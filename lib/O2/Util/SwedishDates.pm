package O2::Util::SwedishDates;

use strict;

use O2 qw($context);

#--------------------------------------------------------------------------------------------
sub new {
  my ($pkg) = @_;
  return bless {}, $pkg;
}
#--------------------------------------------------------------------------------------------
sub addDeltaDays {
  my ($obj, $date, $deltaDays) = @_;
  return $date unless $deltaDays;
  
  require Date::Calc;
  my @date = $obj->splitDate($date);
  @date    = Date::Calc::Add_Delta_Days(@date, $deltaDays);
  return $obj->joinDate(@date);
}
#--------------------------------------------------------------------------------------------
sub getNextDate {
  my ($obj, $date) = @_;
  $obj->addDeltaDays($date, 1);
}
#--------------------------------------------------------------------------------------------
sub getPreviousDate {
  my ($obj, $date) = @_;
  $obj->addDeltaDays($date, -1);
}
#--------------------------------------------------------------------------------------------
sub splitDate {
  my ($obj, $date) = @_;
  die "Wrong date format: $date (should be swedish date)" unless $date =~ m{ \A \d{8} \z }xms;
  my $year  = substr $date, 0, 4;
  my $month = substr $date, 4, 2;
  my $day   = substr $date, 6, 2;
  return ($year, $month, $day);
}
#--------------------------------------------------------------------------------------------
sub joinDate {
  my ($obj, $year, $month, $day) = @_;
  $month = "0$month" if $month < 10;
  $day   = "0$day"   if $day   < 10;
  return "$year$month$day";
}
#--------------------------------------------------------------------------------------------
sub getToday {
  my ($obj) = @_;
  return $context->getSingleton('O2::Mgr::DateTimeManager')->newObject()->format('yyyyMMdd');
}
#--------------------------------------------------------------------------------------------
sub toSwedishDate {
  my ($obj, $date) = @_;
  return $date if $date =~ m{ \A \d{8}  \z }xms;
  if (my ($day, $month, $year) = $date =~ m{ \A  (\d\d) [.] (\d\d) [.] (\d\d\d\d)  \z }xms) {
    return "$year$month$day";
  }
  return $context->getSingleton('O2::Mgr::DateTimeManager')->newObject($date)->format('yyyyMMdd');
}
#--------------------------------------------------------------------------------------------
sub getYearAndWeek {
  my ($obj, $date) = @_;
  $date = $context->getSingleton('O2::Mgr::DateTimeManager')->newObject($date);

  my $year  = $date->getYear();
  my $week  = $date->getWeekNumber();
  my $month = $date->getMonth();

  $year-- if $month ==  1 && $week > 50;
  $year++ if $month == 12 && $week == 1;
  $week = "0$week" if $week < 10 && !wantarray;

  return wantarray ? ($year, $week) : "$year$week";
}
#--------------------------------------------------------------------------------------------
1;
