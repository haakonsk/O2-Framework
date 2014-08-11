use strict;
use warnings;

use Test::More qw(no_plan);
use O2 qw($context);

# keyword
my $keywordMgr = $context->getSingleton('O2::Mgr::KeywordManager');
my $keyword = $keywordMgr->newObject();
$keyword->setMetaName('Test keyword');
$keyword->setIsFolder(0);
$keyword->save();
ok($keyword->getId(), 'Keyword saved');

# childkeyword
my $childKeyword = $keywordMgr->newObject();
$childKeyword->setMetaName('Child keyword');
$childKeyword->setMetaParentId($keyword->getId());
$childKeyword->setIsFolder(0);
$childKeyword->save();
ok($childKeyword->getId(), 'childKeyword saved');

# tagged object
my $object = $keywordMgr->newObject();
$object->setMetaName('Object for testing keywords');
$object->setKeywordIds($childKeyword->getId());
$object->setIsFolder(0);
$object->save();
ok($object->getId(), 'Object saved');
$object = $keywordMgr->getObjectById($object->getId());
is_deeply([$object->getKeywordIds()], [$childKeyword->getId()], 'setKeywordIds() was saved');

# Test getChildren()
my @children = $keyword->getChildren();
ok(@children==1, 'Keyword has one child');
ok($children[0]->getId()==$childKeyword->getId(), 'Found child with getChildren()');

my @taggedObjectIds = $keywordMgr->getTaggedObjectIdsByKeywordIds($childKeyword->getId());
is_deeply(\@taggedObjectIds, [$object->getId()], 'Found object getTaggedObjectIdsByKeywordIds()');

my @taggedObjects = $keywordMgr->getTaggedObjectsByKeywordIds($childKeyword->getId());
is_deeply([ map {$_->getId()} @taggedObjects ], [$object->getId()], 'getTaggedObjectsByKeywordIds() returned correct objects');


@taggedObjectIds = $keywordMgr->getTaggedObjectsByRecursiveKeywordIds($keyword->getId());
is_deeply(\@taggedObjectIds, [$object->getId()], 'Found object via getTaggedObjectsByRecursiveKeywordIds()');

my @namedKeywords = $keywordMgr->getObjectsByNameMatch($keyword->getMetaName().'*');
ok((grep {$_->getId()==$keyword->getId()} @namedKeywords), 'Found keyword via getObjectsByNameMatch()');

my @parent = $childKeyword->getParentKeywords();
ok(@parent==1, 'Child has one parent keyword');
ok($parent[0]->getId()==$keyword->getId(), 'Parent is keyword');

# cleanup
END {
  $keyword->deletePermanently()      if $keyword;
  $childKeyword->deletePermanently() if $childKeyword;
  $object->deletePermanently()       if $object;
}
