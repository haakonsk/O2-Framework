package O2::HttpSession::Files;

# Implements session storage in files

use strict;

use base 'O2::Session::Files';
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
  my $publicSessionPath = $obj->getPublicSessionPath();
  return $context->getSingleton('O2::Data')->load($publicSessionPath) if -e $publicSessionPath;
  return {};
}
#--------------------------------------------------------------------------------------------------
sub getPublicSessionRoot {
  return $config->get('session.publicSessionRoot');
}
#--------------------------------------------------------------------------------------------------
sub getPublicSessionPath {
  my ($obj) = @_;
  return $obj->_getSessionPath( $obj->getPublicSessionRoot() );
}
#--------------------------------------------------------------------------------------------------
sub loadSession {
  my ($obj) = @_;
  $obj->SUPER::loadSession();
  my $publicSessionPath = $obj->getPublicSessionPath();
  $obj->{publicSession} = $context->getSingleton('O2::Data')->load($publicSessionPath) if -e $publicSessionPath;
}
#--------------------------------------------------------------------------------------------------
sub deleteSession {
  my ($obj) = @_;
  $obj->SUPER::deleteSession();
  
  $obj->_deleteCookies();
  
  # Delete public-session file
  unlink $obj->getPublicSessionPath();
}
#--------------------------------------------------------------------------------------------------
sub save {
  my ($obj) = @_;
  
  $obj->SUPER::save();
  return unless $obj->{publicSession};
  
  eval {
    $context->getSingleton('O2::Data')->save( $obj->getPublicSessionPath(),  $obj->{publicSession} );
  };
  my $errorMsg = $@;
  die 'Error saving public session file (' . $obj->getPublicSessionPath() . "): $errorMsg" if $errorMsg;
  
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
  $obj->SUPER::_regenerateId();
  return O2::Role::Misc::HttpSession::regenerateId($obj);
}
#--------------------------------------------------------------------------------------------
sub getExistingSessionId {
  my ($obj) = @_;
  return O2::Role::Misc::HttpSession::getExistingSessionId($obj);
}
#--------------------------------------------------------------------------------------------
1;
