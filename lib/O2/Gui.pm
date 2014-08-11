package O2::Gui;

use strict;

use constant DEBUG => 0;
use O2 qw($context $cgi $config $session);
use O2::Util::List qw(upush);

#------------------------------------------------------------------
sub new {
  my ($pkg, %init) = @_;
  return bless \%init, $pkg;
}
#------------------------------------------------------------------
sub needsAuthentication { # Default, do not require authentication
  my ($obj, $method) = @_;
  return 0;
} 
#------------------------------------------------------------------
sub authenticate { # Default - check for a user ID
  my ($obj, $method) = @_;
  return $context->getUserId() ? 1 : 0;
} 
#------------------------------------------------------------------
sub handleAuthenticationFailure { # Default, redirect to login
  my ($obj, $method) = @_;
  return $obj->error('notLoggedIn') if $obj->getParam('isAjaxRequest');
  $cgi->redirect( $obj->getLoginUrl() );
} 
#------------------------------------------------------------------
sub getLoginUrl {
  my ($obj) = @_;
  my $redirectUrl = $config->get('dispatcher.needAuthRedirectUrl');
  my $wantedUrl   = $cgi->getCurrentUrl();
  $redirectUrl   .= $redirectUrl =~ m/\?/ ? '&' : '?';
  $redirectUrl   .= 'loginSuccessUrl=' . $cgi->urlEncode($wantedUrl);
  return $redirectUrl;
} 
#------------------------------------------------------------------
# abort execution with an error message
sub error {
  my ($obj, $message) = @_;
  if ($obj->getParam('isAjaxRequest')) {
    $obj->ajaxError($message);
    return;
  }
  $cgi->error($message);
}
#------------------------------------------------------------------
sub getContext {
  return $context;
}
#------------------------------------------------------------------
sub getLang {
  my ($obj) = @_;
  return $context->getLang();
}
#------------------------------------------------------------------
sub getCgi {
  return $cgi;
}
#------------------------------------------------------------------
sub getParam {
  my ($obj, $key) = @_;
  return $cgi->getParam($key);
}
#------------------------------------------------------------------
sub getDecimalParam {
  my ($obj, $key) = @_;
  return $cgi->getDecimalParam($key);
}
#------------------------------------------------------------------
sub getParams {
  my ($obj) = @_;
  return $cgi->getParams();
}
#------------------------------------------------------------------
sub getSession {
  return $session;
}
#------------------------------------------------------------------
sub getConfig {
  return $config;
}
#------------------------------------------------------------------
sub getObjectById {
  my ($obj, $objectId) = @_;
  die "No objectId supplied for method 'getObjectById'" unless $objectId;
  return $context->getObjectById($objectId);
}
#------------------------------------------------------------------
sub getUser {
  my ($obj) = @_;
  return $context->getUser() or die 'No user found in context';
}
#------------------------------------------------------------------
sub getObjectByParam {
  my ($obj, $paramName, $needsToBeOfClass) = @_;
  
  my $objectId = $obj->getParam($paramName);
  die "Not a valid objectId for '$paramName': $objectId" if $objectId !~ m{^\d+$};
  
  my $object = $obj->getObjectById($objectId);
  die "Could not find object with id '$objectId'"                                   if !$object          || !$object->isa('O2::Obj::Object');
  die "Object $object (ID: $objectId) is not of required class '$needsToBeOfClass'" if $needsToBeOfClass && !$object->isa($needsToBeOfClass);
  
  return $object;
}
#------------------------------------------------------------------
sub getCwd {
  my ($obj) = @_;
  return $obj->{cwd};
}
#------------------------------------------------------------------
sub setCwd {
  my ($obj, $cwd) = @_;
  $obj->{cwd} = $cwd;
}
#------------------------------------------------------------------
sub verifyRules {
  my ($obj) = @_;

  my ($ruleTitle, $errorMessages) = $cgi->verifyRules();

  if (@{$errorMessages}) {
    if ($obj->getParam('isAjaxRequest')) {
      my $errMsg = "<b>$ruleTitle</b><br>\n";
      foreach my $msg (@{$errorMessages}) {
        $errMsg .= "- $msg<br>\n";
      }
      $obj->ajaxError($errMsg);
    }
    else {
      print "<h1>$ruleTitle</h1>\n<ul>";
      foreach my $msg (@{$errorMessages}) {
        print "<li>$msg</li>\n";
      }
      print "</ul>";
      $cgi->output();
      $cgi->exit();
    }
  }
}
#------------------------------------------------------------------
sub ajaxDisplayString {
  my ($obj, $string) = @_;
  $obj->_ajaxDisplay(_html => $string);
}
#------------------------------------------------------------------
sub setDisplayContentTypeFromFile {
  my ($obj, $fileName) = @_;
  my $encoding = 'utf-8';
  if ($fileName =~ m{ [.]xml \z }xms) {
    $cgi->setContentType('text/xml');
    my $path = -f $fileName ? $fileName : $obj->resolveTemplatePath($fileName);
    my $fileContent = $context->getSingleton('O2::File')->getFile($path);
    my ($fileEncoding) = $fileContent =~ m{ <[?]xml [^\r\n]*? encoding= ["'] ([\w-]+) ["'] [^\r\n]*? [?]> }xmsi;
    $encoding = $fileEncoding if $fileEncoding;
  }
  elsif ($fileName =~ m{ [.]html \z }xms) {
    $cgi->setContentType('text/html');
  }
  $cgi->setCharacterSet($encoding) unless $cgi->characterSetIsSet();
}
#------------------------------------------------------------------
# locate template in $file, parse and display it
sub display {
  my ($obj, $file, @params) = @_;
  debug $file;
  
  my %params = $obj->_validateEvenNumberOfElementsInHash(@params);
  $obj->setDisplayContentTypeFromFile( $file ) unless $params{contentType}; # tarjeiv : So we can override
  $cgi->setContentType( $params{contentType} )     if $params{contentType};
  
  my $path = -f $file ? $file : $obj->resolveTemplatePath($file);
  debug "Resolved path: $path";
  die "display() can not resolve '$file'. TemplateRootPaths:<br>\n" . join "<br>\n", $obj->getTemplateRootPaths() unless -f $path;
  
  if (!$obj->getCwd()) {
    my $cwd = $path;
    $cwd    =~ s{ ([/\\]) [^/\\]+ \z }{$1}xms;
    $obj->setCwd($cwd);
  }
  
  if (($obj->getParam('isAjaxRequest') || $obj->getParam('isMultipartAjax')) && !$params{__doNotPrint}) {
    debug "isAjaxRequest";
    if (!%params  &&  $file !~ m{ [.] (?: html | xml) \z }xms) {
      my $result = $file;
      $obj->_ajaxDisplay(result => $result);
    }
    else {
      if ($obj->getParam('isMultipartAjax')) {
        my @ajaxKeys = qw(isAjaxRequest _target _where onError onSuccess ignoreMissingTarget debug ajaxId errorHandler);
        foreach my $ajaxKey (@ajaxKeys) {
          my $value = $obj->getParam($ajaxKey);
          $params{$ajaxKey} = $value if defined $value;
        }
      }
      $obj->_ajaxDisplay(
        file        => $path,
        contentType => $cgi->getContentType(),
        %params,
      );
    }
    return 'AJAX_DISPLAYED';
  }
  
  my ($content) = $obj->displayString(
    $context->getSingleton('O2::File')->getFileRef($path),
    __templatePath => $path,
    contentType    => $cgi->getContentType(),
    %params,
  );
  return $content;
}
#------------------------------------------------------------------
sub _validateEvenNumberOfElementsInHash {
  my ($obj, @hash) = @_;
  die 'Odd number of elements in hash assignment' if scalar (@hash) % 2;
  return @hash;
}
#------------------------------------------------------------------
sub displayExcel {
  my ($obj, $file, %params) = @_;
  my $fileNameWithoutExtension = $file;
  $fileNameWithoutExtension    =~ s{ [.] [^.]+ \Z }{}xms;
  my $fileName = $params{fileName} || "$fileNameWithoutExtension.xls";

  $cgi->addHeader('Content-Disposition', "attachment;filename=$fileName");

  $obj->display(
    $file,
    %params,
    contentType => 'application/vnd.ms-excel;charset=' . $cgi->getCharacterSet(),
  );
}
#------------------------------------------------------------------
sub exportTableAsCsv {
  my ($obj, $file, %params) = @_;
  my $delimiter       = $params{csvDelimiter} || ',';
  my $delimiterLength = length $delimiter;
  
  $cgi->setCharacterSet( delete $params{encoding} ) if $params{encoding};
  
  my $fileName = delete $params{fileName};
  if (!$fileName) {
    my $fileNameWithoutExtension = $file;
    $fileNameWithoutExtension    =~ s{ [.] [^.]+ \Z }{}xms;
    $fileName = "$fileNameWithoutExtension.csv";
  }
  
  my ($html) = $obj->display(
    $file, %params,
    __doNotPrint => 1,
  );
  
  my $csv = '';
  my ($table) = $html  =~ m{ <table [^>]*? > (.*?) </table> }xms; # Use the first table
  my ($thead) = $table =~ m{ <thead [^>]*? > (.*?) </thead> }xms; # See if there's a thead tag
  $thead = $thead || $table;
  foreach my $header ($thead =~ m{ <th [^>]*? > \s* (.+?) \s*  </th> }xmsg) {
    $csv .= $obj->_quoteForCsv($header) . $delimiter;
  }
  $csv = substr ($csv, 0, -$delimiterLength) . "\n";
  
  my @tableRows = $table =~ m{ <tr [^>]*? > \s* (.+?) \s* </tr> }xmsg;
  foreach my $tableRow (@tableRows) {
    foreach my $td ($tableRow =~ m{ (<td [^>]*? > .*? </td>) }xmsg) {
      my ($attributes, $cellContent) = $td =~ m{ \A <td ([^>]*?) > \s* (.*?) \s* </td> \z }xmsg;
      my ($quote, $class) = $attributes =~ m{ class=(['"]) (\w+?) \1 }xms;
      $cellContent = $obj->_quoteForCsv($cellContent) if $class ne 'number' && $class ne 'unquoted';
      $csv .= "$cellContent$delimiter";
    }
    $csv = substr ($csv, 0, -$delimiterLength) . "\n";
  }
  
  $cgi->addHeader(      'Content-Disposition', "attachment;filename=$fileName" );
  $cgi->setContentType( 'text/csv;charset=' . $cgi->getCharacterSet()          );
  print $csv;
}
#------------------------------------------------------------------
sub _quoteForCsv {
  my ($obj, $string) = @_;
  $string = $context->getSingleton('O2::Util::String')->stripTags($string);
  $string =~ s{"}{\"\"}xmsg; # Escape double quotes by wrapping them in double quotes
  return qq{"$string"};      # Wrap the entire string in double quotes
}
#------------------------------------------------------------------
# parse template in $string and display or return it
sub displayString {
  my ($obj, $string, %params) = @_;
  
  %params = ($obj->getDisplayParams(), %params);
  $obj->setDisplayContentTypeFromFile( '.html' ) unless $params{contentType}; # Just a little hack to set the correct content type..
  $cgi->setContentType(   $params{contentType} )     if $params{contentType};
  
  ${$string} = "<o2 use Html />" . ${$string} if $cgi->getContentType() =~ m{ \A text/html }xms;
  
  my $content;
  my $cacher = $context->getSingleton('O2::Util::SimpleCache');
  my $cacheKey = $params{__cacheKey};
  if ($cacheKey) {
    if (!$params{__cacheOnlyStore}) { # Only store in cache, no fetching
      $content = $cacher->get($cacheKey);
      if ($content) {
        debug "Getting content from cache, cacheKey=$cacheKey";
        debug "Content: $content", 3;
      }
    }
  }
  
  my $template;
  if (!$content) {
    debug 'Generating content (not using cache)';
    require O2::Template;
    $template = O2::Template->newFromString($string);
    $template->setCwd(             $obj->getCwd()          );
    $template->setLocale(          $context->getLocale()   );
    $template->setCurrentTemplate( $params{__templatePath} ) if $params{__templatePath};

    $content = ${ $template->parse(%params) };
    $cacher->set($cacheKey, $content, ttl => 24*3600) if $cacheKey;
  }
  
  return ($content, $template) if $params{__doNotPrint};
  
  print $content;
}
#------------------------------------------------------------------
# set general parameters for the display methods
sub getDisplayParams {
  my ($obj, %params) = @_;
  return $context->getDisplayParams(%params);
}
#------------------------------------------------------------------
sub _ajaxDisplay {
  my ($obj, %params) = @_;
  my $template;
  if (my $path = $params{file}) {
    $path = -f $path ? $path : $obj->resolveTemplatePath($path);
    debug "Resolved path: $path";
    my $fileContents = $context->getSingleton('O2::File')->getFile($path);
    $fileContents .= '<o2 incJavascript /><o2 postJavascript /><o2 incLinkTags /><o2 incStylesheet />'; # Make sure all included javascript and css is included..
    ($params{_html}, $template) = $obj->displayString(
      \$fileContents,
      %params,
      __doNotPrint   => 1,
      __templatePath => $path,
    );
  }
  $params{_html} .= qq{<div id="_o2AjaxElement" style="display: none;"></div>};
  
  my $tagParser  = $template ? $template->getTagParser() : $context->getSingleton('O2::Template::TagParser');
  my $htmlTaglib = $tagParser->getTaglibByName('Html');
  $params{javascriptsToExecuteOnLoad} = $htmlTaglib->_getPrioritizedJavascript('onLoad');
  
  my (@js, @jsFiles, @cssFiles);
  $params{_html} =~ s{<script[^>]+src=[\"\'](.+)[\"\'][^>]*>.*?</script>}{ push @jsFiles,  $1; ''; }ieg;
  $params{_html} =~ s{<link[^>]+ href=[\"\'](.+\.css\b.*?)[\"\'][^>]*>}{   push @cssFiles, $1; ''; }ieg;
  $params{_html} =~ s{<script[^>]*>(.*?)</script>}{                        push @js,       $1; ''; }msieg;
  $params{javascriptsToExecute} = \@js;
  $params{javascriptFiles}      = \@jsFiles;
  $params{cssFiles}             = \@cssFiles;
  
  my %q = $obj->getParams();
  foreach my $key (keys %q) {
    $params{$key} = $q{$key};
  }
  
  require O2::Javascript::Data;
  my $jsData = O2::Javascript::Data->new();
  my $js = $jsData->dump(\%params);
  if (!$obj->getParam('xmlHttpRequestSupported')) {
    print "<script type='text/javascript'>parent.o2.ajax.handleServerResponseIframe($js);</script>";
    return;
  }
  
  print "result = $js";
}
#------------------------------------------------------------------
sub ajaxSuccess {
  my ($obj, %extraParams) = @_;
  
  $cgi->doNotEncodeOutputBuffer('true') if delete $extraParams{doNotEncodeOutput};
  
  my %params = $obj->getParams();
  %params = (%params, %extraParams); # Merging
  $params{result} = 'ok';
  require O2::Javascript::Data;
  my $jsData = O2::Javascript::Data->new();
  my $js = $jsData->dump(\%params);
  $js    =~ s{\r}{ }xmsg;
  if (!$obj->getParam('xmlHttpRequestSupported')) {
    print "<script type='text/javascript'>parent.o2.ajax.handleServerResponseIframe($js);</script>";
  }
  else {
    print "result = $js";
  }

  $cgi->setContentType('text/html'); # We need to enforce this, text/javascript doesn't work well with IE7
  $cgi->output();
  $cgi->exit();
}
#------------------------------------------------------------------
sub ajaxError {
  my ($obj, $errorMsg, $errorHeader) = @_;
  $errorHeader ||= $obj->getLang()->keyExists('o2.ajax.errorHeader') ? $obj->getLang()->getString('o2.ajax.errorHeader') : '';
  $cgi->ajaxError($errorMsg, $errorHeader);
}
#------------------------------------------------------------------
sub getString {
  my ($obj, @params) = @_;
  return $obj->getLang()->getString(@params);
}
#------------------------------------------------------------------
# convert a relative path to full path by testing if file exists when we prepend each templateRootPath
sub resolveTemplatePath {
  my ($obj, $file, $guiClass) = @_;
  die "Missing file parameter" unless $file;
  
  foreach my $root ($obj->getTemplateRootPaths($guiClass)) {
    my $path = $root . ($file =~ m|^/| ? '' : '/') . $file;
    return $path if -f $path;
  }
  return $context->getSingleton('O2::File')->resolvePath($file);
}
#------------------------------------------------------------------
# used by display() to locate template files. (no trailing / in paths)
sub getTemplateRootPaths {
  my ($obj, $guiClass) = @_;
  $guiClass ||= ref $obj; # Figure out default template locations for this gui class
  
  if (my ($pluginName) = $guiClass =~ m{ \A O2Plugin:: (\w+) }xms) {
    my $plugin = $context->getPlugin($pluginName);
    my $root   = "$plugin->{root}/var/templates";
    $guiClass  =~ s{ ::              }{/}xmsg;
    $guiClass  =~ s{ \A [\w/]+ /Gui/ }{}xms;
    return ("$root/$guiClass");
  }
  
  my @superClasses = $context->getSingleton('O2::Mgr::ClassManager')->getSuperClassNamesByClassName($guiClass);
  my @guiClasses   = ($guiClass, @superClasses);
  
  my @possibleRootPaths;
  foreach my $class (@guiClasses) {
    my $class2 = $class;
    $class     =~ s{ \A ( [\w:]+ ::Gui:: ) }{}xms or next; # Removing 'O2CMS::Backend::Gui' / 'O2::Gui' etc...
    $class     =~ s{::}{/}xmsg;
    $class2    =~ s{::}{/}xmsg;
    
    my @rootPaths = $context->getRootPaths(ignorePlugins => 1);
    foreach my $dir (@rootPaths) {
      push @possibleRootPaths, "$dir/var/templates/$class";
    }
    foreach my $dir (@rootPaths) {
      push @possibleRootPaths, "$dir/var/templates/$class2";
    }
  }
  
  my $cwd = $obj->getCwd();
  return (
    @possibleRootPaths,
    $context->getRootPaths(),
    '',
    $cwd ? $cwd : (),
  );
}
#------------------------------------------------------------------
sub displayPage {
  my ($obj, $file, %params) = @_;
  %params = ( $obj->getDisplayParams(), %params );

  # Set correct content type:
  if ($params{contentType}) {
    $cgi->setContentType( $params{contentType} );
  }
  else {
    $obj->setDisplayContentTypeFromFile($file);
  }

  if (!$params{q}) {
    my %q = $obj->getParams();
    $params{q} = \%q;
  }
  
  my $path = -f $file ? $file : $obj->resolveTemplatePath($file);
  
  if ($params{pageTemplatePath} && $context->cmsIsEnabled()) {
    my $objectPath   = $params{pageTemplatePath} || '/Templates/pages/applicationPage.html';
    my $pageTemplate = $context->getSingleton('O2::Mgr::MetaTreeManager')->getObjectByPath($objectPath) or die "ObjectPath ($objectPath) does not exist";
    
    # create a page object on the fly
    my $page = $context->getSingleton('O2CMS::Mgr::PageManager')->newObject();
    $page->setTemplateId( $pageTemplate->getId() );
    
    require O2CMS::Publisher::PageRenderer;
    my $pageRenderer = O2CMS::Publisher::PageRenderer->new(
      page  => $page,
      media => 'Html',
    );
    $pageRenderer->setTemplateVariable('templatePath', $path);
    foreach my $varname (keys %params) {
      $pageRenderer->setTemplateVariable( $varname, $params{$varname} );
    }
    my $html = ${ $pageRenderer->renderPage() };
    print $html;
  }
  else {
    my $pageTemplate = $params{pageTemplate};
    my $pageTemplatePath = -f $pageTemplate ? $pageTemplate : $obj->resolveTemplatePath($pageTemplate);
    my $template = $context->getSingleton('O2::Template', constructorName => 'newFromFile', $pageTemplatePath);
    $template->getTagParser()->setVar('templatePath', $path);
    print $template->parse();
  }
}
#------------------------------------------------------------------
sub displayBlankPage {
  my ($obj, $file, %params) = @_;
  $obj->displayPage(
    $file,
    %params,
    pageTemplatePath => '/Templates/pages/blank.html',
  );
}
#------------------------------------------------------------------
sub displayErrorPage {
  my ($obj, %params) = @_;
  $obj->displayPage(
    'o2://var/templates/error.html',
    %params,
  );
}
#------------------------------------------------------------------
1;
