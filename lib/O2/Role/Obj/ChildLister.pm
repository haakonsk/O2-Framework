package O2::Role::Obj::ChildLister;

use strict;

use O2 qw($context);

#-------------------------------------------------------------------------------
# returns true if you may move this object to $toContainer
sub canMove {
  my ($obj, $fromContainer, $toContainer) = @_;
  return 0;
}
#-------------------------------------------------------------------------------
# returns true if you may add $object to this container
sub canAddObject {
  my ($obj, $fromContainer, $object) = @_;
  return 0;
}
#-------------------------------------------------------------------------------
# returns true if you may remove $object from this container
sub canRemoveObject {
  my ($obj, $toContainer, $object) = @_;
  return 0;
}
#-------------------------------------------------------------------------------
# add an object to this container
sub addObject {
  my ($obj, $fromContainer, $object) = @_;
  return unless $obj->canAddObject($fromContainer, $object);
  $object->setMetaParentId($obj->getId());
  $object->save();
}
#-------------------------------------------------------------------------------
# remove an object from this container
sub removeObject {
  my ($obj, $toContainer, $object) = @_;
}
#-------------------------------------------------------------------------------
# returns true since all subclasses are containers
sub isContainer {
  my ($obj) = @_;
  return 1;
}
#-------------------------------------------------------------------------------
# returns an array of child objects
sub getChildren {
  my ($obj, $skip, $limit) = @_;
  return $context->getSingleton('O2::Mgr::MetaTreeManager')->getChildren( $obj->getId(), $skip, $limit );
}
#-------------------------------------------------------------------------------
sub getChildIds {
  my ($obj, $skip, $limit) = @_;
  return $context->getSingleton('O2::Mgr::MetaTreeManager')->getChildIds($obj, $skip, $limit);
}
#-------------------------------------------------------------------------------
1;
