use Test::More qw(no_plan);

use_ok 'O2::Util::CronTime';

my %timings = (
  '1 * * * *'   => 1083729660,
  '10 * * * *'  => 1083726600,
  '* 1 * * *'   => 1083798000,
  '* 10 * * *'  => 1083744000,
  '* * 1 * *'   => 1086040800,
  '* * 10 * *'  => 1084140000,
  '* * * 1 *'   => 1104534000,
  '* * * 10 *'  => 1096581600,
  '* * * * 1'   => 1084140000,
  '* * * * 7'   => 1084053600,
  '1 1 * * *'   => 1083798060,
  '1 10 * * *'  => 1083744060,
  '10 1 * * *'  => 1083798600,
  '10 10 * * *' => 1083744600,
  '1 1 1 1 1'   => 1167609660,
);

my $testedConstruct;
foreach my $timing (keys %timings) {
  my $cronTime = O2::Util::CronTime->new($timing);
  isa_ok($cronTime, 'O2::Util::CronTime') unless $testedConstruct++;
  # Set date to 05:05:00 05/05/2004
  ok( $cronTime->nextRun(1083726300) == $timings{$timing}, "Calculating '$timing'" );
}

$cronTime = O2::Util::CronTime->new('* * 31 * *');
ok( $cronTime->nextRun(1075676400) == 1080684000, "Respected leapyear" ); # Set date to 00:00:00 02/02/2004

$cronTime = O2::Util::CronTime->new('* * 31 4,5 *');
ok( $cronTime->nextRun(1075676400) == 1085954400, "Respected reached end of month" ); # Set date to 00:00:00 02/02/2004

# Test for illegal dates
my @illegal = (
  '60 * * * *',
  '-1 * * * *',
  '* 24 * * *',
  '* -1 * * *',
  '* * 32 * *',
  '* * 0 * *',
  '* * * 13 *',
  '* * * 0 *',
  '* * * * 8',
  '* * * * -1',
  '* * 30 2 *',
  '* * 31 4,6,9,11 *',
  '',
);

foreach my $illegal (@illegal) {
  eval {
    my $illegalCronTime = O2::Util::CronTime->new($illegal);
  };
  ok( $@, "Should not construct from string '$illegal'" );
}

my $cronTime = O2::Util::CronTime->new( '* * * * *' );
foreach my $testMethod (qw/getMinuteString getHourString getDOMString getMonthString getDOWString/) {
  my $setMethod = $testMethod;
  $setMethod    =~ s/^get/set/;
  $cronTime->$setMethod( $cronTime->$testMethod() );
  ok( $cronTime->$testMethod() eq '*', $testMethod );
}

my %minuteTests = (
  '* * * * *'             => {
    name   => 'Any time',
    values => [0..59],
  },
  '0-10 * * * *'          => {
    name   => 'First 10 minutes of all hours',
    values => [0..10],
  },
  '*/10 * * * *'          => {
    name   => 'Each 10 minutes',
    values => [0,10,20,30,40,50],
  },
  '0-10/2 * * * *'        => {
    name => 'Every second minutes the First 10 minutes of all hours',
    values => [0,2,4,6,8,10],
  },
  '0,1,2,3,4-8/2 * * * *' => {
    name => 'First 4 minutes, then every other minutes between 4 and 8',
    values => [0,1,2,3,4,6,8],
  },
  '1 2 3 4 5'             => {
    name => 'Run 1 minute past 02:00 the 3rd of april when the weekday is friday',
    values => [1],
  },
);

foreach my $cronTimeTest (keys %minuteTests) {
  my $cronTime = O2::Util::CronTime->new($cronTimeTest);
  my $didMatch = 1;
  my @minutes = $cronTime->expandMinutes();
  if (@minutes) {
    foreach my $i (0 .. @minutes) {
      $didMatch = 0 if $minutes[$i] != $minuteTests{$cronTimeTest}->{values}->[$i];
    }
  }
  else {
    $didMatch = 0;
  }
  ok( $didMatch == 1, $minuteTests{$cronTimeTest}->{name} );
}

