package O2::Util::DateFormat;

# Format dates according to given format
# reference: http://www.unicode.org/reports/tr35/#Date_Format_Patterns
# TODO: implement date parsing to epoch e.g via HTTP::Date for the dateFormat method. 
#       Look at the taglib for dateFormat

use strict;

use O2 qw($context $config);

#-----------------------------------------------------------------------------------------
sub new {
  my ($pkg, $locale, %params) = @_;
  my $obj = bless { locale => $locale }, $pkg;
  
  $obj->{defaultDateFormat} = $config->get('o2.defaultDateFormat');
  if ($obj->{locale} ne '' && ref $obj->{locale} ne 'O2::Lang::Locale') { # The provided locale is a string like nb_NO (I think)
    $obj->{locale} = $context->getSingleton('O2::Lang::LocaleManager')->getLocale( $obj->{locale} );
  }
  $obj->{locale} ||= $context->getLocale(); # No locale provided
  
  return $obj;
}
#-----------------------------------------------------------------------------------------
# $time parameter may be a string/int or an O2::Obj::DateTime object.
sub dateFormat {
  my ($obj, $time, $format) = @_;

  $format ||= $obj->{defaultDateFormat};
  # we assume the user is providing valid format for us if this one doesn't go true
  if ($format  &&  ($format eq 'full' || $format eq 'short' || $format eq 'medium' || $format eq 'long')) {
    my $originalFormat = $format;
    $format = $obj->{locale}->getDateFormat($format) or die "getDateFormat('$originalFormat') didn't return anything";
  }
  $format ||= $obj->{locale}->getDateFormatDefault() or die "No default date format";

  my ($sec, $min, $hour, $mday, $mon, $year, $wday, $yday, $isdst);
  if (ref $time) {
    ($sec, $min, $hour, $mday, $mon, $year, $wday, $yday, $isdst)
      = ($time->getSeconds(), $time->getMinutes(), $time->getHours(), $time->getDayOfMonth(), $time->getMonth(), $time->getYear(), $time->getDayOfWeek(), $time->getDayOfYear(), $time->isDaylightSavingsTime());
    my $date = sprintf "%04d%02d%02d", $year, $mon, $mday;
    $time = $obj->_getDateCalc()->dateTime2Epoch($date);
  }
  else {
    $time = $obj->dateTime2Epoch($time) if $time !~ m/^\d{7,10}$/;
    ($sec, $min, $hour, $mday, $mon, $year, $wday, $yday, $isdst) = localtime(  $time ? $time : time  );
    $year += 1900;
    $mon++;
  }
  $wday = $obj->_adjustWeekdayAccordingToLocale($wday);

  $obj->{execeptions} = undef;
  $obj->{eId} = 0;
  # preserving quoted words eg. " h 'o\'clock'" becomes " 9 o'clock
  $format =~ s|\\\'|<slashFnutt>|g;
  while ($format =~ s/\'([^\']+)\'/<$obj->{eId}>/) { # builds up a <0> <1> where the number corresponds to a index in our tmp array
    $obj->{execeptions}->[ $obj->{eId}++ ] = $1;
  }
  
  my $na = 'n/a';
  
  #last entries shows all that are not yet implemented
  $format = $obj->_processStrings(
    $format,
    [
      'MMMMM' ,         sub { $obj->{locale}->getNarrowMonth($mon) },
      'MMMM',           sub { $obj->{locale}->getMonth($mon) },
      'MMM',            sub { $obj->{locale}->getAbbreviatedMonth($mon)},
      'MM',             sub { sprintf('%02d',$mon)},
      'M',              sub { $mon },
      '(EEEEE|eeeee)',  sub { $obj->{locale}->getNarrowDay($wday) }, 
      '(EEEE|eeee)',    sub { $obj->{locale}->getDay($wday) }, 
      '(EEE|eee)',      sub { $obj->{locale}->getAbbreviatedDay($wday) }, 
      'EE',             sub { sprintf('%02d', ($wday==7?1:$wday+1) ) },
      'E',              sub { ($wday==7?1:$wday+1)  },
      'ee',             sub { sprintf('%02d', $wday)},
      'e',              sub { $wday },
      'yyyyy',          sub { sprintf('%05d', $year) },
      'yyyy',           sub { sprintf('%04d', $year) },
      'yyy',            sub { sprintf('%03d', $year) },
      'yy' ,            sub { substr(sprintf('%02d', $year),2,4) }, #see doc for this one
      'y' ,             sub { $year },
      'Y',              sub { $year }, # this is not right, I think should be ISO year-week calendar
      'dd',             sub { sprintf('%02d', $mday) },# not specified but nice to have 0padded da
      'd',              sub { $mday },
      'D',              sub { $yday },
      'h',              sub { ($hour>12?$hour%12:$hour) },
      'HH',             sub { sprintf('%02d',$hour) },
      'H',              sub { $hour },
      'K',              sub { my $h=($hour>12?$hour%12:$hour); return ($h==12?0:$h);  }, # possible bug here 0 am or pm?
      'k',              sub { ($hour==0?24:$hour)  }, 
      'mm',             sub { sprintf('%02d', $min) },
      'm',              sub { $min },
      'ss',             sub { sprintf('%02d', $sec) },
      's',              sub { $sec },
      'a',              sub { ($hour<=12?$obj->{locale}->getAM():$obj->{locale}->getPM()) },
      'G',              sub { ($year<=0? $obj->{locale}->getEraBC():$obj->{locale}->getEraAC())},
      'ww',             sub { sprintf('%02d',$obj->_getWeekNumber($time)) },
      'w',              sub { $obj->_getWeekNumber($time) },
      # not implemented yet
      '(z{1,3}|u|W|f|g|S|A|Z)',       sub { $na },
    ]
  );
  
  # restore data with values
  while ($format =~ s/<(\d+)>/$obj->{execeptions}->[$1]/) {
  }
  
  $format =~ s|<slashFnutt>|\'|g;
  # some locale defines dubbel up the . 
  # eg. nb_NO has medium format pattern: d. MMM. yyyy
  # and have the abvr. month to be 'feb.' leading to MMM. to become feb..
  $format =~ s|\.\.|\.|g;
  
  return $format;
}
#-----------------------------------------------------------------------------------------
sub _processStrings {
  my ($obj, $string, $patterns) = @_;
  
  for (my $i = 0; $i < @{$patterns}; $i+=2) {
    while ($string =~ s/$patterns->[$i]/<$obj->{eId}>/) { # builds up a <0> <1> where the number corresponds to a index in our tmp array
      push @{ $obj->{execeptions} }, &{ $patterns->[$i+1] };
      $obj->{eId}++;
    }
  }
  return $string;
}
#-----------------------------------------------------------------------------------------
sub dateTime2Epoch {
  my ($obj, $dateTime) = @_;
  if ($dateTime =~ m{ \A  (\d{4})  (\d{2})  (\d{2})  \z }xms) {
    $dateTime = "$1-$2-$3";
  }
  $dateTime =~ s/\./-/gxms;
  use HTTP::Date qw/str2time/;
  my $epoch = str2time($dateTime);
  die "Couldn't convert dateTime ($dateTime) to epoch" unless defined $epoch;
  
  return $epoch;
}
#-----------------------------------------------------------------------------------------
sub dateTimeToObject {
  my ($obj, $dateStr) = @_;
  my $dateTime = $context->getSingleton('O2::Mgr::DateTimeManager')->newObject();
  $dateTime->setDateTime($dateStr);
  return $dateTime;
}
#-----------------------------------------------------------------------------------------
sub _getWeekNumber {
  my ($obj, $epoch) = @_;
  return scalar $obj->_getDateCalc()->getWeekNumber($epoch);
}
#-----------------------------------------------------------------------------------------
sub _getDateCalc {
  my ($obj) = @_;
  $obj->{dateCalc} ||= $context->getSingleton('O2::Util::DateCalc');
  return $obj->{dateCalc};
}
#-----------------------------------------------------------------------------------------
sub _adjustWeekdayAccordingToLocale {
  my ($obj, $wday) = @_;
  my $firstDay = $obj->{locale}->getFirstDayOfWeek();
  $wday = $wday+1 if $firstDay eq 'sun';
  $wday = $wday+2 if $firstDay eq 'sat';
  $wday = $wday+3 if $firstDay eq 'fri';
  $wday = $wday+4 if $firstDay eq 'thu';
  $wday = $wday+5 if $firstDay eq 'wed';
  $wday = $wday+6 if $firstDay eq 'tue';
  $wday -= 7 if $wday >= 7;
  return $wday;
}
#-----------------------------------------------------------------------------------------
1;
