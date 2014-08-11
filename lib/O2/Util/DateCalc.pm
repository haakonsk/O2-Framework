package O2::Util::DateCalc;

# Provides various date calculations.
# Right now it just operates as a proxy/API to the great Date::Calc modul.
# But by outlining a O2::Util::DateCalc API for the rest of the O2
# system, we won't be that vulnerable to changes in Date::Calc or if we want to
# implement a different Date::Calc module.
# Of course the best thing would be to implement all the date calcs ourself since 
# Date::Calc is quite big. 
# But that would requiree some time and research in various calendars etc.
#
# BTW: This modul will also support O2::Lang::Locale and O2::Util::DateFormat. Meaning
# that you should not need to think about formatting and stuff :-)
#
# BTW2: The API will remain similar to Date::Calc, except that we are adapting
# java case syntax in O2. So e.g. methos in Date::Calc will be renamed like this:
#  - Day_of_Year -> dayOfYear
#  - Date_to_Days -> dateToDays
#  - Day_of_Week -> dayOfWeek
#  - Week_Number -> weekNumber
# reference:   http://search.cpan.org/dist/Date-Calc/Calc.pod
# TODO     :   An O2 TagLib should be provided for this, perhaps with JS methods as well?!?
# Status   :   Hehe, lots of work left on this one ;-/

use strict;

use O2 qw($context);

our $_ONEDAY = 86400;

