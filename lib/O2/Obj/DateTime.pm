package O2::Obj::DateTime;

use strict;

use base 'O2::Obj::Object';

use O2 qw($context $config);
use DateTime;

use overload(
  '""'  => '_toString',
  'cmp' => '_compare',
  '<=>' => '_compare',
);

#-----------------------------------------------------------------------------
sub new {
  my ($package, %params) = @_;
  my $obj = $package->SUPER::new(%params);
  if ($params{epoch}) {
    $obj->setEpoch( $params{epoch} );
  }
  elsif ($params{date}) {
    $obj->setDateTime( $params{date} );
  }
  else {
    $obj->setEpoch(time); # Default date/time is now
  }
  return $obj;
}
#-----------------------------------------------------------------------------
sub _compare {
  my ($date1, $date2) = @_;
  my $dateStr1 = ref ($date1) ? $date1->dbFormat() : 0;
  my $dateStr2 = ref ($date2) ? $date2->dbFormat() : 0;
  return $dateStr1 cmp $dateStr2;
}
#-----------------------------------------------------------------------------
sub _toString {
  my ($obj) = @_;
  my $dateStr = $obj->dbFormat() . ' (' . $obj->getMetaClassName();
  $dateStr   .= ", ID: " . $obj->getId() if $obj->getId();
  $dateStr   .= ')';
  return $dateStr;
}
#-----------------------------------------------------------------------------
sub setEpoch {
  my ($obj, $epoch) = @_;
  my ($seconds, $minutes, $hours, $dayOfMonth, $month, $year) = localtime $epoch;
  $obj->setYear(       $year + 1900 );
  $obj->setMonth(      $month + 1   );
  $obj->setDayOfMonth( $dayOfMonth  );
  $obj->setHours(      $hours       );
  $obj->setMinutes(    $minutes     );
  $obj->setSeconds(    $seconds     );
}
#-----------------------------------------------------------------------------
sub getEpoch {
  my ($obj) = @_;
  my $time = $obj->format('yyyyMMddTHHmmss');
  return $context->getDateFormatter()->dateTime2Epoch($time);
}
#-----------------------------------------------------------------------------
sub setDateTime { # See http://perl.active-venture.com/lib/HTTP/Date.html for a list of supported formats
  my ($obj, $dateStr, %params) = @_;

  require HTTP::Date;
  my ($year, $month, $dayOfMonth, $hours, $minutes, $seconds, $timeZone) = HTTP::Date::parse_date($dateStr);
  if (!$year) {
    $dateStr =~ s{ [.] }{-}xmsg;
    ($year, $month, $dayOfMonth, $hours, $minutes, $seconds, $timeZone) = HTTP::Date::parse_date($dateStr);
  }
  die "Couldn't parse date: '$dateStr'" unless $year;

  $dayOfMonth =~ s{ \A 0 (\d) }{$1}xms; # Strangely, dayOfMonth may be returned with a leading "0", while month is not.. Anyway, we remove it.
  $obj->setYear(       $year       );
  $obj->setMonth(      $month      );
  $obj->setDayOfMonth( $dayOfMonth );
  if (!$params{ignoreTime}) {
    $obj->setHours(   $hours   );
    $obj->setMinutes( $minutes );
    $obj->setSeconds( $seconds );
  }
}
#-----------------------------------------------------------------------------
# Create a new object based on the existing and add (or subtract if negative) delta - returns new DateTime-object
sub newByDeltaDays {
  my ($obj, $deltaDays) = @_;
  my $newDate = $obj->getManager()->newObject();
  $newDate->setEpoch( $obj->getEpochByDeltaDays($deltaDays) );
  return $newDate;
}
#-----------------------------------------------------------------------------
# Changes the date of this object
sub updateByDeltaDays {
  my ($obj, $deltaDays) = @_;
  $obj->setEpoch( $obj->getEpochByDeltaDays($deltaDays) );
  return $obj;
}
#-----------------------------------------------------------------------------
sub getEpochByDeltaDays {
  my ($obj, $deltaDays) = @_;
  return $context->getSingleton('O2::Util::DateCalc')->addDeltaDays( $obj->getEpoch(), $deltaDays );
}
#-----------------------------------------------------------------------------
sub setDate {
  my ($obj, $date) = @_;
  $date = sprintf "%08d", $date if length $date < 8;
  $obj->setDateTime( $date, ignoreTime => 1 );
}
#-----------------------------------------------------------------------------
sub getDate {
  my ($obj) = @_;
  return $obj->format('yyyyMMdd');
}
#-----------------------------------------------------------------------------
sub format {
  my ($obj, $format) = @_; # $format is optional
  
  $format ||= $config->get('o2.defaultDateFormat');
  
  # Since dateFormat() is slow...
  return sprintf '%04d-%02d-%02d',                $obj->getYear(), $obj->getMonth(), $obj->getDayOfMonth()                                                           if $format eq 'yyyy-MM-dd';
  return sprintf '%04d%02d%02d',                  $obj->getYear(), $obj->getMonth(), $obj->getDayOfMonth()                                                           if $format eq 'yyyyMMdd';
  return sprintf '%04d%02d%02dT%02d%02d%02d',     $obj->getYear(), $obj->getMonth(), $obj->getDayOfMonth(), $obj->getHours(), $obj->getMinutes(), $obj->getSeconds() if $format eq 'yyyyMMddTHHmmss';
  return sprintf '%04d-%02d-%02d %02d:%02d:%02d', $obj->getYear(), $obj->getMonth(), $obj->getDayOfMonth(), $obj->getHours(), $obj->getMinutes(), $obj->getSeconds() if $format eq 'yyyy-MM-dd HH:mm:ss';
  return sprintf '%02d/%02d',                     $obj->getDayOfMonth(), $obj->getMonth()                                                                            if $format eq 'dd/MM';
  return sprintf '%02d:%02d:%02d',                $obj->getHours(), $obj->getMinutes(), $obj->getSeconds()                                                           if $format eq 'HH:mm:ss';
  return sprintf '%02d.%02d.%02d',                $obj->getDayOfMonth(), $obj->getMonth(), $obj->getYearTwoDigits()                                                  if $format eq 'dd.MM.yy';
  
  return                 $obj->getWeekNumber() if $format eq 'w';
  return sprintf "%02d", $obj->getWeekNumber() if $format eq 'ww';
  
  # Exception. When calculating weeknumber we cannot just add weeknumber and year. If the weeknumber "leaks" into the next year we have to move the year as well
  my $year = $obj->getYear();
  $year++ if ($obj->getWeekNumber() eq 1 && $obj->getDayOfMonth() > 7);
  return $year.sprintf("%02d", $obj->getWeekNumber())                 if $format eq 'yyyyww';
  return ($year =~ /(\d{2})$/).sprintf("%02d", $obj->getWeekNumber()) if $format eq 'yyww';
  
  return $context->getDateFormatter()->dateFormat($obj, $format);
}
#-----------------------------------------------------------------------------
sub getYearTwoDigits {
  my ($obj) = @_;
  my $year = $obj->getYear();
  return substr $year, 2;
}
#-----------------------------------------------------------------------------
sub getWeekNumber {
  my ($obj) = @_;
  return $context->getDateFormatter()->_getWeekNumber($obj);
}
#-----------------------------------------------------------------------------
sub getExternalDateTimeObject {
  my ($obj) = @_;
  return $obj->{dateTime} = DateTime->new(
    year   => $obj->getYear(),
    month  => $obj->getMonth(),
    day    => $obj->getDayOfMonth(),
    hour   => $obj->getHours(),
    minute => $obj->getMinutes(),
    second => $obj->getSeconds(),
  );
}
#-----------------------------------------------------------------------------
sub getDayOfWeek {
  my ($obj) = @_;
  return $obj->getExternalDateTimeObject()->day_of_week();
}
#-----------------------------------------------------------------------------
sub getDayOfYear {
  my ($obj) = @_;
  return $obj->getExternalDateTimeObject()->day_of_year();
}
#-----------------------------------------------------------------------------
sub isDaylightSavingsTime {
  my ($obj) = @_;
  return $obj->getExternalDateTimeObject()->is_dst();
}
#-----------------------------------------------------------------------------
sub getSwedishDate {
  my ($obj) = @_;
  return $obj->format('yyyyMMdd');
}
#-----------------------------------------------------------------------------
# Format date the way the database expects the date to be formatted
sub dbFormat {
  my ($obj) = @_;
  return $obj->format('yyyy-MM-dd HH:mm:ss');
}
#-----------------------------------------------------------------------------
sub getMondayOfWeek {
  my ($obj) = @_;
  my $dayOfWeek = $obj->format('e');
  my $monday = $obj->newByDeltaDays( 1-$dayOfWeek );
  return $monday;
}
#-----------------------------------------------------------------------------
sub getSundayOfWeek {
  my ($obj) = @_;
  return $obj->getMondayOfWeek()->newByDeltaDays(6);
}
#-----------------------------------------------------------------------------
sub getHowLongAgo {
  my ($obj) = @_;
  return $context->getSingleton('O2::Mgr::DatePeriodManager')->newObject(
    fromDate => $obj,
    toDate   => time,
  );
}
#-----------------------------------------------------------------------------
sub isToday {
  my ($obj) = @_;
  my $now = $context->getSingleton('O2::Mgr::DateTimeManager')->newObject();
  return $obj->format('yyyy-MM-dd') eq $now->format('yyyy-MM-dd');
}
#-----------------------------------------------------------------------------
sub isYesterday {
  my ($obj) = @_;
  my $now       = $context->getSingleton('O2::Mgr::DateTimeManager')->newObject();
  my $yesterday = $now->newByDeltaDays(-1);
  return $obj->format('yyyy-MM-dd') eq $yesterday->format('yyyy-MM-dd');
}
#-----------------------------------------------------------------------------
sub clearTime {
  my ($obj) = @_;
  $obj->setHours(   0 );
  $obj->setMinutes( 0 );
  $obj->setSeconds( 0 );
}
#-----------------------------------------------------------------------------
1;
