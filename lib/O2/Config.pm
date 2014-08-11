package O2::Config;

# Class for accessing config files.
# Config files are perl data structures.
# The configKey 'lang.strings.okButton' would be resolved in the following order:
# 1. {string}->{okButton} in $confDir/lang.conf
# 2. {okButton} in $confDir/lang/string.conf
# 3. The whole datastructure in $confDir/lang/string/okButton.conf

use strict;

use O2 qw($context);
use O2::Util::List qw(upush);

#-----------------------------------------------------------------------------
sub new {
  my ($pkg, @confDirs) = @_;
  
  my $obj = bless {
    confDirs     => \@confDirs,
    cacheHandler => undef, # default no cache handler
    files        => {},    # filename to config plds mapping
  }, $pkg;
  $obj->loadConfDirs();
  
  return $obj;
}
#-----------------------------------------------------------------------------
sub loadConfDirs {
  my ($obj) = @_;
  $context->deleteRootPathCache();
  $obj->{confDirs} = [] unless exists $obj->{confDirs};
  
  foreach my $root ($context->getRootPaths()) {
    my $dir = "$root/etc/conf";
    upush @{ $obj->{confDirs} || [] }, $dir if -d $dir;
  }
  die "No config directories found!" unless @{ $obj->{confDirs} };
}
#-----------------------------------------------------------------------------
# description: returns a config value
# params: $confKey - dotted-style path to a config element.
sub getConfigValue {
  my ($obj, $confKey) = @_;
  return $obj->{cache}->{$confKey} if exists $obj->{cache}->{$confKey};
  die "Error in config path: '$confKey'" if $confKey !~ m{ \A [\w\s.:+]+ \z }xms;
  
  $obj->_debug("<li>GET configKey: <b>$confKey</b>");
  my @parts = split /\./, $confKey;
  my @confDirs = @{ $obj->{confDirs} };
  
  # If the config value is a.b.c and c is a file (c.conf), then we should merge all c.conf's so the entire file doesn't have to be duplicated if you just want to override a single value
  my $mergedConfigFile;
  
  while (@confDirs) {
    my $dirPath = shift @confDirs;
    my @remainingParts = @parts;
    my $confPath = '';
    while ( my $part = shift @remainingParts ) { # Going through parts of config key, starting on the left.
      $confPath = "$dirPath/$part.conf"; # .../conf/<previousParts>/$part.conf
      $confPath = $obj->{actualPath}->{$confPath} if $obj->{actualPath}->{$confPath};
      if ( !exists $obj->{files}->{$dirPath} ) {
        $obj->{files}->{$dirPath} = -d $dirPath;
        $obj->_debug( "Fileoperation: Stat $dirPath - " . ($obj->{files}->{$dirPath} ? 'found' : 'missing') );
      }
      if (!$obj->{files}->{$dirPath}) {
        return $obj->{files}->{$dirPath} = $mergedConfigFile unless @confDirs;
        next;
      }
      
      if (!-f $confPath && !exists $obj->{files}->{$confPath}) {
        my $originalConfPath = $confPath;
        my ($confName) = $confPath =~ m{ (\w+) [.]conf \z }xms;
        my $dir = $confPath;
        $dir    =~ s{ [.]conf \z }{-configs}xms;
        if (-d $dir) {
          $confPath = sprintf "$dir/$confName.%s.conf", $obj->getServerId();
          $obj->{actualPath}->{$originalConfPath} = $confPath;
        }
        else {
          $obj->{files}->{$confPath} = undef;
        }
      }
      if (-f $confPath) {
        $obj->_debug("Fileoperation: read $confPath");
        $obj->{_lastFile} = $confPath;
        my $evaledFileContent = $obj->{files}->{$confPath};
        if (!$evaledFileContent) {
          my $fileMgr = $context->getSingleton('O2::File');
          $evaledFileContent = eval $fileMgr->getFile($confPath); ## no critic(BuiltinFunctions::ProhibitStringyEval)
          die "Error in '$confPath': $@" if $@;
          $obj->{files}->{$confPath} = $evaledFileContent;
        }
        my $value = $obj->_nextPart($evaledFileContent, @remainingParts);
        if (ref ($value) eq 'HASH') {
          %{$mergedConfigFile}
            = $mergedConfigFile  ?  ( %{$value}, %{$mergedConfigFile} )  :  %{$value}; # The values we find first (from $mergedConfigFile} are most significant and should not be overridden
        }
        elsif (defined $value) {
          return $obj->{cache}->{$confKey} = $value;
        }
      }
      $dirPath .= "/$part";
    }
    if (!@confDirs) { # This is the last directory we're checking
      return $mergedConfigFile if $mergedConfigFile || -f $confPath;
      
      $obj->_debug("Fileoperation: $confPath not found");
      return $obj->{cache}->{$confKey} = undef;
    }
  }
  return $obj->{cache}->{$confKey} = undef;
}
#-----------------------------------------------------------------------------
# returns a config value casted to an array
sub getArray {
  my ($obj, $confKey) = @_;
  
  if ($obj->{cacheHandler}) {
    my $config = $obj->{cacheHandler}->get("O2_CONFIG:$confKey");
    return @{$config} if $config;
  }
  
  my $configValue = $obj->getConfigValue($confKey);
  $configValue    = [] unless defined $configValue;
  $obj->{cacheHandler}->set("O2_CONFIG:$confKey", $configValue) if $obj->{cacheHandler};
  return @{$configValue};
}
#-----------------------------------------------------------------------------
# returns a config value casted to an array
sub getHash {
  my ($obj, $confKey) = @_;
  
  if ($obj->{cacheHandler}) {
    my $config = $obj->{cacheHandler}->get("O2_CONFIG:$confKey");
    return %{$config} if $config;
  }
  
  my $conf = $obj->getConfigValue($confKey);
  return () unless ref $conf eq 'HASH';
  
  my %config;
  foreach my $ck (keys %{$conf}) {
    if ( ref $conf->{$ck} ne 'HASH') {
      $config{$ck} = $obj->get("$confKey.$ck");
    }
    else {
      %{ $config{$ck} } = $obj->getHash("$confKey.$ck");
    }
  }
  $obj->{cacheHandler}->set("O2_CONFIG:$confKey", \%config) if $obj->{cacheHandler};
  return %config;
}
#-----------------------------------------------------------------------------
# returns an config value, where all %%<reference-to-another-config-key-here>%% constructs are interpolated.
sub get {
  my ($obj, $confKey) = @_;
  
  # Get from cache handler
  my $string;
  if ($obj->{cacheHandler}) {
    $string = $obj->{cacheHandler}->get("O2_CONFIG:$confKey");
    return $string if $string;
  }
  
  $string = $obj->getConfigValue($confKey);
  return unless defined $string;
  
  $string =~ s|%%(.*?)%%|$obj->get($1)|ge if index ($string, '%%') >= 0;
  $obj->{cacheHandler}->set("O2_CONFIG:$confKey", $string) if $obj->{cacheHandler};
  return $string;
}
#-----------------------------------------------------------------------------
# description: recursively resolve a configKey
sub _nextPart {
  my ($obj, $item, @remainingParts) = @_;
  return $item unless @remainingParts;  # last config part evaluated
  return       unless defined $item;    # woops! confKey pointed to an undef or missing item, and there's more parts to evaluate
  my $nextPart = shift @remainingParts; # move to next part of confKey
  
  $obj->_debug("_nextPart: find $nextPart of $item");
  return $obj->_nextPart( $item->{$nextPart}, @remainingParts ) if ref $item eq 'HASH';
  
  if (ref $item eq 'ARRAY') {
    die "Trying to use '$nextPart' as array-index" unless $nextPart =~ m|^\d+$|;
    return $obj->_nextPart( $item->[$nextPart], @remainingParts );
  }
  die "Don't know how to retrieve part '$nextPart' from a '$item' item...";
}
#-----------------------------------------------------------------------------
sub _debug {
  my ($obj, $msg) = @_;
  return;
  print "Content-type: text/html\n\n" unless $obj->{_headerDebugDone}; ## no critic(ControlStructures::ProhibitUnreachableCode)
  $obj->{_headerDebugDone} = 1;                                        ## no critic(ControlStructures::ProhibitUnreachableCode)
  print "\t$msg<br>\n";                                                ## no critic(ControlStructures::ProhibitUnreachableCode)
}
#-----------------------------------------------------------------------------
sub setCacheHandler {
  my ($obj, $cacheHandler) = @_;
  $obj->{cacheHandler} = $cacheHandler;
}
#-----------------------------------------------------------------------------
sub shiftConfigDirectory {
  my ($obj, $configDirectory) = @_;
  my $foundDir = 0;
  foreach my $dir (@{ $obj->{confDirs} }) {
    $foundDir = 1 if $dir eq $configDirectory;
  }
  shift @{ $obj->{confDirs} }, $configDirectory unless $foundDir;
}
#-----------------------------------------------------------------------------
sub getServerId {
  my ($obj) = @_;
  my $customerPath = $context->getCustomerPath() or die "Couldn't find customerPath";
  my $symlinkPath = "$customerPath/etc/conf/serverId";
  die "Symlink to serverType ($symlinkPath) doesn't exist" unless -l $symlinkPath;
  
  return readlink $symlinkPath;
}
#-----------------------------------------------------------------------------
sub clearCache {
  my ($obj) = @_;
  $obj->{cache} = undef;
  $obj->{files} = undef;
  $obj->loadConfDirs();
}
#-----------------------------------------------------------------------------
1;
