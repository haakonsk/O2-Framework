# This file was originally auto-generated by O2 with contents hashing to 2e580db2d667bf5b712770b3d87214b4
use strict;

use Test::More qw(no_plan);
use O2::Script::Test::Common;

use_ok 'O2::Mgr::Object::QueryManager';

use O2 qw($context $config);

my @localeCodes = @{ $config->get('o2.locales') };
my $mgr = $context->getSingleton('O2::Mgr::Object::QueryManager');

my $newObj = $mgr->newObject();
$newObj->setMetaName('Test-script for O2::Obj::Object::Query/O2::Mgr::Object::QueryManager');
$newObj->setMetaStatus("Test-varchar");
$newObj->setMetaParentId( getTestObjectId() );
$newObj->setKeywordIds( getTestObjectId(), getTestObjectId() );
$newObj->setMetaOwnerId( getTestObjectId() );
$newObj->setMetaName("Test-varchar");
$newObj->setInFolderCondition( getTestObjectId() );
$newObj->setJoinWith('and');
$newObj->setDebug(1);
$newObj->setLimit(1);
$newObj->setSearchArchiveToo(1);
$newObj->setConditionGroups( getTestObjectId(), getTestObjectId() );
$newObj->setUnionQuery( getTestObjectId() );
$newObj->setClassName('O2::Obj::Object');
$newObj->setSkip(1);
$newObj->setOrderBy('metaStatus');

foreach my $localeCode (@localeCodes) {
  $newObj->setCurrentLocale($localeCode);
  $newObj->setTitle("Test-varchar ($localeCode)");
}
$newObj->save();

ok($newObj->getId() > 0, 'Object saved ok');

my $dbObj = $context->getObjectById( $newObj->getId() );
ok($dbObj, 'getObjectById returned something') or BAIL_OUT("Couldn't get object from database");

is( $dbObj->getMetaClassName(), $newObj->getMetaClassName(), 'metaClassName retrieved ok.' );
is( $dbObj->getMetaStatus(), $newObj->getMetaStatus(), 'metaStatus retrieved ok.' );
is( $dbObj->getMetaParentId(), $newObj->getMetaParentId(), 'metaParentId retrieved ok.' );
is_deeply( [ $dbObj->getKeywordIds() ], [ $newObj->getKeywordIds() ], 'keywordIds retrieved ok.' );
is( $dbObj->getMetaCreateTime(), $newObj->getMetaCreateTime(), 'metaCreateTime retrieved ok.' );
is( $dbObj->getId(), $newObj->getId(), 'id retrieved ok.' );
is( $dbObj->getMetaChangeTime(), $newObj->getMetaChangeTime(), 'metaChangeTime retrieved ok.' );
is( $dbObj->getMetaOwnerId(), $newObj->getMetaOwnerId(), 'metaOwnerId retrieved ok.' );
is( $dbObj->getMetaName(), $newObj->getMetaName(), 'metaName retrieved ok.' );
is( $dbObj->getInFolderConditionId(), $newObj->getInFolderConditionId(), 'inFolderCondition retrieved ok.' );
is( $dbObj->getJoinWith(), $newObj->getJoinWith(), 'joinWith retrieved ok.' );
is( $dbObj->getDebug(), $newObj->getDebug(), 'debug retrieved ok.' );
is( $dbObj->getLimit(), $newObj->getLimit(), 'limit retrieved ok.' );
is( $dbObj->getSearchArchiveToo(), $newObj->getSearchArchiveToo(), 'searchArchiveToo retrieved ok.' );
is_deeply( [ $dbObj->getConditionGroupIds() ], [ $newObj->getConditionGroupIds() ], 'conditionGroups retrieved ok.' );
is( $dbObj->getUnionQueryId(), $newObj->getUnionQueryId(), 'unionQuery retrieved ok.' );
is( $dbObj->getClassName(), $newObj->getClassName(), 'className retrieved ok.' );
is( $dbObj->getSkip(), $newObj->getSkip(), 'skip retrieved ok.' );
is( $dbObj->getOrderBy(), $newObj->getOrderBy(), 'orderBy retrieved ok.' );
foreach my $localeCode (@localeCodes) {
  $newObj->setCurrentLocale($localeCode);
  $dbObj->setCurrentLocale($localeCode);
  is( $dbObj->getTitle(), $newObj->getTitle(), 'title retrieved ok.' );
}

# See if a simple object search works
my @searchResults = $mgr->objectSearch( objectId => $newObj->getId() );
is($searchResults[0]->getId(), $newObj->getId(), 'Search for objectId ok');

END {
  $newObj->deletePermanently() if $newObj;
  deleteTestObjects();
}
