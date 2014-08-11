use strict;

use Test::More qw(no_plan);
use O2 qw($context $config $db);
use O2::Script::Test::Common;

my $maxNumObjectsToTestWithPerClass = 2;

# Run with config.o2.objectCache = 0
if ($config->get('o2.objectCache')) {
  diag("config(o2.objectCache) should be turned off. Aborting.");
  exit;
}

# Find all O2::Obj-files:
my $fileMgr = $context->getSingleton('O2::File');
my @files   = $fileMgr->scanDirRecursive("$ENV{O2ROOT}/lib/O2/Obj", '.pm$');
my @classes;
if ($ARGV{-class}) {
  $ARGV{-class} =~ s{ \A O2::Obj:: }{}xms;
  @classes = ( $ARGV{-class} );
}
else {
  foreach my $file (@files) {
    my $class = $file;
    $class    =~ s{ / }{::}xmsg;
    $class    =~ s{ [.]pm \z }{}xms;
    push @classes, $class;
  }
}

my $cacheMgr       = $context->getSingleton('O2::Util::SimpleCache');
my $pldsSerializer = $context->getSingleton('O2::Util::Serializer', format  => 'PLDS');

foreach my $class (@classes) {
  next if $class eq 'Class';
  
  diag "$class";
  $class = "O2::Obj::$class";
  my @objectIds = $db->selectColumn("select objectId from O2_OBJ_OBJECT where className = ? and status != 'trashed' and status != 'deleted' order by objectId desc limit $maxNumObjectsToTestWithPerClass", $class);
  if (!@objectIds) {
    diag "Couldn't test $class objects. No such objects in database.";
    next;
  }
  my $object;
  eval {
    $object = $context->getObjectById( $objectIds[0] );
  };
  if ($@) {
    fail("getObjectById() died for $class ($objectIds[0]): $@");
    next;
  }
  next unless $object->isCachable();
  
  foreach my $objectId (@objectIds) {
    my $className = $object->getMetaClassName();
    eval {
      $object = $context->getObjectById($objectId);
      my $cacheKey = "cacheTest-$class-$objectId";
      $cacheMgr->set($cacheKey, $object);
      next unless $object->isCachable();
      
      my $serialized = $object->serialize();
      my $compactObject = $pldsSerializer->thaw($serialized);
      my $cachedObject;
      $cachedObject = $cacheMgr->get($cacheKey);
#      $cachedObject->getModel() if $deSerializedObject->can('getModel'); # Making sure $obj->{manager}->{model} exists
      $cachedObject = $cachedObject->getManager()->init($cachedObject);
      $serialized = $cachedObject->serialize();
      $cachedObject = $pldsSerializer->thaw($serialized);
      is_deeply($cachedObject, $compactObject, $class);
    };
    fail("Died testing object with id $objectId which is of type $className: $@") if $@;
  }
}
