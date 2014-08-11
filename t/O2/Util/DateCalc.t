use strict;

use Test::More qw(no_plan);
use O2 qw($context);
use O2::Script::Test::Common;

use_ok 'O2::Util::DateCalc';
my $dateCalc = O2::Util::DateCalc->new( $context->getLocale() );

my $time = 1205854784; # All tests are based on fixed time Tue Mar 18 16:39:44 2008. (Else we would risk errors when calculating dates).
my %rangeNameTests = (
  today      => [ 1205794800, 1205881199 ],
  yesterday  => [ 1205708400, 1205794799 ],
  lastWeek   => [ 1205103600, 1205708399 ],
  thisWeek   => [ 1205708400, 1206313199 ],
  last7Days  => [ 1205249984, $time      ],
  last30Days => [ 1203262784, $time      ],
  lastMonth  => [ 1201820400, 1204325999 ],
  thisMonth  => [ 1204326000, 1207000799 ],
  thisYear   => [ 1199142000, 1230764399 ],
  lastYear   => [ 1167606000, 1199141999 ],
);

foreach my $rangeName (sort keys %rangeNameTests) {
  my ($start, $end) = $dateCalc->getRangeByName($rangeName, $time);
  diag("$rangeName is " . localtime ($start) . ' - ' . scalar localtime $end);
  is_deeply( [$start, $end], $rangeNameTests{$rangeName}, "getRangeByName($rangeName)" );
}

eval {
  $dateCalc->getRangeByName('xxx');
};
ok($@, "getRangeByName('xxx') dies");
