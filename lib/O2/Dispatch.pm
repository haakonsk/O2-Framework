package O2::Dispatch;

use strict;

our $context;
our $cgi;

use constant DEBUG => 0;
use O2::Context;
require O2;

#------------------------------------------------------------------------------------------------------------
sub new {
  my ($pkg, %params) = @_;
  return bless \%params, $pkg;
}
#------------------------------------------------------------------------------------------------------------
sub dispatch {
  my ($obj, %params) = @_;
  $cgi     = $O2::cgi     = $params{cgi} or die sprintf 'cgi parameter missing in dispatch, called from %s, line %d', [caller]->[1], [caller]->[2];
  $context = $O2::context = $params{context} || O2::Context->new( cgi => $cgi );
  
  $cgi->setCharacterSet('utf-8');
  
  # Possible to force locale via "forceLocale" url parameter
  $context->setLocaleCode( $cgi->getParam('forceLocale') ) if $cgi->getParam('forceLocale');
  
  my $session = $obj->getSession();
  $context->setSession($session);
  $obj->_debug("Session object: $session", 2);
  
  # This enables us to turn on/off logging of cache debug for the current session through the url:
  $session->set(    'debugLevel', $cgi->getParam('enableDebugLevel') ) if $cgi->getParam('enableDebugLevel');
  $session->delete( 'debugLevel' ) if $cgi->getParam('disableDebug');
  $main::debugLevel = $session->get('debugLevel') || 0;
  
  if ($ENV{SCRIPT_NAME} =~ m{ index[.]cgi \z }xms  &&  $ENV{SCRIPT_URI} !~ m{ index[.]cgi \z }xms) {
    # Directory accessed, index.cgi is executing, but was not requested explicitely.
    # Fetch from cache if cached:
    my $dir = $ENV{SCRIPT_FILENAME};
    $dir    =~ s{ /index[.]cgi \z }{}xms;
    my $locale = $context->getLocaleCode();
    if (-f "$dir/index.html.$locale") {
      print $context->getSingleton('O2::File')->getFile("$dir/index.html.$locale");
      $cgi->output();
      return;
    }
  }
  # Translate path-info to class and method name
  my $pathInfo = $context->getEnv('PATH_INFO');
  my $url      = $pathInfo;
  my ($class, $method) = $cgi->getPathInfo();
  $method ||= '';
  die "You are not allowed to run this method" if $method =~ m{ \A _ }xms;  
  
  $context->setEnv('PATH_INFO', "/o2/$class/$method");
  
  ($class, $method) = $obj->cleanClassAndMethod($class, $method);
  ($class, $method) = $obj->getDefaultClassAndMethod() unless $class;
  $method ||= 'init';
  
  my %nonGuiDispatchers = $obj->getNonGuiDispatchers();
  if ($nonGuiDispatchers{$class}) {
    eval "require $nonGuiDispatchers{$class};";
    die "Could not load class '$nonGuiDispatchers{$class}': $@" if $@;
    
    $nonGuiDispatchers{$class}->dispatch();
    return;
  }
  
  ($class, $method) = $obj->handlePublisherUrls($url, $class, $method, %params);
  
  # Resolve gui module package
  my ($pluginName, $partialClass) = $class =~ m{ \A O2Plugin::(.+?)::(.+) \z }xms;
  if ($pluginName) {
    my $plugin = $context->getPlugin($pluginName) or die "Not such plugin '$pluginName'";
    die "Plugin '$pluginName' not enabled" unless $context->pluginIsEnabled($pluginName);
  }
  my @fullClasses
    = $pluginName
    ? ("O2Plugin::${pluginName}::Backend::Gui::$partialClass", "O2Plugin::${pluginName}::Gui::$partialClass")
    : map { "$_$class" } $obj->getGuiModulePackagePrefixes()
    ;
  
  my $guiModule;
  foreach my $fullClass (@fullClasses) {
    $guiModule = eval {
      $obj->instantiateClass($fullClass);
    };
    if ($@) {
      my $path = "$fullClass.pm";
      $path    =~ s{ :: }{/}xmsg;
      die "$fullClass: $@" if $@ !~ m{Can't locate \Q$path\E in \@INC}ms;
    }
    $obj->_debug( "Try $fullClass : " . (ref $guiModule ? 'found' : 'missing') );
    last if ref $guiModule;
  }
  die "Could not resolve gui module for url '$url' (class $class)" unless ref $guiModule;
  
  # do we need authentication for this method?
  if ( $guiModule->needsAuthentication($method) && !$guiModule->authenticate($method) ) {
    $guiModule->handleAuthenticationFailure($method);
  }
  
  # Profiling:
  my $profiling;
  {
    no strict;
    my $guiPackage = ref $guiModule;
    eval "\$profiling = ${guiPackage}::PROFILING";
  }
  if ($profiling eq 'on') {
    $context->setProfilingOn();
    $context->getDbh()->enableProfiling();
    require O2::Util::WebProfiler;
    O2::Util::WebProfiler->import();
  }
  
  $obj->_debug("Try $method()", 2);
  my $response = $guiModule->$method();
  $obj->_debug("Dispatcher done", 2);
  if ($cgi->getParam('isAjaxRequest')) {
    $guiModule->ajaxSuccess( ref $response ? %{$response} : () ) if $response && $response ne 'AJAX_DISPLAYED';
    $guiModule->ajaxError()                                  unless $response;
  }
  
  # ajaxSuccess exits, so if it gets called, we don't get down here.
  # Also, if the GUI module calls ajaxSuccess, there's no risk that ajaxSuccess will get called more than once, for the same reason (it exits).
  
  $cgi->output();
  $session->save() if $session->{needsToBeSaved};
}
#------------------------------------------------------------------------------------------------------------
sub getSession {
  return $context->getSingleton('O2::HttpSession');
}
#------------------------------------------------------------------------------------------------------------
sub getNonGuiDispatchers {
  return ( imageResize => 'O2::ImageResize' );
}
#------------------------------------------------------------------------------------------------------------
sub getDefaultClassAndMethod {
  return ('', '');
}
#------------------------------------------------------------------------------------------------------------
sub cleanClassAndMethod {
  my ($obj, $class, $method) = @_;
  $class  =~ s/[^a-zA-Z0-9\-\_]//g;
  $class  =~ s/-/::/g;
  $method =~ s/[^a-zA-Z0-9\-\_]//g if $method;
  return ($class, $method);
}
#------------------------------------------------------------------------------------------------------------
sub instantiateClass {
  my ($obj, $class, @constructorArgs) = @_;
  eval "require $class;";
  die "Could not load class '$class': $@" if $@;
  
  my $object = eval {
    $class->new(@constructorArgs);
  };
  die "new $class didn't return a ref: $@" if $@ || !ref $object;
  return $object;
}
#------------------------------------------------------------------------------------------------------------
sub handlePublisherUrls {
  my ($obj, $url, $class, $method, %params) = @_;
  # route publisher urls to publisher gui module
  if ( $url =~ m/^[^?]+.o2$/ || $params{isPublisherRequest} ) {
    $obj->_debug("Publisher request $url");
    $context->setEnv( 'O2REQUESTPATH', $url         );
    $context->setEnv( 'O2REQUESTURL',  $params{url} );
    $class  = $context->getConfig()->get('publisher.publisherModule');
    $method = $context->getConfig()->get('publisher.publisherMethod');
  }
  return ($class, $method);
}
#------------------------------------------------------------------------------------------------------------
sub getGuiModulePackagePrefixes {
  my @prefixes;
  my $fileMgr = $context->getSingleton('O2::File');
  foreach my $root (reverse $context->getRootPaths()) {
    my $path = "$root/etc/conf/dispatcher.conf";
    next unless -e $path;
    
    my $conf = do $path;
    my @newPrefixes = @{ $conf->{guiModulePackagePrefixes} || [] };
    if (!@prefixes) {
      @prefixes = @newPrefixes;
      next;
    }
    
  NEW_PREFIX:
    foreach my $newPrefix (@newPrefixes) {
      if ($newPrefix =~ m{ ::Backend:: }xms) {
        # Insert backend prefixes before any other backend prefix
        my $i = 0;
        foreach my $originalPrefix (@prefixes) {
          if ($originalPrefix =~ m{ ::Backend:: }xms) {
            splice @prefixes, $i, 0, $newPrefix; # Replace array of length 0 at position $i with new prefix
            next NEW_PREFIX;
          }
          $i++;
        }
        push @prefixes, $newPrefix; # No backend prefixes were found in @prefixes
      }
      else {
        unshift @prefixes, $newPrefix; # Insert frontend prefixes at the beginning
      }
    }
  }
  
  my $isBackend ||= $cgi->getCurrentUrl =~ m{ \A /o2cms }xms;
  @prefixes = grep { $_ =~ m{ ::Backend:: }xms } @prefixes     if $isBackend;
  @prefixes = grep { $_ !~ m{ ::Backend:: }xms } @prefixes unless $isBackend;
  return @prefixes;
}
#------------------------------------------------------------------------------------------------------------
sub _debug {
  my ($obj, $msg, $level) = @_;
  O2::_debug($msg, $level) if DEBUG && (!$level || DEBUG >= $level);
}
#------------------------------------------------------------------------------------------------------------
1;
