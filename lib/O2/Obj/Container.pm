package O2::Obj::Container; # Superclass for all container classes

use strict;

use base 'O2::Obj::Object';

use O2 qw($context);

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
sub isSerializable {
  return 1;
}
#-------------------------------------------------------------------------------
# add an object to this container
sub addObject {
  my ($obj, $fromContainer, $object) = @_;
  return unless $obj->canAddObject($fromContainer, $object);
  
  $object->setMetaParentId( $obj->getId() );
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
  my ($obj, $skip, $limit, %searchParams) = @_;
  delete $searchParams{_folderCode};
  return $context->getSingleton('O2::Mgr::MetaTreeManager')->getChildren( $obj->getId(), $skip, $limit, %searchParams );
}
#-------------------------------------------------------------------------------
sub getChildIds {
  my ($obj, $skip, $limit, %searchParams) = @_;
  delete $searchParams{_folderCode};
  return $context->getSingleton('O2::Mgr::MetaTreeManager')->getChildIds($obj, $skip, $limit, %searchParams);
}
#-------------------------------------------------------------------------------
sub getChildSortMethod {
  my ($obj) = @_;
  my $method = $obj->getPropertyValue($obj, 'childSortMethod');
  return $method || 'alphabetical';
}
#-------------------------------------------------------------------------------
sub setChildSortMethod {
  my ($obj, $value) = @_;
  $obj->setPropertyValue($obj->getId(), 'childSortMethod', $value);
}
#-------------------------------------------------------------------------------
sub getChildSortDirection {
  my ($obj) = @_;
  return $obj->getPropertyValue($obj, 'childSortDirection')  ||  'asc';
}
#-------------------------------------------------------------------------------
sub setChildSortDirection {
  my ($obj, $value) = @_;
  $obj->setPropertyValue($obj->getId(), 'childSortDirection', $value);
}
#-------------------------------------------------------------------------------
sub deletePermanently {
  my ($obj, %params) = @_;
  my $level  = $params{level} || 0;
  my $indent = '  ' x $level;
  $params{level}++;
  if ($params{recursive}) {
    my @children = $obj->getChildren( undef, undef, metaStatus => { like => '%' } );
    foreach my $child (@children) {
      printf "${indent}Deleting %s (%d)\n", $child->getMetaName(), $child->getId() if $params{verbose};
      $child->deletePermanently(%params);
    }
  }
  else {
    my ($id) = $obj->getChildIds( 0, 1, metaStatus => { like => '%' } );
    die sprintf "Can't delete container \"%s\" (%d): Not empty", $obj->getMetaName(), $obj->getId() if $id;
  }
  $params{level}--;
  $obj->SUPER::deletePermanently(%params);
}
#-------------------------------------------------------------------------------
1;
