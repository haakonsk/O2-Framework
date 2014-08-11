use strict;

use Test::More qw(no_plan);
use O2 qw($db $config);

my $tableName = 'O2_TEST_TABLE';

$db->do( sprintf "create table $tableName ( field1 varchar(4), field2 int ) engine InnoDB DEFAULT CHARSET=%s DEFAULT COLLATE=%s", $config->get('o2.database.characterSet'), $config->get('o2.database.collation') );

$db->startTransaction();
$db->do("insert into $tableName (field1) values ('abcd')");
is( $db->fetch("select field1 from $tableName where field1 = 'abcd'"), 'abcd', 'insert' );
$db->rollback();
is( $db->fetch("select field1 from $tableName where field1 = 'abcd'"), undef, 'rollback' );

# Test recursive rollback
$db->startTransaction();
$db->do("insert into $tableName (field1, field2) values ('test', 1)");
$db->startTransaction();
$db->do("insert into $tableName (field1, field2) values ('test', 2)");
$db->endTransaction();
$db->do("insert into $tableName (field1, field2) values ('test', 3)");
$db->rollback();
my @field2Values = $db->selectColumn("select field2 from $tableName where field1 = 'test'");
ok(@field2Values == 0, 'Recursive rollback');

$db->startTransaction();
$db->do("insert into $tableName (field1) values ('abcd')");
is( $db->fetch("select field1 from $tableName where field1 = 'abcd'"), 'abcd', 'insert' );
$db->endTransaction();
is( $db->fetch("select field1 from $tableName where field1 = 'abcd'"), 'abcd', 'endTransaction' );

eval {
  $db->do("insert into $tableName (field1, field2) values ('abcdef', 10)");
};
ok( $@,                                                                    "Test died as it should: $@" );
is( $db->fetch("select field1 from $tableName where field2 = 10"), undef, 'Nothing inserted'           );

END {
  $db->do("drop table $tableName") if $db;
}
