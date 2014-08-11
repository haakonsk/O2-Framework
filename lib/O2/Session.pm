package O2::Session;

# Implements session storage in files

use strict;

use constant DEBUG => 0;
use O2 qw($context $config);

#--------------------------------------------------------------------------------------------------
sub new {
  my ($obj) = @_;
  if ($config->get('session.dataStore') eq 'memcached' && $context->getMemcached()->isa('O2::Cache::MemcachedFast')) {
    debug 'Using memcached for sessions';
    require O2::Session::Memcached;
    return O2::Session::Memcached->createObject();
  }
  
  debug 'Using files for sessions';
  require O2::Session::Files;
  return O2::Session::Files->createObject();
}
#--------------------------------------------------------------------------------------------------
sub createObject {
  my ($package, %params) = @_;
  return $package->SUPER::new(%params);
}
#--------------------------------------------------------------------------------------------------
1;
