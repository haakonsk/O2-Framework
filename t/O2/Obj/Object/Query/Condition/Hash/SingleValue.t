# This file was originally auto-generated by O2 with contents hashing to ac5244b5a0c75f1b79e57d3cd81a4fd6
use strict;

use Test::More qw(no_plan);
use O2::Script::Test::Common;

use_ok 'O2::Mgr::Object::Query::Condition::Hash::SingleValueManager';

use O2 qw($context $config);

my @localeCodes = @{ $config->get('o2.locales') };
my $mgr = $context->getSingleton('O2::Mgr::Object::Query::Condition::Hash::SingleValueManager');

my $newObj = $mgr->newObject();
$newObj->setMetaName('Test-script for O2::Obj::Object::Query::Condition::Hash::SingleValue/O2::Mgr::Object::Query::Condition::Hash::SingleValueManager');
$newObj->setMetaStatus("Test-varchar");
$newObj->setMetaParentId( getTestObjectId() );
$newObj->setKeywordIds( getTestObjectId(), getTestObjectId() );
$newObj->setMetaOwnerId( getTestObjectId() );
$newObj->setMetaName("Test-varchar");
$newObj->setOperator("Test-varchar");
$newObj->setTableName("Test-varchar");
$newObj->setFieldName("Test-varchar");
$newObj->setListType('none');
$newObj->setHashKey("Test-varchar");
$newObj->setForceNumeric(1);
$newObj->setValue("Test-varchar");
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
is( $dbObj->getOperator(), $newObj->getOperator(), 'operator retrieved ok.' );
is( $dbObj->getTableName(), $newObj->getTableName(), 'tableName retrieved ok.' );
is( $dbObj->getFieldName(), $newObj->getFieldName(), 'fieldName retrieved ok.' );
is( $dbObj->getListType(), $newObj->getListType(), 'listType retrieved ok.' );
is( $dbObj->getHashKey(), $newObj->getHashKey(), 'hashKey retrieved ok.' );
is( $dbObj->getForceNumeric(), $newObj->getForceNumeric(), 'forceNumeric retrieved ok.' );
is( $dbObj->getValue(), $newObj->getValue(), 'value retrieved ok.' );

# See if a simple object search works
my @searchResults = $mgr->objectSearch( objectId => $newObj->getId() );
is($searchResults[0]->getId(), $newObj->getId(), 'Search for objectId ok');

END {
  $newObj->deletePermanently() if $newObj;
  deleteTestObjects();
}
