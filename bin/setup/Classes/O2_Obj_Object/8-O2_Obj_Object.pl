use strict;

use O2::Util::ScriptEnvironment;
O2::Util::ScriptEnvironment->runOnlyOnce();

use O2 qw($context);

my $schemaMgr = $context->getSingleton('O2::DB::Util::SchemaManager');
$schemaMgr->dropColumn('O2_OBJ_OBJECT', 'isHidden');
$schemaMgr->dropColumn('O2_OBJ_OBJECT', 'mustInstantiate');
