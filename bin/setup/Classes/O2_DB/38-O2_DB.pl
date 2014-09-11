use strict;

use O2::Util::ScriptEnvironment;
O2::Util::ScriptEnvironment->runOnlyOnce();

use O2::Script::Common;

use O2 qw($context $db);
my $dbIntrospect = $context->getSingleton('O2::DB::Util::Introspect');

my @dbTableNames = map { $_->getName() } $dbIntrospect->listTables();

foreach my $tableName (@dbTableNames) {
  my $sql = $db->fetch("show create table $tableName");
  $context->useArchiveDbh();
  $db->sql($sql) unless $dbIntrospect->getTable($tableName);
  $context->usePreviousDbh();
}
