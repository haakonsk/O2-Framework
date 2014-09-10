package O2::Mgr::UniversalManager;

use strict;

use base 'O2::Mgr::ObjectManager';

use O2 qw($context $db);

our $MANAGER_CACHE;
#------------------------------------------------------------------
sub newObject {
  die 'Cannot make a new object';
}
#------------------------------------------------------------------
sub newObjectByClassName {
  my ($obj, $className) = @_;
  die 'No class name given' unless $className;
  
  my $mgr = $obj->getManagerByClassName($className);
  die "Can't find manager for class '$className'" unless $mgr;
  
  my $object = $mgr->newObject();
  return $object;
}
#------------------------------------------------------------------
sub unserializeObject {
  my ($obj, $serialized) = @_;
  die 'Nothing to unserialize' unless $serialized;
  
  my $unserializedRaw = $context->getSingleton('O2::Data')->undump($serialized) or die "Couldn't undump object: $@.<br>\nObject was $serialized";
  return $obj->getObjectByPlds($unserializedRaw);
}
#------------------------------------------------------------------
sub getObjectByPlds {
  my ($obj, $plds) = @_;
  die 'Not a valid PLDS' unless ref $plds eq 'HASH';
  
  my $className = $plds->{meta}->{className};
  die 'Could not figure out what class we are' unless $className;
  
  my $object = $obj->newObjectByClassName($className);
  die 'Class ' . ref ($object) . ' is not unserializable' unless $object->isSerializable();
  
  $object->setMetaPlds(       $plds->{meta}         );
  $object->setContentPlds(    $plds->{data}         ) or die "Could not unserialize $className: $@";
  $object->setKeywordIds(  @{ $plds->{keywordIds} } ) if $plds->{keywordIds};
  foreach (keys %{$plds}) {
    next if $_ eq 'objectClass' || $_ eq 'meta' || $_ eq 'data' || $_ eq 'keywordIds';
    $object->{$_} = $plds->{$_};
  }
  
  $object->getManager()->setOriginalListFieldTableValues($object);
  
  return $object;
}
#------------------------------------------------------------------
# returns object based on objectId. The actual retrieval is done by the manager matching the objectclass.
sub getObjectById {
  my ($obj, $objectId, %params) = @_;
  die 'getObjectById: No ID given' unless $objectId;

  my $manager = eval {
    $obj->getManagerByObjectId($objectId);
  };
  die "Couldn't instantiate object with id $objectId: Error getting manager by objectId: $@" if $@;

  if (!$manager && !$params{searchingArchive}) { # objectId not found in database or status=deleted
    # Try to find object in archive database
    $context->useArchiveDbh();
    my $object = eval {
      $obj->getObjectById($objectId, searchingArchive => 1);
    };
    my $errorMsg = $@;
    $context->usePreviousDbh();
    die "Couldn't instantiate object from archive database: $errorMsg" if $errorMsg;

    return $object;
  }
  return $manager->getObjectById($objectId);
}
#------------------------------------------------------------------
# returns trashed object based on objectId. The actual retrieval is done by the manager matching the objectclass.
sub getTrashedObjectById {
  my ($obj, $objectId) = @_;
  my $manager = $obj->getManagerByObjectId($objectId);
  return unless $manager;
  return $manager->getTrashedObjectById($objectId);
}
#------------------------------------------------------------------
# return all objects of a class
sub getObjectsByClassNameAndStatus {
  my ($obj, $className, $status) = @_;
  my @objectIds = $obj->getObjectIdsByClassNameAndStatus($className, $status);
  my @objects;
  foreach my $objectId (@objectIds) {
    push @objects, $obj->getObjectById($objectId);
  }
  return @objects;
}
#------------------------------------------------------------------
sub getObjectIdsByClassNameAndStatus {
  my ($obj, $className, $status) = @_;
  my @objectIds = $db->selectColumn('select objectId from O2_OBJ_OBJECT where className = ? and status = ?', $className, $status);
  return @objectIds;
}
#------------------------------------------------------------------
# returns manager used for handling object
sub getManagerByObjectId {
  my ($obj, $objectId) = @_;
  die "getManagerByObjectId($objectId) called without objectId parameter" unless $objectId > 0;
  
  return $MANAGER_CACHE->{$objectId} if exists $MANAGER_CACHE->{$objectId};
  
  my $className    = $db->fetch('select className from O2_OBJ_OBJECT where objectId = ?', $objectId);
  my $managerClass = $obj->_guessManagerClassName($className);
  return '' unless $managerClass;
  
  my $manager = $obj->getManagerByName($managerClass);
  die "Could not instantiate manager ($managerClass) for objectId $objectId" unless ref $manager;
  return $MANAGER_CACHE->{$objectId} = $manager;
}
#------------------------------------------------------------------
# returns manager object used for handling a class
sub getManagerByClassName {
  my ($obj, $className) = @_;
  die 'Name of class is empty' unless $className;
  
  my $managerClassName = $context->getSingleton('O2::Mgr::ClassManager')->getManagerClassByClassName($className);
  $managerClassName  ||= $obj->_guessManagerClassName($className);
  return $obj->getManagerByName($managerClassName);
}
#------------------------------------------------------------------
# instantiates and returns a manager object from its classname
sub getManagerByName {
  my ($obj, $managerClass) = @_;
  die 'Name of manager class is empty' unless $managerClass;
  
  my $manager = eval {
    return $context->getSingleton($managerClass);
  };
  die "Couldn't instantiate manager '$managerClass': $@" if $@ || !$manager;
  return $manager;
}
#------------------------------------------------------------------
sub _guessManagerClassName {
  my ($obj, $className) = @_;
  $className ||= '';
  if ($className =~ m/::Obj::/) {
    $className =~ s/(::)Obj::/$1Mgr$1/;
    $className.= 'Manager';
  }
  else {
    $className =~ s/^(\w+)(::)(.+)/$1$2Mgr$2$3Manager/;
  }
  return $className;
}
#------------------------------------------------------------------
sub objectClassNameToManagerClassName {
  my ($obj, $objectClass) = @_;
  my $mgrClass = "${objectClass}Manager";
  $mgrClass =~ s{ ::Obj:: }{::Mgr::}xms;
  return $mgrClass;
}
#------------------------------------------------------------------
sub managerClassNameToObjectClassName {
  my ($obj, $mgrClass) = @_;
  my $objectClass = $mgrClass;
  $objectClass    =~ s{ Manager \z }{}xms;
  $objectClass    =~ s{ ::Mgr:: }{::Obj::}xms;
  return $objectClass;
}
#------------------------------------------------------------------
1;
