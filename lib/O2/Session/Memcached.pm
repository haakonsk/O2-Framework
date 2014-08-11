package O2::Session::Memcached;

use strict;

use base 'O2::Role::Misc::Session';

use O2 qw($context $config);

#--------------------------------------------------------------------------------------------
sub new {
  die "Please instantiate Session through O2::HttpSession (or O2CMS::Backend::Session)";
}
#--------------------------------------------------------------------------------------------
sub createObject {
  my ($package, %params) = @_;
  
  my $obj = bless {
    sessionName => $params{sessionName} || 'frontend',
  }, $package;
  $obj->init(%params);
  
  return $obj;
}
#--------------------------------------------------------------------------------------------
# Loading session variables from memcached
sub loadSession {
  my ($obj) = @_;
  my $storedSession = $context->getMemcached()->get( $obj->_getCacheId() );
  return unless $storedSession;
  
  $obj->{values}      = $storedSession->{values};
  $obj->{oldSessions} = $storedSession->{oldSessions};
}
#--------------------------------------------------------------------------------------------
# Clears all session variables and deletes the session file
sub deleteSession {
  my ($obj) = @_;
  $obj->clearSession();
  $obj->{needsToBeSaved} = 0;
  $context->getMemcached()->delete( $obj->_getCacheId() );
}
#--------------------------------------------------------------------------------------------
sub _getCacheId {
  my ($obj) = @_;
  return 'O2_SESSION_MEMCACHED:' . $obj->getId();
}
#--------------------------------------------------------------------------------------------
sub save {
  my ($obj) = @_;
  
  my $sessionToDump = {
    values      => $obj->{values},
    oldSessions => $obj->{oldSessions},
  };
  
  eval {
    $context->getMemcached()->set( $obj->_getCacheId(), $sessionToDump );
  };
  if ($@) {
    my $errorMsg = $@;
    $errorMsg    =~ s{ \s+ \z }{}xms;
    $errorMsg    = "Error saving session data to memcached, cache ID is  " . $obj->_getCacheId() . ": $errorMsg ($!)";
    die $errorMsg;
  }
  
  $obj->{needsToBeSaved} = 0;
  return 1;
}
#--------------------------------------------------------------------------------------------
sub init {
  my ($obj) = @_;
  return O2::Role::Misc::Session::_init($obj);
}
#--------------------------------------------------------------------------------------------
sub _regenerateId {
  my ($obj) = @_;
  return O2::Role::Misc::Session::regenerateId($obj);
}
#--------------------------------------------------------------------------------------------
sub getExistingSessionId {
  my ($obj) = @_;
  return O2::Role::Misc::Session::getExistingSessionId($obj);
}
#--------------------------------------------------------------------------------------------
1;
