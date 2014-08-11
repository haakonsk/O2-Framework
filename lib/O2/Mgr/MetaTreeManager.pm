package O2::Mgr::MetaTreeManager;

# Responsible for the browsable tree representation of the O2 objects. Mainly a utility class.

use strict;

use O2 qw($context $db);
use O2::Util::List qw(upush);

#-----------------------------------------------------------------------------
sub new {
  my ($pkg, %init) = @_;
  return bless {
    objectMgr    => $context->getSingleton( 'O2::Mgr::ObjectManager'    ),
    universalMgr => $context->getSingleton( 'O2::Mgr::UniversalManager' ),
  }, $pkg;
}
#-----------------------------------------------------------------------------
# Returns objects based on parentId. result may be filtered through an extra query.
# Respects sorting properties of parent object
sub getChildIds {
  my ($obj, $parent, $skip, $limit, %searchParams) = @_;

  # Sorting
  if (!$searchParams{-orderBy} && $parent->can('getChildSortMethod')) {
    my $sortMethod    = $parent->getChildSortMethod();
    my $sortDirection = $parent->getChildSortDirection();
    my $orderBy
      = $sortMethod eq 'changeTime'  ?  'metaChangeTime'
      : $sortMethod eq 'createTime'  ?  'metaCreateTime'
      :                                 'metaName'
      ;
    $orderBy .= " $sortDirection";
    $searchParams{-orderBy} = $orderBy;
  }
  
  $searchParams{-skip}  = $skip  if $skip;
  $searchParams{-limit} = $limit if $limit;
  return $context->getSingleton('O2::Mgr::ObjectManager')->objectIdSearch(
    metaParentId => $parent->getId(),
    %searchParams,
  );
}
#-----------------------------------------------------------------------------
# returns recursive _all_ children objects. result may be filtered through an extra query.
sub getChildrenRecursive {
  my ($obj, $parentId, $skip, $limit) = @_;
  my @children = $obj->getChildren($parentId, $skip, $limit);
  foreach my $child (@children) {
    push @children, $obj->getChildrenRecursive( $child->getId(), $skip, $limit );
  }
  return @children;
}
#-----------------------------------------------------------------------------
sub getChildren {
  my ($obj, $parentId, $skip, $limit, %searchParams) = @_;
  
  my $parent   = $context->getObjectById($parentId) || $context->getUniversalMgr()->getTrashedObjectById($parentId);
  my @childIds = $parent->getChildIds($skip, $limit, %searchParams);
  
  # Trash must be handled differently than the rest:
  if ($parent && $parent->isTrashed()) {
    my $query = "select objectId from O2_OBJ_OBJECT where parentId = ?";
    $query .= ' limit ' if $limit;
    $query .= "$skip, " if $limit && $skip;
    $query .= $limit    if $limit;
    @childIds = $db->selectColumn($query, $parentId);
    my @children;
    foreach my $id (@childIds) {
      push @children, $obj->{universalMgr}->getTrashedObjectById($id);
    }
    return @children;
  }
  
  return $context->getObjectsByIds(@childIds);
}
#-----------------------------------------------------------------------------
sub getChildIdsRecursive {
  my ($obj, $parentIds) = @_;
  $parentIds = [$parentIds] if ref $parentIds ne 'ARRAY';
  return if @{$parentIds} == 0;
  
  my @ids = $db->selectColumn('select objectId from O2_OBJ_OBJECT where parentId in (??)', $parentIds);
  push @ids, $obj->getChildIdsRecursive(\@ids) if @ids;
  return @ids;
}
#-----------------------------------------------------------------------------
# returns ids of containers that contains objects
sub getContainerIdsRecursive {
  my ($obj, $parentId) = @_;
  my @containerIds = ($parentId);
  my @contentIds = $context->getSingleton('O2::Mgr::ObjectManager')->objectIdSearch(
    metaParentId => $parentId,
    -isa         => 'O2::Obj::Container',
  );
  upush @containerIds, @contentIds;
  foreach my $id (@contentIds) {
    upush @containerIds, $obj->getContainerIdsRecursive($id);
  }
  return @containerIds;
}
#-----------------------------------------------------------------------------
sub _getObjectByObjectOrObjectId {
  my ($obj, $objectOrObjectId, $canBeTrashed) = @_;
  return unless $objectOrObjectId;
  return $objectOrObjectId if ref $objectOrObjectId;
  return $context->getObjectById($objectOrObjectId) || $obj->{universalMgr}->getTrashedObjectById($objectOrObjectId);
}
#-----------------------------------------------------------------------------
sub getObjectPath {
  my ($obj, $objectOrObjectId) = @_;
  my $object = $obj->_getObjectByObjectOrObjectId($objectOrObjectId);
  return $obj->_getObjectPath( $object, $obj->{universalMgr} );
}
#-----------------------------------------------------------------------------
sub getMetaObjectPath {
  my ($obj, $objectOrObjectId) = @_;
  my $object = $obj->_getObjectByObjectOrObjectId($objectOrObjectId);
  return $obj->_getObjectPath( $object, $obj->{objectMgr} );
}
#-----------------------------------------------------------------------------
sub _getObjectPath {
  my ($obj, $object, $manager) = @_;
  return unless $object;
  my @path = $obj->_getObjectPathTo($object, $manager);
  push @path, $object;
  return @path;
}
#-----------------------------------------------------------------------------
# returns array of parent metaobjects
sub getMetaObjectPathTo {
  my ($obj, $objectOrObjectId) = @_;
  my $object = $obj->_getObjectByObjectOrObjectId($objectOrObjectId);
  return $obj->_getObjectPathTo( $object, $obj->{objectMgr} );
}
#-----------------------------------------------------------------------------
sub getObjectPathTo {
  my ($obj, $object) = @_;
  return $obj->_getObjectPathTo( $object, $obj->{universalMgr} );
}
#-----------------------------------------------------------------------------
sub _getObjectPathTo {
  my ($obj, $object, $manager) = @_;
  return unless $object;

  my $status = $object->{preDeleteStatus} || $object->getMetaStatus();
  my $foundTrashedObject = $status =~ m{ \A trashed }xms;

  my @path;
  my $parentId = $object->getMetaParentId();
  while ($parentId && $parentId > 0) {
    $object = $manager->getObjectById($parentId) || $obj->{universalMgr}->getTrashedObjectById($parentId);
    return ()               if !$object || $object->getMetaStatus() eq 'deleted';
    $foundTrashedObject = 1 if             $object->isTrashed();
    push @path, $object;
    $parentId = $object->getMetaParentId();
  }
  @path = reverse @path;
  return $obj->_listTrashObjectPath(@path) if $foundTrashedObject;
  return @path;
}
#-----------------------------------------------------------------------------
sub _listTrashObjectPath {
  my ($obj, @path) = @_;
  while (@path) {
    my $status = $path[0]->getMetaStatus();
    last if $status =~ m{ \A trashed }xms;
    
    shift @path;
  }
  unshift @path, $context->getTrashcan();
  return @path;
}
#-----------------------------------------------------------------------------
# returns array of parentIds
sub getIdPathTo {
  my ($obj, $objectId) = @_;
  my @path;
  my $sth = $db->prepare("select parentId from O2_OBJ_OBJECT where objectId = ?");
  while ($objectId) {
    $sth->execute($objectId);
    ($objectId) = $sth->next();
    push @path, $objectId if defined $objectId;
  }
  return reverse @path;
}
#-----------------------------------------------------------------------------
# returns object based on path in tree (i.e. '/Installation/www.example.com/news')
sub getObjectByPath {
  my ($obj, $path) = @_;
  my $objectId = $obj->getObjectIdByPath($path);
  return unless $objectId;
  return $context->getObjectById($objectId);
}
#-----------------------------------------------------------------------------
# returns objectId based on path in tree (i.e. '/Installation/www.example.com/news')
sub getObjectIdByPath {
  my ($obj, $path) = @_;

  my $cachedObjectId = $context->getMemcached()->get($path);
  return $cachedObjectId if $cachedObjectId;

  my (@path) = $path =~ m|\/+([^\/]+)|g;
  my $objectId;
  my $sth = $db->prepare("select objectId from O2_OBJ_OBJECT where name = ? and (parentId = ? or (? is null and parentId is null)) and status not in ('trashed', 'trashedAncestor', 'deleted')");
  do {
    my $name = shift @path;
    $sth->execute($name, $objectId, $objectId);
    ($objectId) = $sth->nextArray();
    $sth->finish();
    return unless $objectId;
  } while (@path);

  $context->getMemcached()->set($path, $objectId, 3600); # default only live for one hour, it's a bit of a trade off here, but the above sql is extremly slow
  return $objectId;
}
#-----------------------------------------------------------------------------
sub getIdByClassName {
  my ($obj, $className) = @_;
  my $objectId = $db->fetch('select objectId from O2_OBJ_OBJECT where className = ?', $className);
  die ("Could not find objectId for classname '$className'") unless $objectId;
  return $objectId;
}
#-----------------------------------------------------------------------------
# move object to a container. returns errorcode if something goes wrong, otherwise undef
sub move {
  my ($obj, $objectId, $toContainerId) = @_;
  return 'sameContainer' if $objectId == $toContainerId;

  my ($object) = $context->getObjectById($objectId);
  return 'missingObject' unless $object;
  return 'sameContainer'     if $object->getMetaParentId() == $toContainerId;
  
  my ($toContainer) = $context->getObjectById($toContainerId);
  return 'missingToContainer' unless $toContainer;
  
  my $fromContainer;
  if ( $object->getMetaParentId() ) {
    $fromContainer = $context->getObjectById( $object->getMetaParentId() );
    return 'missingFromContainer' unless $fromContainer;
    return 'canNotRemove'         unless $fromContainer->canRemoveObject($toContainer, $object);
  }

  # avoid circular references
  my @idPath = $obj->getIdPathTo( $toContainer->getId() );
  return 'circularReference'      if grep { $_==$object->getId() } @idPath;
  return 'notContainer'       unless $toContainer->isContainer();
  return 'canNotAdd'          unless $toContainer->canAddObject($fromContainer, $object);
  
  # move to trash does not need to respect canMove(), since isDeletable() says the same thing.
  # This eliminates the need for typing "return 1 if $toContainer->isa('O2CMS::Obj::Trashcan')" in canMove() in every deletable object
  if ( !$toContainer->isa('O2CMS::Obj::Trashcan') ) {
    return 'canNotMove' unless $object->canMove($fromContainer, $toContainer);
  }

  $fromContainer->removeObject($toContainer, $object) if $fromContainer;
  $toContainer->addObject($fromContainer, $object);
  $object->objectMoved($fromContainer, $toContainer); # notify object
  return;
}
#-----------------------------------------------------------------------------
1;
