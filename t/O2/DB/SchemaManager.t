use strict;

use Test::More qw(no_plan);
use O2 qw($context $db);

use_ok 'O2::DB::Util::SchemaManager';
use_ok 'O2::DB::Util::Introspect';

my $tableName = 'SCHEMAMANAGER_TEST_TABLE2';

my $dbIntrospect = $context->getSingleton('O2::DB::Util::Introspect');
my $schemaMgr    = $context->getSingleton('O2::DB::Util::SchemaManager');

if ($dbIntrospect->tableExists('SCHEMAMANAGER_TEST_TABLE')) {
  $schemaMgr->dropTable('SCHEMAMANAGER_TEST_TABLE');
}
if ($dbIntrospect->tableExists($tableName)) {
  $schemaMgr->dropTable($tableName);
}
ok(!$dbIntrospect->tableExists($tableName), "SCHEMAMANAGER_TEST_TABLE does not exist");
ok(!$dbIntrospect->tableExists($tableName), "$tableName does not exist");
$schemaMgr->createTable(
  name    => 'SCHEMAMANAGER_TEST_TABLE',
  columns => [
    {
      name          => 'id',
      type          => 'int',
      nullable      => 0,
      autoIncrement => 1,
      primaryKey    => 1,
    },
  ],
);
ok($dbIntrospect->tableExists('SCHEMAMANAGER_TEST_TABLE'), "SCHEMAMANAGER_TEST_TABLE created");
$schemaMgr->renameTable('SCHEMAMANAGER_TEST_TABLE', $tableName);
ok(!$dbIntrospect->tableExists('SCHEMAMANAGER_TEST_TABLE'), "Table SCHEMAMANAGER_TEST_TABLE doesn't exist anymore");
my $table = O2::DB::Util::Introspect::Table->new(
  context   => $context,
  tableName => $tableName,
);

ok(!$table->hasColumn('secondColumn'), 'secondColumn does not exist');
$schemaMgr->addColumn(
  tableName  => $tableName,
  columnName => 'secondColumn',
  type       => 'int',
  nullable   => 1,
);
ok($table->hasColumn('secondColumn'), "secondColumn created");
$schemaMgr->renameColumn($tableName, 'secondColumn', 'secondColumn2');
ok( $table->hasColumn('secondColumn2'), "secondColumn renamed to secondColumn2");
ok(!$table->hasColumn('secondColumn'),  "secondColumn doesn't exist now");

$db->startTransaction();
$db->sql("insert into $tableName (secondColumn2) values (12)");
ok($db->getLastInsertedId() == 1, "insert ok, auto_increment works");
$db->endTransaction();

$schemaMgr->alterColumn(
  tableName  => $tableName,
  columnName => 'secondColumn2',
  type       => 'varchar',
  length     => 255,
);
my $column = $table->getColumn('secondColumn2');
ok(lc $column->getDataType() eq 'varchar', "secondColumn2's dataType is varchar");

$db->startTransaction();
$db->sql("insert into $tableName (secondColumn2) values (?)", 'Håkon');
ok($db->getLastInsertedId() == 2, "insert ok, auto_increment works");
$db->endTransaction();

$schemaMgr->renameColumn($tableName, 'id', 'id2');
ok( $table->hasColumn('id2'), "id column renamed to id2");
ok(!$table->hasColumn('id'),  "id doesn't exist anymore");
$db->sql("insert into $tableName (secondColumn2) values (12)");

$db->startTransaction();
ok($db->getLastInsertedId() == 3, "insert ok, auto_increment works");
$schemaMgr->dropColumn($tableName, 'secondColumn2');
$db->endTransaction();

ok(!$table->hasColumn('secondColumn2'), "secondColumn2 dropped");

$schemaMgr->dropTable($tableName);
ok(!$dbIntrospect->tableExists($tableName), "$tableName dropped");



# Let's see if updateTableFromSql works:
ok(!$dbIntrospect->tableExists('myTestTable'), "myTestTable doesn't exist");
my $sql = <<END;
create table myTestTable (
  col1 int(10),
  col2 char(2),
  col3 text,
  primary key(col1, col2)
)
END
$db->sql($sql);
ok($dbIntrospect->tableExists('myTestTable'), "myTestTable exists");

# Changing size of col1:
$sql = <<END;
create table myTestTable (
  col1 int(11),
  col2 char(2),
  col3 text,
  primary key(col1, col2)
)
END

eval {
  $schemaMgr->updateTableFromSql($sql);
};
ok(0, "updateTableFromSql died: $@")       if $@;
ok(1, "updateTableFromSql didn't die") unless $@;
ok($dbIntrospect->getTable('myTestTable')->getColumn('col1')->getSize() == 11, 'Changed size of col1 from 10 to 11');
$db->sql("drop table myTestTable");
ok(!$dbIntrospect->tableExists('myTestTable'), "myTestTable dropped");



# Testing createTable and addColumn, adding a primary key column to a table that already has a primary key:
$schemaMgr->createTable(
  name    => 'myTestTable',
  columns => [
    {
      name          => 'col1',
      type          => 'int',
      nullable      => 0,
      primaryKey    => 1,
    },
    {
      name     => 'col2',
      type     => 'varchar',
      length   => '255',
      nullable => 0,
    },
    {
      name     => 'col3',
      type     => 'int',
      nullable => 0,
    },
  ],
);

$schemaMgr->addColumn(
  tableName  => 'myTestTable',
  columnName => 'col4',
  type       => 'int',
  primaryKey => 1,
);

my $table = $dbIntrospect->getTable('myTestTable');
my $col1 = $table->getColumn('col1');
my $col2 = $table->getColumn('col2');
my $col3 = $table->getColumn('col3');
my $col4 = $table->getColumn('col4');
ok($col1->isPrimaryKey() && !$col2->isPrimaryKey() && !$col3->isPrimaryKey() && $col4->isPrimaryKey(), "col1 and col4 are primary keys");


# Testing renameColumn:
$schemaMgr->renameColumn('myTestTable', 'col1', 'col1Renamed');
ok(!$table->hasColumn('col1') && $table->hasColumn('col1Renamed'), 'Renamed col1 to col1Renamed');

$db->sql("drop table myTestTable"); # Cleaning up
