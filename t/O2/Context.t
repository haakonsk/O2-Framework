use strict;

use Test::More qw(no_plan);
use O2 qw($context);

# locale
my $localeCode = 'sv_SE';
$context->setLocaleCode($localeCode);
is( $context->getLocaleCode(),          $localeCode, 'getLocaleCode()' );
is( $context->getLocale()->getLocale(), $localeCode, 'getLocale()'     );

# getSingleton
my $dateTimeMgr = $context->getSingleton('O2::Mgr::DateTimeManager');
ok(ref ($dateTimeMgr) eq 'O2::Mgr::DateTimeManager', 'Object is of right type');
my $dateTimeMgr2 = $context->getSingleton('O2::Mgr::DateTimeManager');
ok($dateTimeMgr eq $dateTimeMgr2, 'DateTimeManagers are the same object');
