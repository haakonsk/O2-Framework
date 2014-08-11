use strict;
use warnings;

# Make sure the database and all database tables have utf-8 as character set and the correct collation

use O2::Util::ScriptEnvironment;
O2::Util::ScriptEnvironment->runOnlyOnce();

use O2 qw($context $db);
use O2::Script::Common;

my $dbIntrospect = $context->getSingleton('O2::DB::Util::Introspect');
my $schemaMgr    = $context->getSingleton('O2::DB::Util::SchemaManager');

$schemaMgr->alterCharacterSetForDatabase( 'utf8'           ) if $dbIntrospect->getCharacterSet() ne 'utf8';
$schemaMgr->alterCollationForDatabase(    'utf8_danish_ci' ) if $dbIntrospect->getCollation()    ne 'utf8_danish_ci';

foreach my $table ($dbIntrospect->getTables()) {
  $schemaMgr->alterCharacterSetForTable( $table->getName(), 'utf8'           ) if $table->getCharacterSet() ne 'utf8';
  $schemaMgr->alterCollationForTable(    $table->getName(), 'utf8_danish_ci' ) if $table->getCollation()    ne 'utf8_danish_ci';
}
