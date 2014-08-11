use strict;

use Test::More qw(no_plan);
use O2::Script::Test::Common;

use_ok 'O2::Mgr::DateTimeManager';

use O2 qw($context $config);

my @localeCodes = @{ $config->get('o2.locales') };
my $mgr = $context->getSingleton('O2::Mgr::DateTimeManager');

my $newObj = $mgr->newObject();
$newObj->setHours(1);
$newObj->setDayOfMonth(2);
$newObj->setMonth(3);
$newObj->setMinutes(4);
$newObj->setSeconds(5);
$newObj->setNanoSeconds(6);
$newObj->setYear(1933);
$newObj->setMetaStatus("Test-varchar");
$newObj->setMetaParentId(1);
$newObj->setKeywordIds(1, 2);
$newObj->setMetaOwnerId(1);
$newObj->setMetaName("Test-varchar");
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
is( $dbObj->getMonth(), $newObj->getMonth(), 'month retrieved ok.' );
is( $dbObj->getDate(), $newObj->getDate(), 'date retrieved ok.' );
is( $dbObj->getSeconds(), $newObj->getSeconds(), 'seconds retrieved ok.' );
is( $dbObj->getHours(), $newObj->getHours(), 'hours retrieved ok.' );
is( $dbObj->getDayOfMonth(), $newObj->getDayOfMonth(), 'dayOfMonth retrieved ok.' );
is( $dbObj->getMinutes(), $newObj->getMinutes(), 'minutes retrieved ok.' );
is( $dbObj->getNanoSeconds(), $newObj->getNanoSeconds(), 'nanoSeconds retrieved ok.' );
is( $dbObj->getYear(), $newObj->getYear(), 'year retrieved ok.' );

$newObj->setEpoch(time);
is( $newObj->format('yyyyMMdd'), $context->getDateFormatter()->dateFormat(time, 'yyyyMMdd'), 'format method seems to work' );

# See if a simple object search works
my @searchResults = $mgr->objectSearch( objectId => $newObj->getId() );
is($searchResults[0]->getId(), $newObj->getId(), 'Search for objectId ok');

END {
  $newObj->deletePermanently() if $newObj;
  deleteTestObjects();
}
