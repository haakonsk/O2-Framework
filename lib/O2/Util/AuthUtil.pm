package O2::Util::AuthUtil;

use strict;

use O2 qw($context);

#------------------------------------------------------------
sub new {
  my ($pkg, %params) = @_;
  my $obj = bless {}, $pkg;
  return $obj;
}
#------------------------------------------------------------
sub getUserId {
  my ($obj) = @_;
  unless ($obj->{userId}) {
    my $session = $context->getSession();
    $obj->setUserId( $session->get('user')->{userId} );
  }
  return $obj->{userId};
}
#------------------------------------------------------------
sub setUserId {
  my ($obj, $userId) = @_;
  $obj->{userId} = $userId;
}
#------------------------------------------------------------
sub userIsOwnerOfObjectId {
  my ($obj, $objectId) = @_;
  my $userId = $obj->getUserId();
  my $object = $context->getObjectById($objectId);
  return $object->getMetaOwnerId() == $userId;
}
#------------------------------------------------------------
sub memberMustHaveAttribute {
  my ($obj, $attributeKey, $attributeValue) = @_;
  my $userId = $obj->getUserId();
  my $member = $context->getObjectById($userId);
  return $member->getAttribute($attributeKey) == $attributeValue;
}
#------------------------------------------------------------
1;
