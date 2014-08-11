package O2::Obj::Member;

use strict;

use base 'O2::Obj::Person';

use O2 qw($config $db);

#-----------------------------------------------------------------------------
sub isSerializable {
  return 1;
}
#-----------------------------------------------------------------------------
sub isDeletable {
  return 1;
}
#-----------------------------------------------------------------------------
sub getCanLogInAsUserIds {
  my ($obj) = @_;
  return $obj->{canLogInAsUserIds};
}
#-----------------------------------------------------------------------------
sub setCanLogInAsUserIds {
  my ($obj, $userIds) = @_;
  $obj->{canLogInUserIds} = $userIds;
}
#-----------------------------------------------------------------------------
sub canLogInAs {
  my ($obj, $userId) = @_;
  foreach my $id ($obj->{canLogInAsUserIds}) {
    return 1 if $userId == $id;
  }
  return 0;
}
#-----------------------------------------------------------------------------
sub asString {
  my ($obj) = @_;
  my $string = '';
  $string .= "username: "   . $obj->getUsername()   . ", ";
  $string .= "email: "      . $obj->getEmail()      . ", ";
  $string .= "firstName: "  . $obj->getFirstName()  . ", ";
  $string .= "middleName: " . $obj->getMiddleName() . ", ";
  $string .= "lastName: "   . $obj->getLastName()   . ", ";
  $string .= "status: "     . $obj->getMetaStatus() . ", ";
  foreach my $key (keys %{ $obj->{attributes} }) {
    $string .= "$key: $obj->{attributes}->{$key}, ";
  }
  return $string;
}
#--------------------------------------------------------------------------------------#
sub delete {
  my ($obj) = @_;
  $obj->setMetaStatus('inactive');
  $obj->save();
}
#-----------------------------------------------------------------------------
sub getIndexableFields {
  my ($obj) = @_;
  return ( $obj->SUPER::getIndexableFields(), 'username' );
}
#-----------------------------------------------------------------------------
sub getPassword {
  my ($obj, $default) = @_;
  if ( lc ( $config->get('o2.encryptPasswords') )  eq  'yes' ) {
    # Normally, when passwords are encrypted (and we therefore don't know what the password is), getPassword cannot return the password,
    # so we return the $default value provided (or nothing at all).
    return $default;
  }
  return $obj->getModelValue('password');
}
#-----------------------------------------------------------------------------
sub setPassword {
  my ($obj, $password) = @_;
  if ( lc ( $config->get('o2.encryptPasswords') )  eq  'yes' ) {
    # Hack: If called from the init method in ObjectManager, we want to set the password field to the encrypted value fetched from the database.
    # If called from anywhere else, we assume the given $password is not a hash, so we must encrypt it.
    my $callerMethod = (caller 2)[3];
    require O2::Util::Crypt;
    $password = O2::Util::Crypt->crypt( $password, O2::Util::Crypt->salt() ) if $callerMethod ne 'O2::Mgr::ObjectManager::init';
  }
  $obj->setModelValue('password', $password);
}
#-----------------------------------------------------------------------------
sub isCorrectPassword {
  my ($obj, $given) = @_;
  my $correct = $obj->getModelValue('password');
  die sprintf "User '%s' doesn't have a password", $obj->getUsername() unless $correct;
  
  if ( lc ( $config->get('o2.encryptPasswords') )  eq  'yes' ) {
    require O2::Util::Crypt;
    return $correct eq O2::Util::Crypt->crypt($given, substr $correct, 0, 2);
  }
  return $correct eq $given;
}
#-----------------------------------------------------------------------------
1;
