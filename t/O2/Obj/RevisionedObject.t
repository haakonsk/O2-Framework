use strict;
use warnings;

use Test::More qw(no_plan);
use O2 qw($context);

my $revisionedObjectMgr = $context->getSingleton('O2::Mgr::RevisionedObjectManager');
my $revision = $revisionedObjectMgr->newObject();
$revision->setMetaName('testscript O2::Obj::RevisionedObject/O2::Mgr::RevisionedObjectManager');
$revision->setRevisionedObjectId(12);
$revision->setSerializedObject(12);
$revision->save();
ok($revision->getId()>0, 'Revision saved ok');

my $dbRevision = $revisionedObjectMgr->getObjectById($revision->getId());
ok(ref $dbRevision eq 'O2::Obj::RevisionedObject', 'Revision retrieved');
ok($revision->getRevisionedObjectId() eq $dbRevision->getRevisionedObjectId(), 'revisionedObjectId column match');
ok($revision->getSerializedObject()   eq $dbRevision->getSerializedObject(),   'serializedObject column match');

END {
  $revision->deletePermanently() if $revision;
}
