package O2::Obj::DatePeriod;

# It's optional if you want to set fromDate/toDate or numSeconds, or numSeconds in combination with either fromDate or toDate.

use strict;

use base 'O2::Obj::Object';

use O2 qw($context);

#-----------------------------------------------------------------------------
sub getTotalNumYears {
  my ($obj) = @_;
  return int ( $obj->getNumSeconds() / (60*60*24*365.25) ) unless $obj->getFromDate();

  my $deltaYears = $obj->getToDate()->getYear() - $obj->getFromDate()->getYear();
  $deltaYears-- if $obj->getFromDate()->format('MM-dd HH:mm:ss') gt $obj->getToDate()->format('MM-dd HH:mm:ss');
  return $deltaYears;
}
#-----------------------------------------------------------------------------
sub getTotalNumMonths {
  my ($obj) = @_;
  return int ( $obj->getNumSeconds() / (60*60*24*30) ) unless $obj->getFromDate();
  return 12*$obj->getTotalNumYears() + $obj->getMonthsOfYear();
}
#-----------------------------------------------------------------------------
sub getMonthsOfYear {
  my ($obj) = @_;
  die "Can't calculate getMonthsOfYear without fromDate/toDate" unless $obj->getFromDate();

  my $monthDiff = $obj->getToDate()->getMonth() - $obj->getFromDate()->getMonth();
  $monthDiff-- if $obj->getFromDate()->format('dd HH:mm:ss') gt $obj->getToDate()->format('dd HH:mm:ss');
  $monthDiff = 12 + $monthDiff if $monthDiff < 0;
  return $monthDiff;
}
#-----------------------------------------------------------------------------
sub getTotalNumWeeks {
  my ($obj) = @_;
  return int ( $obj->getNumSeconds() / (60*60*24*7) );
}
#-----------------------------------------------------------------------------
sub getWeeksOfMonth {
  my ($obj) = @_;
  die "Can't calculate getWeeksOfMonth without fromDate/toDate" unless $obj->getFromDate();
  return int ( $obj->getDaysOfMonth() / 7 );
}
#-----------------------------------------------------------------------------
sub getTotalNumDays {
  my ($obj) = @_;
  return int ( $obj->getNumSeconds() / (60*60*24) );
}
#-----------------------------------------------------------------------------
# Ignores time of day
sub getTotalNumDates {
  my ($obj) = @_;
  my $numDates = $obj->getTotalNumDays();
  my $fromDate = $obj->getFromDate();
  my $toDate   = $obj->getToDate();
  $numDates++ if                         $fromDate->format('HH:mm:ss') eq $toDate->format('HH:mm:ss');
  $numDates++ if $fromDate lt $toDate && $fromDate->format('HH:mm:ss') gt $toDate->format('HH:mm:ss');
  $numDates-- if $fromDate gt $toDate && $fromDate->format('HH:mm:ss') lt $toDate->format('HH:mm:ss');
  return $numDates;
}
#-----------------------------------------------------------------------------
sub getDaysOfMonth {
  my ($obj) = @_;
  die "Can't calculate getDaysOfMonth without fromDate/toDate" unless $obj->getFromDate();

  my $epoch = $obj->_getDateCalc()->addDelta( $obj->getFromDate()->getEpoch(), $obj->getTotalNumYears(), $obj->getMonthsOfYear(), 0 );
  my $fromDate = $context->getSingleton('O2::Mgr::DateTimeManager')->newObject($epoch);
  my $toDate   = $obj->getToDate();
  my $deltaDays = $toDate->getDayOfMonth() - $fromDate->getDayOfMonth();
  $deltaDays-- if $fromDate->format('HH:mm:ss') gt $toDate->format('HH:mm:ss');
  $deltaDays = $obj->_getDateCalc()->countDaysInMonth( $fromDate->getEpoch() )  +  $deltaDays if $deltaDays < 0;
  return $deltaDays;
}
#-----------------------------------------------------------------------------
sub getDaysOfWeek {
  my ($obj) = @_;
  return $obj->getDaysOfMonth() % 7;
}
#-----------------------------------------------------------------------------
sub getTotalNumHours {
  my ($obj) = @_;
  return int ( $obj->getNumSeconds() / (60*60) );
}
#-----------------------------------------------------------------------------
sub getHoursOfDay {
  my ($obj) = @_;
  return $obj->getTotalNumHours() % 24;
}
#-----------------------------------------------------------------------------
sub getTotalNumMinutes {
  my ($obj) = @_;
  return int ( $obj->getNumSeconds() / 60 );
}
#-----------------------------------------------------------------------------
sub getMinutesOfHour {
  my ($obj) = @_;
  return $obj->getTotalNumMinutes() % 60;
}
#-----------------------------------------------------------------------------
sub getSecondsOfMinute {
  my ($obj) = @_;
  return $obj->getNumSeconds % 60;
}
#-----------------------------------------------------------------------------
sub getTotalNumSeconds {
  my ($obj) = @_;
  return $obj->getNumSeconds();
}
#-----------------------------------------------------------------------------
sub getDates {
  my ($obj, $format) = @_;
  $format ||= 'yyyyMMdd';

  my $tmpDate = $obj->getFromDate();
  my $endDate = $obj->getToDate();

  my $firstDate = $tmpDate->format($format);

  my @datesInPeriod = ($firstDate);
  while (1) {
    $tmpDate->updateByDeltaDays(1);
    last if $tmpDate->format('yyyyMMdd') gt $endDate->format('yyyyMMdd');
    
    push @datesInPeriod, $tmpDate->format($format);
  }
  return @datesInPeriod;
}
#-----------------------------------------------------------------------------
sub getFromDay {
  my ($obj) = @_;
  return $obj->getFromDate()->format('dd');
}
#-----------------------------------------------------------------------------
sub getFromMonth {
  my ($obj) = @_;
  return $obj->getFromDate()->format('MM');
}
#-----------------------------------------------------------------------------
sub getFromYear {
  my ($obj) = @_;
  return $obj->getFromDate()->format('yyyy');
}
#-----------------------------------------------------------------------------
sub getToDay {
  my ($obj) = @_;
  return $obj->getToDate()->format('dd');
}
#-----------------------------------------------------------------------------
sub getToMonth {
  my ($obj) = @_;
  return $obj->getToDate()->format('MM');
}
#-----------------------------------------------------------------------------
sub getToYear {
  my ($obj) = @_;
  return $obj->getToDate()->format('yyyy');
}
#-----------------------------------------------------------------------------
sub containsDate {
  my ($obj, $date) = @_;
  return $context->getSingleton('O2::Util::DateCalc')->epochWithinEpochs( $date->getEpoch(), $obj->getFromDate()->getEpoch(), $obj->getToDate()->getEpoch() );
}
#-----------------------------------------------------------------------------
sub containsPeriod {
  my ($obj, $period) = @_;
  my $dateCalc = $context->getSingleton('O2::Util::DateCalc');
  return 0 unless $dateCalc->epochWithinEpochs( $period->getStartEpoch(), $obj->getFromDate()->getEpoch(), $obj->getToDate()->getEpoch() );
  return 0 unless $dateCalc->epochWithinEpochs( $period->getToEpoch(),    $obj->getFromDate()->getEpoch(), $obj->getToDate()->getEpoch() );
  return 1;
}
#-----------------------------------------------------------------------------
sub _calculateToDate {
  my ($obj) = @_;
  die "Can't calculate toDate without numSeconds" unless $obj->getNumSeconds();
  die "Can't calculate toDate without fromDate"   unless $obj->getFromDate();
  my $toDateEpoch = $obj->_getDateCalc()->addDeltaDays( $obj->getFromDate()->getEpoch(), $obj->getNumSeconds() );
  $obj->setToDate($toDateEpoch);
}
#-----------------------------------------------------------------------------
sub _calculateFromDate {
  my ($obj) = @_;
  die "Can't calculate toDate without numSeconds" unless $obj->getNumSeconds();
  die "Can't calculate toDate without toDate"     unless $obj->getToDate();
  my $fromDateEpoch = $obj->_getDateCalc()->addDeltaDays( $obj->getFromDate()->getEpoch(), $obj->getNumSeconds() );
  $obj->setFromDate($fromDateEpoch);
}
#-----------------------------------------------------------------------------
sub _calculateNumSeconds {
  my ($obj) = @_;
  die "Can't calculate toDate without fromDate" unless $obj->getFromDate();
  die "Can't calculate toDate without toDate"   unless $obj->getToDate();
  my $numSeconds = $obj->getToDate()->getEpoch() - $obj->getFromDate()->getEpoch();
  $obj->setNumSeconds($numSeconds);
}
#-----------------------------------------------------------------------------
sub _getDateCalc {
  my ($obj) = @_;
  return $context->getSingleton('O2::Util::DateCalc');
}
#-----------------------------------------------------------------------------
1;
