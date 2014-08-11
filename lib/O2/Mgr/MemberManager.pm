package O2::Mgr::MemberManager;

use strict;

use base 'O2::Mgr::PersonManager';

use O2 qw($context $db);
use O2::Obj::Member;

#-----------------------------------------------------------------------------
sub initModel {
  my ($obj, $model) = @_;
  $obj->SUPER::initModel($model);
  $model->registerFields(
    'O2::Obj::Member',
    # Your class definition goes here:
    #-----------------------------------------------------------------------------
    username => { type => 'varchar', length => 100 },
    password => { type => 'varchar', length => 50  },
    #-----------------------------------------------------------------------------
  );
  $model->registerIndexes(
    'O2::Obj::Member',
    { name => 'usernameIndex', columns => [qw(username)], isUnique => 1 },
  );
}
#-----------------------------------------------------------------------------
sub save {
  my ($obj, $object) = @_;
  $object->setMetaName(   $object->getUsername() );
  $object->setMetaStatus( 'active'               ) unless $object->getMetaStatus();
  my $username = $object->getUsername();
  $obj->SUPER::save($object);
}
#-----------------------------------------------------------------------------
sub usernameExists {
  my ($obj, $username) = @_;
  die "No user name given" unless $username;

  # Make sure to call objectIdSearch on a manager of this class (O2::Mgr::MemberManager),
  # so that all rows in the O2_OBJ_MEMBER table are searched.
  my $mgr = ref ($obj) eq __PACKAGE__  ?  $obj  :  $context->getSingleton(__PACKAGE__);

  my @objectIds = $mgr->objectIdSearch(
    username => $username,
  );
  return @objectIds > 0;
}
#-----------------------------------------------------------------------------
sub getMemberByUsername {
  my ($obj, $username) = @_;
  my ($member) = $obj->objectSearch(
    username   => $username,
    metaStatus => { 'not in' => [ qw(inactive trashed trashedAncestor deleted) ] },
  );
  return $member;
}
#-----------------------------------------------------------------------------
sub canLoginAs {
  my ($obj, $currentUserId, $loginAsUserId) = @_;
  my @userIds = $db->selectColumn("select userid from O2_OBJ_MEMBER_LOGINAS where masteruserid = ?", $currentUserId);
  foreach my $userId (@userIds) {
    return 1 if $userId eq $loginAsUserId || $userId eq '-1';
  }
  return 0;
}
#-----------------------------------------------------------------------------
sub getCanLoginAsUserIds {
  my ($obj, $currentUserId) = @_;
  return $obj->canLoginAsUserIds($currentUserId);
}
#-----------------------------------------------------------------------------
sub canLoginAsUserIds {
  my ($obj, $currentUserId) = @_;
  if ($obj->canLoginAsAll($currentUserId)) {
    return $obj->objectIdSearch(
      metaStatus => 'active',
    );
  }
  return $db->selectColumn("select userid from O2_OBJ_OBJECT o, O2_OBJ_MEMBER_LOGINAS l where l.userid = o.objectId and l.masteruserid = ? and o.status = 'active'", $currentUserId);
}
#-----------------------------------------------------------------------------
sub canLoginAsAll {
  my ($obj, $currentUserId) = @_;
  my @userIds = $db->selectColumn("select userid from O2_OBJ_MEMBER_LOGINAS where masteruserid = ?", $currentUserId);
  foreach my $userId (@userIds) {
    return 1 if $userId eq '-1';
  }
  return 0;
}
#-----------------------------------------------------------------------------
sub addCanLoginAsMember {
  my ($obj, $masterUserId, $userId) = @_;
  return if $masterUserId == $userId || $obj->canLoginAsAll();
  my $uId = $db->fetch("select userid from O2_OBJ_MEMBER_LOGINAS where masteruserid = ? and userid = ?", $masterUserId, $userId);
  if (!$uId) {
    $db->do("insert into O2_OBJ_MEMBER_LOGINAS (masteruserid, userid) values (?, ?)", $masterUserId, $userId);
  }
}
#-----------------------------------------------------------------------------
sub setCanLoginAsAll {
  my ($obj, $masterUserId) = @_;
  $db->do("delete from O2_OBJ_MEMBER_LOGINAS where masteruserid = ?", $masterUserId);
  $db->do("insert into O2_OBJ_MEMBER_LOGINAS (masteruserid, userId) values (?, ?)", $masterUserId, -1);
}
#-----------------------------------------------------------------------------
sub deleteCanLoginAs {
  my ($obj, $masterUserId, $userId) = @_;
  $db->do("delete from O2_OBJ_MEMBER_LOGINAS where masteruserid = ? and userid = ?", $masterUserId, $userId);
}
#-----------------------------------------------------------------------------
sub getMemberHashById {
  my ($obj, $memberId) = @_;
  my ($username, $password, $email, $firstName, $middleName, $lastName) = $db->fetch(
    "select username, password, email, firstName, middleName, lastName from O2_OBJ_MEMBER m, O2_OBJ_PERSON p where m.objectId = p.objectId and m.objectId = ?", $memberId
  );
  return (
    username   => $username,
    password   => $password,
    email      => $email,
    firstName  => $firstName,
    middleName => $middleName,
    lastName   => $lastName,
  );
}
#-----------------------------------------------------------------------------
1;
