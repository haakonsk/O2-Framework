use strict;
use warnings;

use Test::More qw(no_plan);
use O2 qw($context $db);
use O2::Script::Test::Common;
use Time::HiRes qw(time);
use O2::Util::SetApacheEnv;

use O2::Data;
my $d = O2::Data->new();

$| = 1;
my $cacheHandler = $context->getMemcached();
if (!$cacheHandler->canCacheObject()) {
  $cacheHandler->enableObjectCache();
  $cacheHandler = $context->reloadCacheHandler();
}
if ($cacheHandler->isa('O2::Cache::Dummy')) {
  diag "Couldn't turn caching on";
  exit;
}
#$db->enableDebug();
#$db->disableDBCache();

my $doTest;
if ($ARGV{-test}) {
  %{$doTest} = map { ($_-1) => $_ } split /,/, $ARGV{-test};
}

my @tests = (
  \&testObjectsInDB,
);

if ($ARGV{-objectId}) {
  testObject( $ARGV{-objectId} );
  exit;
}
for (my $i = 0; $i < @tests; $i++) {
  $tests[$i]->() if !$doTest || exists $doTest->{$i};
}

sub testObjectsInDB {
  diag "Using cachehandler: ".ref $cacheHandler;
  my @classNames = $db->fetchAll('select distinct(className) from O2_OBJ_OBJECT');

  foreach my $class (@classNames) {
    my $className = $class->{className};
    next if $ARGV{-classname} && $className ne $ARGV{-classname};
    next if $className eq 'O2::Obj::Class';
    diag '-' x 78;
    diag "testing $className\n";
    my $objectId = $db->fetch("select max(objectId) from O2_OBJ_OBJECT where status not in ('deleted', 'trashed') and classname like ?", $className);
    if (!$objectId) {
      diag "Could not find any active instances of $className\n";
    }
    else {
      testObject($objectId);
    }
  }
}

sub testObject {
  my ($objectId) = @_;

  diag '-' x 78, "\n";
  diag "Testing object with id: $objectId";
  $cacheHandler->deleteObjectById($objectId);
  my $object;
  eval {
    my $startTime = time;
    $object = $context->getObjectById($objectId);
    diag "NO CACHE done - used:".sprintf('%.4f',(time-$startTime))."s";
  };
  my $errorMsg = $@;
  if (!ref $object || $errorMsg) {
    if ($errorMsg !~ m{Couldn't instantiate object with id $objectId: Error getting manager by objectId}ms) {
      diag "Could not load a object,tried objectId: $objectId, reason: $@\n";
      ok(0, "Couldn't cache object: $objectId, reason: $@");
    }
    return;
  }
  return unless $object->isCachable();

  my $className = ref $object;
  
  # add to cache
  if ($cacheHandler->setObject($object)) {
    diag "added $className to cache";
    diag "get the object from cache";
    my $startTime = time;
    my $cachedObject = $cacheHandler->getObjectById($objectId);
    diag "CACHE done - used:" . sprintf ( '%.4f', (time-$startTime) ) . "s";
    
    diag '-' x 50, "\n";
    diag "No cached dump:\n";
    diag $d->dump($object->getObjectPlds);
    diag '-' x 50, "\n";
    diag "Cached dump:\n";
    diag $d->dump($cachedObject->getObjectPlds);

    is_deeply( $cachedObject->getObjectPlds(),  $object->getObjectPlds(),  $object->getMetaClassName . "[" . $object->getId() . "] tested cached object against objectPlds"  );
    is_deeply( $cachedObject->getContentPlds(), $object->getContentPlds(), $object->getMetaClassName . "[" . $object->getId() . "] tested cached object against contentPlds" );
    is_deeply( $object,                         $object,                   "real object against itself"                                                                      );
  }
  else {
    ok( 0, sprintf "Object %d (%s) could not be cached", $object->getId(), $object->getMetaClassName() );
  }
}
