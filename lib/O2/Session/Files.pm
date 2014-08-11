package O2::Session::Files;

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
# Loading session variables from file
sub loadSession {
  my ($obj) = @_;
  my $path = $obj->getSessionPath();
  my $storedSession;
  $storedSession = eval $context->getSingleton('O2::File')->getFile($path) if -e $path;
  return unless $storedSession;
  
  $obj->{values}      = $storedSession->{values};
  $obj->{oldSessions} = $storedSession->{oldSessions};
}
#--------------------------------------------------------------------------------------------
sub getSessionPath {
  my ($obj) = @_;
  return $obj->_getSessionPath( $obj->getSessionRoot() );
}
#--------------------------------------------------------------------------------------------
# Clears all session variables and deletes the session file
sub deleteSession {
  my ($obj) = @_;
  $obj->clearSession();
  $obj->{needsToBeSaved} = 0;
  unlink $obj->getSessionPath();
}
#--------------------------------------------------------------------------------------------
# Dump $obj->{values} and $obj->{oldValues} to file
sub save {
  my ($obj) = @_;
  
  my $sessionToDump = {
    values      => $obj->{values},
    oldSessions => $obj->{oldSessions},
  };
  require O2::Data;
  my $data = O2::Data->new();
  
  eval {
    $data->save( $obj->getSessionPath(), $sessionToDump );
  };
  if ($@) {
    my $errorMsg = $@;
    $errorMsg    =~ s{ \s+ \z }{}xms;
    $errorMsg    = "Error saving regular session file to " . $obj->getSessionPath() . ": $errorMsg ($!)";
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
sub _getSessionPath {
  my ($obj, $rootDir) = @_;
  die "Session has no ID" unless $obj->getId();
  return "$rootDir/" . $obj->getId() . '.ses' if $obj->getId() !~ m{ \A \d{8} _ }xms; # For compatibility with old session IDs
  
  my $filePath = $context->getSingleton('O2::File')->distributePath(
    id       => $obj->getId(),
    levels   => 4,
    rootDir  => $rootDir,
    fileName => $obj->getId() . '.ses',
    mkDirs   => 1,
  );
  return $filePath;
}
#-----------------------------------------------------------------------------
sub getSessionRoot {
  return $config->get('session.sessionRoot');
}
#--------------------------------------------------------------------------------------------------
1;
