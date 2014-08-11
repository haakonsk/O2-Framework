use Test::More qw(no_plan);

use O2 qw($context);

my $period = $context->getSingleton('O2::Mgr::DatePeriodManager')->newObject();

$period->setFromDate('20040227');
$period->setToDate('20040328');
my $checkDate = '20040229';
my $hadDate = 0;
foreach my $date ($period->getDates()) {
  $hadDate = 1 if $checkDate == $date;
}

ok($hadDate, 'Testing for leapyear');
