package O2::Mgr::PropertyManager;

# Takes care of "properties". Properties are values that are inherited down in the tree.
# I.e. if you set color=blue on the installation object, you will get "blue" if you ask a site for "color", unless you override color on the site.

use strict;

use O2 qw($context $db);
use O2::Mgr::PropertyManager::Property;

#--------------------------------------------------------------------------------------------
sub new {
  my ($pkg, %init) = @_;
  my $obj = bless \%init, $pkg;
  $obj->{tableCache} = {};
  return $obj;
}
#--------------------------------------------------------------------------------------------
sub newObject {
  my ($obj) = @_;
  return O2::Mgr::PropertyManager::Property->new(manager=>$obj);
}
#--------------------------------------------------------------------------------------------
sub getProperty {
  my ($obj, $objectId, $name) = @_;
  my %property = $obj->_resolveProperty($objectId, $name);
  return unless $property{originatorId};
  
  my $property = $obj->newObject();
  $property->setObjectId(     $objectId               );
  $property->setName(         $name                   );
  $property->setValue(        $property{value}        );
  $property->setOriginatorId( $property{originatorId} );
  return $property;
}
#--------------------------------------------------------------------------------------------
# set direct property
sub setPropertyValue {
  my ($obj, $objectId, $name, $value) = @_;
  delete $obj->{tableCache}->{$name}->{$objectId};
  if ( $db->fetch('select count(objectId) from O2_OBJ_OBJECT_PROPERTY where objectId=? and name=?', $objectId, $name) ) {
    $db->sql('update O2_OBJ_OBJECT_PROPERTY set value=? where objectId=? and name=?', $value, $objectId, $name);
  }
  else {
    $db->insert('O2_OBJ_OBJECT_PROPERTY', objectId=>$objectId, name=>$name, value=>$value);
  }
}
#--------------------------------------------------------------------------------------------
# return direct or inherited value
sub getPropertyValue {
  my ($obj, $objectOrObjectId, $name) = @_;
  my %property = $obj->_resolveProperty($objectOrObjectId, $name);
  return $property{value};
}
#--------------------------------------------------------------------------------------------
# remove direct property
sub deletePropertyValue {
  my ($obj, $objectId, $name) = @_;
  delete $obj->{tableCache}->{$name}->{$objectId};
  $db->sql('delete from O2_OBJ_OBJECT_PROPERTY where objectId = ? and name = ?', $objectId, $name);
}
#--------------------------------------------------------------------------------------------
sub getDirectProperties {
  my ($obj, $objectId) = @_;
  my @results = $db->fetchAll("select name, value from O2_OBJ_OBJECT_PROPERTY where objectId=?", $objectId);
  my %properties;
  foreach (@results) {
    $properties{ $_->{name} } = $_->{value};
  }
  return %properties;
}
#--------------------------------------------------------------------------------------------
# lookup direct or inherited property
sub _resolveProperty {
  my ($obj, $objectOrObjectId, $name) = @_;
  my $originatorId = ref $objectOrObjectId ? $objectOrObjectId->getId() : $objectOrObjectId;
  my ($value, $isSet);
  my $maxLoops = 10;
  while ($originatorId && $originatorId > 0 && --$maxLoops >= 0) {
    if (ref $obj->{tableCache}->{$name}->{$originatorId}) {
      ($isSet, $value) = @{ $obj->{tableCache}->{$name}->{$originatorId} };
    }
    else {
      ($isSet, $value) = $db->fetch('select 1, value from O2_OBJ_OBJECT_PROPERTY where objectId=? and name=?', $originatorId, $name);
      $obj->{tableCache}->{$name}->{$originatorId} = [$isSet, $value];
    }
    return (
      originatorId => $originatorId,
      value        => $value,
    ) if $isSet;
    $originatorId = $obj->_getParentId($originatorId);
  }
  return ();
}
#--------------------------------------------------------------------------------------------
sub _getParentId {
  my ($obj, $objectId) = @_;
  return $obj->{parentIds}->{$objectId} if exists $obj->{parentIds}->{$objectId};
  return $obj->{parentIds}->{$objectId} = $db->fetch('select parentId from O2_OBJ_OBJECT where objectId = ?', $objectId);
}
#--------------------------------------------------------------------------------------------
# returns all properties with a certain name
sub getPropertiesByName {
  my ($obj, $name) = @_;
 
  my @properties;
  my $sth = $db->prepare('select objectId, value from O2_OBJ_OBJECT_PROPERTY where name=?');
  $sth->execute($name);
  while ( my ($objectId, $value) = $sth->next() ) {
    my $property = $obj->newObject();
    $property->setObjectId(     $objectId );
    $property->setName(         $name     );
    $property->setValue(        $value    );
    $property->setOriginatorId( $objectId );
    push @properties, $property;
  }
  return @properties;
}
#--------------------------------------------------------------------------------------------
# returns all properties available for an object (direct and inherited)
sub getPropertiesById {
  my ($obj, $objectId) = @_;
  
  my %properties;
  my $metaTreeMgr = $context->getSingleton('O2::Mgr::MetaTreeManager');
  my @idPath = ( $objectId, reverse $metaTreeMgr->getIdPathTo($objectId) ); # reverse path (starting with object, ending with installation
  
  foreach my $pathId (@idPath) {
    my $object = $context->getObjectById($pathId);
    my %direct = $obj->getDirectProperties($pathId);
    foreach my $name (keys %direct) {
      next if exists $properties{$name};  # property already set closer to object

      my $property = $obj->newObject();
      $property->setObjectId(     $objectId      );
      $property->setName(         $name          );
      $property->setValue(        $direct{$name} );
      $property->setOriginatorId( $pathId        );
      $properties{$name} = $property;
    }
  }
  return sort { $a->getName() cmp $b->getName() } values %properties;
}
#--------------------------------------------------------------------------------------------
1;
