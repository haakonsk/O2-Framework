use strict;

use Test::More qw(no_plan);
use O2 qw($db);

ok( $db->getDbh()->ping(), '$dbi->ping()' );
ok( $db->sql('select count(*) from O2_OBJ_OBJECT') > 0 ,'O2_OBJ_OBJECT contains rows' );