#-----------------------------------------------------------------------------------------
sub new {
  my ($pkg, %params) = @_;
  return bless {}, $pkg;
}
#-----------------------------------------------------------------------------------------
sub localTime {
  my ($obj, $epoch) = @_;
  $epoch ||= time;
  my @keys = qw(second minute hour day month year weekday yearday isdst);
  my @d = localtime $epoch;
  my %date = map { $_ => shift @d } @keys;
  $date{year}  += 1900;
  $date{month} += 1;
  return %date;
}
#-----------------------------------------------------------------------------------------
sub countDaysInPeriod {
  my ($obj, $startTime, $endTime) = @_;
  my $diff = $endTime - $startTime;
  return int($diff/$_ONEDAY)+1;
}
#-----------------------------------------------------------------------------------------
sub countDaysInMonth {
  my ($obj, $epoch) = @_;
  my %d = $obj->localTime($epoch);
  require Date::Calc;
  return Date::Calc::Days_in_Month( $d{year}, $d{month} );
}
#-----------------------------------------------------------------------------------------
sub getLastDayInMonth {
  my ($obj, $epoch) = @_;
  return $obj->setDate($epoch, 0, 0, 31, 0, 0, 0, 0);
}
#-----------------------------------------------------------------------------------------
# Add year, month, day to an epoch.
sub addDelta {
  my ($obj, $epoch, $dYear, $dMonth, $dDay) = @_;
  require Date::Calc;
  my %d = $obj->localTime($epoch);
  my @d = Date::Calc::Add_Delta_YMDHMS(
    $d{year}, $d{month}, $d{day}, $d{hour}, $d{minute}, $d{second},
    $dYear,   $dMonth,   $dDay,   0,        0,          0
  );
  return $obj->toEpoch(@d);
}
#-----------------------------------------------------------------------------------------
sub addDeltaDays {
  my ($obj, $epoch, $numDays) = @_;
  return $obj->addDelta($epoch, 0, 0, $numDays);
}
#-----------------------------------------------------------------------------------------
sub addDeltaMonths {
  my ($obj, $epoch, $dMonth) = @_;
  return $obj->addDelta($epoch, 0, $dMonth, 0);
}
#-----------------------------------------------------------------------------------------
sub addDeltaYears {
  my ($obj, $epoch, $dYear) = @_;
  return $obj->addDelta($epoch, $dYear, 0, 0);
}
#-----------------------------------------------------------------------------------------
# test if a epoch is within to epochs (logical forms a period).
sub epochWithinEpochs {
  my ($obj, $testDate, $startDate, $endDate) = @_;
  return $startDate <= $testDate && $testDate <= $endDate ? 1 : 0;
}
#-----------------------------------------------------------------------------------------
sub dateTime2Epoch {
  my ($obj, $dateTime) = @_;
  use HTTP::Date qw(str2time);
  return str2time($dateTime);
}
#-----------------------------------------------------------------------------------------
sub epoch2DateTime {
  my ($obj, $epoch) = @_;
  my ($d, $m, $y) = (localtime($epoch))[3,4,5];
  return sprintf '%04d%02d%02d', $y+1900, $m+1, $d;
}
#-----------------------------------------------------------------------------------------
sub toEpoch {
  my ($obj, $year, $month, $day, $hour, $minute, $second) = @_;
  $hour   ||= 0;
  $minute ||= 0;
  $second ||= 0;
  require Time::Local;
  return Time::Local::timelocal($second, $minute, $hour, $day, $month-1, $year);
}
#-----------------------------------------------------------------------------------------
# remove all refs clock time (set to 00:00:00)
sub normalizeEpoch {
  my ($obj, $epoch) = @_; 
  my %d = $obj->localTime($epoch);
  return $obj->toEpoch( $d{year}, $d{month}, $d{day}, 0, 0, 0 );
}
#-----------------------------------------------------------------------------------------
#-----------------------------------------------------------------------------------------
# Set methods for epoch
# e.g. Want to have current time and set month to january
# my $time = $dateCalc->setMonth(time, 1);
# # 
#-----------------------------------------------------------------------------------------
sub setDate {
  my ($obj, $epoch, $year, $month, $day, $hour, $minute, $second) = @_;

  my %d = $obj->localTime($epoch);

  $d{year}  = $year  if $year;
  $d{month} = $month if $month;

  $day = $obj->countDaysInMonth($epoch) if $day > $obj->countDaysInMonth($epoch);
  $d{day}     = $day    if $day;
  $d{hour}    = $hour   if $hour;
  $d{minute}  = $minute if $minute;
  $d{seconds} = $second if $second;

  return $obj->toEpoch( $d{year}, $d{month}, $d{day}, $d{hour}, $d{minute}, $d{second} );  
}
#-----------------------------------------------------------------------------------------
sub setDay {
  my ($obj, $epoch, $day) = @_;
  return $obj->setDate($epoch, 0, 0, $day, 0, 0, 0);
}
#-----------------------------------------------------------------------------------------
sub setMonth {
  my ($obj, $epoch, $month) = @_;
  return $obj->setDate($epoch, 0, $month, 0, 0, 0, 0);
}
#-----------------------------------------------------------------------------------------
sub setYear {
  my ($obj, $epoch, $year) = @_;
  return $obj->setDate($epoch, $year, 0, 0, 0, 0, 0);
}
#-----------------------------------------------------------------------------------------
sub setHour {
  my ($obj, $epoch, $hour) = @_;
  return $obj->setDate($epoch, 0, 0, 0, $hour, 0, 0);
}
#-----------------------------------------------------------------------------------------
sub setMinute {
  my ($obj, $epoch, $minute) = @_;
  return $obj->setDate($epoch, 0, 0, 0, 0, $minute, 0);
}
#-----------------------------------------------------------------------------------------
sub setSecond {
  my ($obj, $epoch, $second) = @_;
  return $obj->setDate($epoch, 0, 0, 0, 0, 0, $second);
}
#-----------------------------------------------------------------------------------------
# misc periode calcs
#-----------------------------------------------------------------------------------------
sub getPeriodRange {
  my ($obj, @dates) = @_;
  return ( $obj->getSmallestDateInPeriod(@dates), $obj->getLargestDateInPeriod(@dates) );
}
#-----------------------------------------------------------------------------------------
sub getSmallestDateInPeriod {
  my ($obj, @dates) = @_;
  my $smallest = shift @dates;
  foreach my $date (@dates) {
    if($date < $smallest) {
      $smallest = $date;
    }
  }
  return $smallest;
}
#-----------------------------------------------------------------------------------------
sub getLargestDateInPeriod {
  my ($obj, @dates) = @_;
  my $largest = shift @dates;
  foreach my $date (@dates) {
    if($date > $largest) {
      $largest = $date;
    }
  }
  return $largest;
}
#-----------------------------------------------------------------------------------------
# Misc week methods
#-----------------------------------------------------------------------------------------
sub getWeekNumber {
  my ($obj, $date) = @_;
  $date = $context->getSingleton('O2::Mgr::DateTimeManager')->newObject($date);
  require Date::Calc;
  my ($week, $year) = Date::Calc::Week_of_Year( $date->getYear(), $date->getMonth(), $date->getDayOfMonth() );
  return wantarray ? ($week, $year) : $week;
}
#-----------------------------------------------------------------------------------------
sub getWeekDay {
  my ($obj,$epoch)=@_;
  
}
#-----------------------------------------------------------------------------------------
# Returns the monday's epoch
sub getMondayOfWeek {
  my ($obj, $epochOrWeekNumber, $year) = @_;
  my $week = 0;
  if (length ($epochOrWeekNumber) > 2  && !$year) { # epoch
    ($week, $year) = $obj->getWeekNumber($epochOrWeekNumber);
  }
  $week ||= $epochOrWeekNumber;
  require Date::Calc;
  my ($month, $day);
  ($year, $month, $day) = Date::Calc::Monday_of_Week($week, $year);
  return Date::Calc::Date_to_Time($year, $month, $day, 0, 0, 0);
}
#-----------------------------------------------------------------------------------------
# Returns the sunday's epoch
sub getSundayOfWeek {
  my ($obj, $epochOrWeekNumber, $year) = @_;
  return $obj->addDeltaDays( $obj->getMondayOfWeek($epochOrWeekNumber, $year), 6 );
}
#-----------------------------------------------------------------------------------------
# return the epoch for the first day (monday) of the epoch week it resides within and last day (sunday)
sub getWeekRangeInEpoch {
  my ($obj, $epochOrWeekNumber, $year) = @_;
  return ( $obj->getMondayOfWeek($epochOrWeekNumber, $year), $obj->getSundayOfWeek($epochOrWeekNumber, $year) );
}
#-----------------------------------------------------------------------------------------
# Misc period methods
#-----------------------------------------------------------------------------------------
sub getNextPeriod {
  my ($obj, @dates) = @_;
}
#-----------------------------------------------------------------------------------------
sub getPreviousPeriod {
  my ($obj, @dates) = @_;
  my ($first, $last) = $obj->getPeriodRange(@dates);
  my $totalDays = $obj->countDaysInPeriod($first, $last);
  my $newLast   = $obj->addDeltaDays( $first, -1            );
  my $newFirst  = $obj->addDeltaDays( $first, -1*$totalDays );
  return ($newFirst, $newLast);
}
#-----------------------------------------------------------------------------------------
# coubt total weeks in within total days given (not abs correct, cause it is round up)
# e.g. 31 would yield 4 weeks
# e.g. 1 days = 1 week
# e.g. 8 days = 2 week
# 365 = 53 weeks (note some times this is an estimat)
sub getTotalWeeksWithinNumberOfDays {
  my ($obj, $totalDays) = @_;
  my $totalWeeks = $totalDays/7;
  require O2::Util::Math;
  return  O2::Util::Math::ceil(undef, $totalWeeks);
}
#-----------------------------------------------------------------------------------------
# return all monthPeriods in this period
# e.g. getMonthRangesInPeriod(20080201,20080407)
# returns 
# [
#  {
#   start => in epoch,
#   end   => in epoch,
#  },
#  {
#   start => 20080301,
#   end   => 20080331,
#  },
#  {
#   start => 20080401,
#   end   => 20080407,
#  },
# ]
sub getMonthRangesInPeriod {
  my ($obj, $startEpoch, $endEpoch) = @_;
  my $currentEpoch = $startEpoch;
  my @periods;

  my $safe = 0;
  while ($currentEpoch <= $endEpoch && $safe++ < 100_000) {
    my ($start, $end) = ( $currentEpoch, $obj->getLastDayInMonth($currentEpoch) );
    $end = $endEpoch if $end >= $endEpoch;
    push @periods, {
      start => $start,
      end   => $end,
    };
    $currentEpoch = $obj->addDeltaDays($end, 1);
  }

  return wantarray ? @periods : \@periods;
}
#-----------------------------------------------------------------------------------------
# returns epoch for monday at 00:00:00
sub epochToMonday {
  my ($obj, $epoch) = @_;

  # subtract current weekday, and we will end up on monday
  my ($sec, $min, $hour, $mday, $mon, $year, $wday, $yday, $isdst) = localtime $epoch;
  $wday = 7 if $wday == 0;
  return $obj->addDeltaDays( $obj->toEpoch($year+1900, $mon+1, $mday), -($wday-1) );
}
#-----------------------------------------------------------------------------------------
# returns (startEpoch,endEpoch) for a named period range (i.e. 'yesterday' or 'lastWeek')
# "this" prefix refers to "the one we are in now" / "current"
# "last" prefix refers to "the one before _this_". Except for "last..days", where current day is part of range.
sub getRangeByName {
  my ($obj, $rangeName, $basedOnTime) = @_;

  require Date::Calc;
  $basedOnTime ||= time;
  my ($year, $month, $day, $hour, $min, $sec) = Date::Calc::Time_to_Date($basedOnTime);

  if ( $rangeName =~ m/last(\d+)Days/ ) {
    return ( $obj->addDeltaDays($basedOnTime, -$1), $basedOnTime );
  }
  elsif ($rangeName eq 'today') {
    my $midnight       = $obj->toEpoch($year, $month, $day);
    my $beforeMidnight = $obj->normalizeEpoch( $obj->addDeltaDays($basedOnTime, 1) ) - 1;
    return ($midnight, $beforeMidnight);
  }
  elsif ($rangeName eq 'yesterday') {
    my $yesterday      = $obj->normalizeEpoch( $obj->addDeltaDays($basedOnTime, -1) );
    my $beforeMidnight = $obj->toEpoch($year, $month, $day) - 1;
    return ($yesterday, $beforeMidnight);
  }
  elsif ($rangeName eq 'lastWeek') {
    my $thisMonday     = $obj->epochToMonday($basedOnTime);
    my $previousMonday = $obj->addDeltaDays($thisMonday, -7);
    return ($previousMonday, $thisMonday-1);
  }
  elsif($rangeName eq 'thisWeek') {
    my $thisMonday = $obj->epochToMonday($basedOnTime);
    my $nextMonday = $obj->addDeltaDays($thisMonday, 7);
    return ($thisMonday, $nextMonday-1);
  }
  elsif ($rangeName eq 'lastMonth') {
    my ($year, $month, $day) = Date::Calc::Add_Delta_YM($year, $month, 1, 0, -1); # first of last month
    my $firstOfMonth = $obj->toEpoch($year, $month, $day);
    my $lastOfMonth  = $obj->addDeltaMonths($firstOfMonth, 1) - 1;
    return ($firstOfMonth, $lastOfMonth);
  }
  elsif ($rangeName eq 'thisMonth') {
    my $firstOfMonth = $obj->toEpoch($year, $month, 1, 0, 0, 0);
    my $lastOfMonth  = $obj->addDeltaMonths($firstOfMonth, 1) - 1;
    return ($firstOfMonth, $lastOfMonth);
  }
  elsif ($rangeName eq 'thisYear') {
    my $startOfYear = $obj->toEpoch($year, 1, 1, 0, 0, 0);
    my $endOfYear   = $obj->addDeltaYears($startOfYear, 1) - 1;
    return ($startOfYear, $endOfYear);
  }
  elsif ($rangeName eq 'lastYear') {
    my $startOfYear = $obj->toEpoch($year-1, 1, 1, 0, 0, 0); # January first, last year
    my $endOfYear   = $obj->addDeltaYears($startOfYear, 1) - 1;
    return ($startOfYear, $endOfYear);
  }
  else {
    die "Unknown range name: '$rangeName'";
  }
}
#-----------------------------------------------------------------------------------------
1;
