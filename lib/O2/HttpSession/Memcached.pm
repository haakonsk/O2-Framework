package O2::HttpSession::Memcached;

# Implements session storage in memcached

use strict;

use base 'O2::Session::Memcached';
use base 'O2::Role::Misc::HttpSession';

use O2 qw($context $cgi $config);

#--------------------------------------------------------------------------------------------------
sub createObject {
  my ($package, %params) = @_;
  return $package->SUPER::createObject(%params);
}
#--------------------------------------------------------------------------------------------------
sub _getPublicSessionData {
  my ($obj) = @_;
  return $context->getMemcached()->get( $obj->_getPublicSessionCacheId() );
}
#--------------------------------------------------------------------------------------------------
sub loadSession {
  my ($obj) = @_;
  $obj->SUPER::loadSession();
  $obj->{publicSession} = $obj->_getPublicSessionData();
}
#--------------------------------------------------------------------------------------------------
sub deleteSession {
  my ($obj) = @_;
  $obj->SUPER::deleteSession();
  
  $obj->_deleteCookies();
  $context->getMemcached()->delete( $obj->_getPublicSessionCacheId() );
}
#--------------------------------------------------------------------------------------------------
sub _getPublicSessionCacheId {
  my ($obj) = @_;
  return 'O2_HTTPSESSION_MEMCACHED:' . $obj->getId();
}
#--------------------------------------------------------------------------------------------
sub save {
  my ($obj) = @_;
  $obj->SUPER::save();
  return unless $obj->{publicSession};
  
  eval {
    $context->getMemcached()->set( $obj->_getPublicSessionCacheId(), $obj->{publicSession} );
  };
  my $errorMsg = $@;
  die "Error saving public session to memcached: $errorMsg" if $errorMsg;
  
  $obj->setPublicSessionCookie();
}
#--------------------------------------------------------------------------------------------------
sub init {
  my ($obj, %params) = @_;
  $obj->SUPER::init(%params);
  return O2::Role::Misc::HttpSession::_init($obj, %params);
}
#--------------------------------------------------------------------------------------------
sub _regenerateId {
  my ($obj) = @_;
  return O2::Role::Misc::HttpSession::regenerateId($obj);
}
#--------------------------------------------------------------------------------------------
sub getExistingSessionId {
  my ($obj) = @_;
  return O2::Role::Misc::HttpSession::getExistingSessionId($obj);
}
#--------------------------------------------------------------------------------------------
1;
