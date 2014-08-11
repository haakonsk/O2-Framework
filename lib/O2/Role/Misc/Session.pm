package O2::Role::Misc::Session;

use strict;

use constant DEBUG => 0;

use O2 qw($context $config $cgi);

#-----------------------------------------------------------------------------
sub _init {
  my ($obj, %params) = @_;
  $obj->{sessionId}      = '';
  $obj->{values}         = {};
  $obj->{oldSessions}    = [];
  $obj->{needsToBeSaved} = 0;
  foreach my $key (keys %params) {
    $obj->{$key} = $params{$key};
  }
  $obj->{sessionId} ||= $obj->getExistingSessionId();
  
  if ($obj->{sessionId}) {
    $obj->loadSession();
  }
  else {
    $obj->{sessionId} = $obj->getUniqueId();
  }
  debug "Session ID for $obj->{sessionName}: $obj->{sessionId}";
}
#-----------------------------------------------------------------------------
sub getSessionName {
  my ($obj) = @_;
  return $obj->{sessionName};
}
#-----------------------------------------------------------------------------
# Returns the session id
sub getId {
  my ($obj) = @_;
  return $obj->{sessionId};
}
#-----------------------------------------------------------------------------
sub setId {
  my ($obj, $sessionId) = @_;
  $obj->regenerateId($sessionId);
  $obj->loadSession();
}
#-----------------------------------------------------------------------------
# Regenerates the session id
sub regenerateId {
  my ($obj, $id) = @_;
  $obj->{sessionId}      = $id || $obj->getUniqueId();
  $obj->{needsToBeSaved} = 1;
  debug "regenerate ID for $obj->{sessionName}, new ID: $obj->{sessionId}";
}
#-----------------------------------------------------------------------------
sub getExistingSessionId {
  my ($obj) = @_;
  return '';
}
#-----------------------------------------------------------------------------
sub isEmpty {
  my ($obj) = @_;
  return !%{ $obj->{values} };
}
#-----------------------------------------------------------------------------
# Get the value of a session variable by name
sub get {
  my ($obj, $name) = @_;
  my $value = $obj->{values}->{$name};
  return $value unless length $value;
  
  if (my ($_value) = $value =~ m{ \A __SERIALIZED_OBJECT: (.*) \z }xms) {
    $value = $context->getSingleton('O2::Util::Serializer', format => 'PLDS')->unserialize($_value);
  }
  return $value;
}
#-----------------------------------------------------------------------------
sub getSessionVariableNames {
  my ($obj) = @_;
  return keys %{ $obj->{values} };
}
#-----------------------------------------------------------------------------
# Stack away the current session variables. Your current session variables are cleared.
sub pushSession {
  my ($obj) = @_;
  push @{ $obj->{oldSessions} }, $obj->{values};
  $obj->{values}         = {};
  $obj->{needsToBeSaved} = 1;
}
#-----------------------------------------------------------------------------
sub canPopSession {
  my ($obj) = @_;
  return defined @{ $obj->{oldSessions} } && @{ $obj->{oldSessions} };
}
#-----------------------------------------------------------------------------
sub popSession {
  my ($obj) = @_;
  return unless $obj->canPopSession();
  
  $obj->{values}         = pop @{ $obj->{oldSessions} };
  $obj->{needsToBeSaved} = 1;
}
#-----------------------------------------------------------------------------
# Deletes the current and pushed session variables
sub clearSession {
  my ($obj) = @_;
  $obj->{values}         = {};
  $obj->{oldSessions}    = [];
  $obj->{needsToBeSaved} = 1;
}
#-----------------------------------------------------------------------------
# Sets a session variable
sub set {
  my ($obj, $name, $value) = @_;
  $value = '__SERIALIZED_OBJECT:' . $value->serialize() if ref ($value) =~ m{ ::Obj:: }xms  &&  $value->isSerializable();
  $obj->{values}->{$name} = $value;
  $obj->{needsToBeSaved} = 1;
}
#-----------------------------------------------------------------------------
# Deletes a session variable by name
sub delete {
  my ($obj, $name) = @_;
  delete $obj->{values}->{$name};
  $obj->{needsToBeSaved} = 1;
}
#-----------------------------------------------------------------------------
# Optional attribute position. By default the most recently pushed session's variables are returned
# (corresponds to position=1).
sub getPushedSessionValues {
  my ($obj, $position) = @_;
  $position ||= 1;
  return $obj->{oldSessions}->[-$position] || {};
}
#-----------------------------------------------------------------------------
# Return the session variables for the actually (originally) logged in user.
sub getOriginalSessionValues {
  my ($obj) = @_;
  return $obj->{oldSessions}->[0];
}
#-----------------------------------------------------------------------------
# Generates a unique (hopefully) id
sub getUniqueId {
  my ($obj) = @_;
  my $today = $context->getSingleton('O2::Util::SwedishDates')->getToday();
  return "${today}_$ENV{UNIQUE_ID}" if $ENV{UNIQUE_ID};
  return "${today}_" . int (rand 999_999_999_999_999) . '_' . time;
}
#-----------------------------------------------------------------------------
sub newFromId {
  die "Use 'sessionId' parameter in constructor instead";
}
#--------------------------------------------------------------------------------------------------
sub isFrontend {
  return 1; # Default yes
}
#--------------------------------------------------------------------------------------------------
sub getNeedAuthRedirectUrl {
  return $config->get('dispatcher.needAuthRedirectUrl');
}
#--------------------------------------------------------------------------------------------
1;
