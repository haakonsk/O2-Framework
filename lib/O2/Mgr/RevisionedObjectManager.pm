package O2::Mgr::RevisionedObjectManager;

use strict;

use base 'O2::Mgr::ObjectManager';

use O2 qw($context);
use O2::Obj::RevisionedObject;

#-------------------------------------------------------------------------------
sub initModel {
  my ($obj, $model) = @_;
  $obj->SUPER::initModel($model);
  $model->registerFields(
    'O2::Obj::RevisionedObject',
    # Your class definition goes here:
    #-----------------------------------------------------------------------------
    revisionedObjectId => { type => 'int', notNull => 1        },
    serializedObject   => { type => 'mediumtext', notNull => 1 },
    #-----------------------------------------------------------------------------
  );
  $model->registerIndexes(
    'O2::Obj::RevisionedObject',
    { name => 'revisionedObjectId_idx', columns => [qw(revisionedObjectId)], isUnique => 0 },
  );
}
#-------------------------------------------------------------------------------
sub getRevisionsByObjectId {
  my ($obj, $revisionObjectId, $skip, $limit) = @_;
  my %extraSearchParams;
  $extraSearchParams{-skip}  = $skip  if $skip;
  $extraSearchParams{-limit} = $limit if $limit;
  return $obj->objectSearch(
    metaClassName      => 'O2::Obj::RevisionedObject', # Don't want the drafts
    revisionedObjectId => $revisionObjectId,
    -orderBy           => 'objectId desc',
    %extraSearchParams,
  );
}
#-------------------------------------------------------------------------------
sub restoreRevisionById {
  my ($obj, $revisionId) = @_;
  my $revisionObject = $context->getObjectById($revisionId);
  return $obj->restoreRevision($revisionObject);
}
#-------------------------------------------------------------------------------
sub restoreRevision {
  my ($obj, $revisionObject) = @_;
  return $revisionObject->getUnserializedObject();
}
#-------------------------------------------------------------------------------
1;
