use Test::More qw(no_plan);

use_ok 'O2::Util::AuthUtil';

my $authUtil = new O2::Util::AuthUtil();
$authUtil->setUserId(100);
ok( $authUtil->getUserId() == 100, 'UserId set OK' );

# XXX Add tests for the rest
