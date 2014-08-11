package O2::Cache::Init;

# Cache handler initializer depending on the settings in the cache.conf file

use strict;

use O2 qw($context);

#--------------------------------------------------------------------------------------------
# Returns a dummy object if caching is turned off.
sub initCacheHandler {
  my ($forceCacheHandler) = @_;
  
  my $conf = O2::Cache::Init::_getConfig();
  $conf->{memcached}->{cacheModules} = [$forceCacheHandler] if $forceCacheHandler;
  $conf->{memcached}->{cacheOn}      = 1 if $context->cacheIsEnabled();
  $conf->{memcached}->{cacheObject}  = 1 if $context->objectCacheIsEnabled();
  $conf->{memcached}->{cacheSQL}     = 1 if $context->dbCacheIsEnabled();
  
  my $cacheIsOn = $context->cacheIsEnabled();
  $cacheIsOn    = $conf->{memcached}->{cacheOn} unless defined $cacheIsOn;
  return $context->getSingleton('O2::Cache::Dummy') unless $cacheIsOn;
  
  foreach my $module (@{ $conf->{memcached}->{cacheModules} }) { # Looping through the cache modules, returning the first one we can load and connect
    my $cacheHandler = $context->getSingleton($module, config => $conf);
    return $cacheHandler if ref $cacheHandler && $cacheHandler->isa('O2::Cache::Base');
  }
  
  die "Didn't find a valid cache handler";
}
#--------------------------------------------------------------------------------------------
# I need to load the cache.conf manually.
# Otherwise I will get an infinite loop between O2::Config and O2::Cache trying to use each other
sub _getConfig {
  my $dataMgr = $context->getSingleton('O2::Data');
  my %cache;
  foreach my $rootPath ($context->getRootPaths()) {
    next if !$rootPath || !-e "$rootPath/etc/conf/cache.conf";
    
    %cache = (
      %{ $dataMgr->load("$rootPath/etc/conf/cache.conf") },
      %cache,
    );
  }
  return \%cache if %cache;
  die "Couldn't find cache.conf";
}
#--------------------------------------------------------------------------------------------
1;
