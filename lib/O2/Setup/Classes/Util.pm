package O2::Setup::Classes::Util;

use strict;

use O2 qw($context $db);

#-----------------------------------------------------------------------------
sub new {
  my ($pkg, %init) = @_;
  return bless {}, $pkg;
}
#-----------------------------------------------------------------------------
sub updateDbForClassAndSubClasses {
  my ($obj, $className) = @_;
  print "updateDbForClassAndSubClasses: $className:\n";

  my $tableName = uc $className;
  $tableName    =~ s{ :: }{_}xmsg;

  my $dbIntrospect = $context->getSingleton('O2::DB::Util::Introspect');
  if (!$dbIntrospect->tableExists($tableName)) {
    my $schemaMgr = $context->getSingleton('O2::DB::Util::SchemaManager');
    $schemaMgr->createTableForClass($className);
  }

  my @objectIds = $db->selectColumn("select objectId from O2_OBJ_OBJECT where className = ?", $className);
  printf  " inserting up to %d rows into $tableName.\n", scalar @objectIds;
  foreach my $objectId (@objectIds) {
    if (!$db->fetch("select objectId from $tableName where objectId = ?", $objectId)) {
      $db->do("insert into $tableName (objectId) values (?)", $objectId);
    }
  }

  $obj->updateDbForSubClasses($className);
}
#-----------------------------------------------------------------------------
sub updateDbForSubClasses {
  my ($obj, $className, @parents) = @_;
  print "updateDbForSubClasses: $className:\n";
  my $tableName = uc $className;
  $tableName    =~ s{ :: }{_}xmsg;

  push @parents, {
    className => $className,
    tableName => $tableName,
  };

  my $dbIntrospect = $context->getSingleton('O2::DB::Util::Introspect');
  if (!$dbIntrospect->tableExists($tableName)) {
    my $schemaMgr = $context->getSingleton('O2::DB::Util::SchemaManager');
    $schemaMgr->createTableForClass($className);
  }

  my $introspector = $context->getSingleton('O2::Util::ObjectIntrospect');
  $introspector->setClass($className);
  my @subClasses = $introspector->getSubClasses();

  foreach my $subClassName (@subClasses) {

    my @objectIds = $db->selectColumn("select objectId from O2_OBJ_OBJECT where className = ?", $subClassName);
    print " inserting into " . join ', ', map { $_->{tableName} } @parents;
    printf ". Up to %d rows to insert.\n" . scalar @objectIds;
    foreach my $parent (@parents) {
      foreach my $objectId (@objectIds) {
        if (!$db->fetch("select objectId from $parent->{tableName} where objectId = ?", $objectId)) {
          $db->do("insert into $parent->{tableName} (objectId) values (?)", $objectId);
        }
      }
    }

    $obj->updateDbForClassAndSubClasses($subClassName, @parents);
  }
}
#-----------------------------------------------------------------------------
1;
