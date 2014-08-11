use strict;
use warnings;

use O2::Util::ScriptEnvironment;
O2::Util::ScriptEnvironment->runOnlyOnce();

use O2 qw($context $db);
use O2::Script::Common;

my $introspector = $context->getSingleton('O2::DB::Util::Introspect');
my $schemaMgr    = $context->getSingleton('O2::DB::Util::SchemaManager');

my $table = $introspector->getTable('O2_CONSOLE_LOG');
if (!$table->hasColumn('line')) {
  $schemaMgr->addColumn(
    tableName  => 'O2_CONSOLE_LOG',
    columnName => 'line',
    type       => 'int',
    length     => 11,
  );
}
if (!$table->hasColumn('processId')) {
  $schemaMgr->addColumn(
    tableName  => 'O2_CONSOLE_LOG',
    columnName => 'processId',
    type       => 'int',
    length     => 11,
  );
}
