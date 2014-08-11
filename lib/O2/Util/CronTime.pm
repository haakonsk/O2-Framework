package O2::Util::CronTime;

use strict;

#------------------------------------------------------------
sub new {
  my ($pkg, $cronString) = @_;
  my $obj = bless {}, $pkg;
  
  my @parts = split /\s+/, $cronString;
  die "Not a valid cron-syntax '$cronString' (need a string with 5 parameters, found $#parts)" if $#parts != 4;
  
  $obj->setCronString($cronString);
  
  my @minutes = $obj->expandMinutes();
  my @hours   = $obj->expandHours();
  my @DOMs    = $obj->expandDOMs();
  my @months  = $obj->expandMonths();
  my @DOWs    = $obj->expandDOWs();
  
  foreach (@minutes) { die "Minute out of range"       if $_ < 0 || $_ > 59; }
  foreach (@hours)   { die "Hour out of range"         if $_ < 0 || $_ > 23; }
  foreach (@DOMs)    { die "Day of month out of range" if $_ < 1 || $_ > 31; }
  foreach (@months)  { die "Month out of range"        if $_ < 1 || $_ > 12; }
  foreach (@DOWs)    { die "Day of week out of range"  if $_ < 0 || $_ > 7; }
  
  die 'Month/Day of month out of range' if $#months == 0 && $#DOMs == 0 && $months[0] == 2 && $DOMs[0] > 29;
  
  if ($#DOMs == 0 && $DOMs[0] > 30) {
    my $okMonth = undef;
    foreach (@months) {
      $okMonth = 1 if $_ =~ m/^(?: 1 | 3 | 5 | 7 | 8 | 10 | 12  )$/x;
    }
    die "Month/Day of month out of range" unless $okMonth;
  }
  
  return $obj;
}
#------------------------------------------------------------
sub expandMinutes {
  my ($obj) = @_;
  return $obj->_expand( $obj->getMinuteString(), 0 => 59 );
}
#------------------------------------------------------------
sub expandHours {
  my ($obj) = @_;
  return $obj->_expand( $obj->getHourString(), 0 => 23 );
}
#------------------------------------------------------------
sub expandDOMs {
  my ($obj) = @_;
  return $obj->_expand( $obj->getDOMString(), 1 => 31 );
}
#------------------------------------------------------------
sub expandMonths {
  my ($obj) = @_;
  return $obj->_expand( $obj->getMonthString(), 1 => 12 );
}
#------------------------------------------------------------
sub expandDOWs {
  my ($obj) = @_;
  my @parts = split /,/, $obj->getDOWString();
  foreach (@parts) {
    s/0/7/; # 0 AND 7 is sunday
  }
  return $obj->_expand( join (',', @parts), 1 => 7 );
}
#------------------------------------------------------------
sub _expand {
  my ($obj, $string, $min, $max) = @_;
  my @parts = split /,/, $string;
  my %expanded;
  foreach my $part (@parts) {
    $part =~ s/\*/$min-$max/;
    if ( $part =~ m/^(\d+)\-(\d+)(?:\/(\d+))?$/ ) {
      my $start = $1;
      my $stop  = $2;
      my $step  = $3 || 1;
      
      if ($start > $stop) {
        ($start, $stop) = ($stop, $start);
      }
      $start = $min if $start < $min;
      $stop  = $max if $stop  > $max;
      
      for (my $i = $start; $i <= $stop; $i+=$step) {
        $expanded{$i} = 1;
      }
    }
    elsif ($part =~ m/^\-?\d+$/) {
      $expanded{$part} = 1;
    }
  }
  return sort { $a <=> $b } keys %expanded;
}
#------------------------------------------------------------
sub getCronString {
  my ($obj) = @_;
  return $obj->{cronString};
}
#------------------------------------------------------------
sub setCronString {
  my ($obj, $cronString) = @_;
  $obj->{cronString} = $cronString;
}
#------------------------------------------------------------
sub getMinuteString {
  my ($obj) = @_;
  return ($obj->splitCronTime())[0];
}
#------------------------------------------------------------
sub setMinuteString {
  my ($obj, $minuteString) = @_;
  my @parts = $obj->splitCronTime();
  $parts[0] = $minuteString;
  $obj->joinCronTime(@parts);
}
#------------------------------------------------------------
sub getHourString {
  my ($obj) = @_;
  return ($obj->splitCronTime())[1];
}
#------------------------------------------------------------
sub setHourString {
  my ($obj, $hourString) = @_;
  my @parts = $obj->splitCronTime();
  $parts[1] = $hourString;
  $obj->joinCronTime(@parts);
}
#------------------------------------------------------------
sub getDOMString {
  my ($obj) = @_;
  return ($obj->splitCronTime())[2];
}
#------------------------------------------------------------
sub setDOMString {
  my ($obj, $DOMString) = @_;
  my @parts = $obj->splitCronTime();
  $parts[2] = $DOMString;
  $obj->joinCronTime(@parts);
}
#------------------------------------------------------------
sub getMonthString {
  my ($obj) = @_;
  return ($obj->splitCronTime())[3];
}
#------------------------------------------------------------
sub setMonthString {
  my ($obj, $monthString) = @_;
  my @parts = $obj->splitCronTime();
  $parts[3] = $monthString;
  $obj->joinCronTime(@parts);
}
#------------------------------------------------------------
sub getDOWString {
  my ($obj) = @_;
  return ($obj->splitCronTime())[4];
}
#------------------------------------------------------------
sub setDOWString {
  my ($obj, $DOWString) = @_;
  my @parts = $obj->splitCronTime();
  $parts[4] = $DOWString;
  $obj->joinCronTime(@parts);
}
#------------------------------------------------------------
sub joinCronTime {
  my ($obj, @parts) = @_;
  $obj->setCronString(join ' ', @parts);
}
#------------------------------------------------------------
sub splitCronTime {
  my ($obj) = @_;
  my @parts = split /\s/, $obj->{cronString}, 5;
  return @parts;
}
#----------------------------------------------------------------------
sub nextRun {
  my ($obj, $time) = @_;
  $time ||= int time;
  
  $obj->{timeAndDate} = [ (localtime( $time ))[1..6] ];
  $obj->{timeAndDate}->[4] += 1900;
  $obj->{timeAndDate}->[3] ++;
  
  $obj->{pointers} = {};
  
  $obj->_setupPointer( 'month'  );
  $obj->_setupPointer( 'DOM'    );
  $obj->_setupPointer( 'hour'   );
  $obj->_setupPointer( 'minute' );
  
  if ($obj->getDOWString() !~ m/\*|[01]\-7|(0,)?1,2,3,4,5,6,7/) { # We have an explicit DOW
    my %possibleDOWs = map {$_ => 1} $obj->expandDOWs();
    
    while ( not $possibleDOWs{ $obj->_getCurrentDOW() } ) {
      $obj->increaseUnit('DOM');
    }
    
    # We need to go forward, so let's set the hour and minute pointer to the first elm of both
    $obj->{pointers}->{minute} = 0;
    $obj->{pointers}->{hour}   = 0;
  }
  
  require Time::Local;
  my $epoch = Time::Local::timelocal(
    0,
    $obj->{possibilities}->{minute}->[ $obj->{pointers}->{minute} ],
    $obj->{possibilities}->{hour}->[   $obj->{pointers}->{hour}   ],
    $obj->{possibilities}->{DOM}->[    $obj->{pointers}->{DOM}    ],
    $obj->{possibilities}->{month}->[  $obj->{pointers}->{month}  ] -1,
    $obj->{year} - 1900,
  );
  return $epoch;
}
#----------------------------------------------------------------------
sub _getCurrentDOW {
  my ( $obj ) = @_;
  require Date::Calc;
  my $currentDOW = Date::Calc::Day_of_Week(
    $obj->{year},
    $obj->{possibilities}->{month}->[  $obj->{pointers}->{month}  ],
    $obj->{possibilities}->{DOM}->[    $obj->{pointers}->{DOM}    ],
  );
  return $currentDOW;
}
#----------------------------------------------------------------------
sub _setupPointer {
  my ($obj, $name) = @_;
  
  my $value;
  
  my $timeIndex;
  if ($name eq 'month') {
    $obj->{year} = $obj->{timeAndDate}->[ 4 ];
    $timeIndex = 3;
  }
  elsif ($name eq 'DOM')  { $timeIndex = 2; }
  elsif ($name eq 'hour') { $timeIndex = 1; }
  else {                    $timeIndex = 0; }
  
  $value = $obj->{timeAndDate}->[$timeIndex];
  
  my $ucName = ucfirst $name;
  my $methodName = 'expand' . $ucName . 's';
  $obj->{possibilities}->{$name} = [ $obj->$methodName() ];
  foreach ( 0 .. $#{ $obj->{possibilities}->{$name} } ) {
    next if $name eq 'DOM' && $obj->_dateOutOfRange(
      $obj->{year},
      $obj->{possibilities}->{month}->[  $obj->{pointers}->{month}  ],
      $obj->{possibilities}->{DOM}->[ $_ ],
    );
    
    if ( $value <= $obj->{possibilities}->{$name}->[$_] ) {
      $obj->_resetTimeAndDate($timeIndex) if $value != $obj->{possibilities}->{$name}->[$_]; # If not an exact match, let's reset for every smaller time unit
      $obj->{pointers}->{$name} = $_;
      last;
    }
  }
  if (!exists $obj->{pointers}->{$name}) { # We are later now than any of the places we need to be
    $obj->{pointers}->{$name} = $#{ $obj->{possibilities}->{$name} }; # Make sure we "bump" it
    $obj->increaseUnit($name);
    $obj->_resetTimeAndDate($timeIndex);
  }
}
#----------------------------------------------------------------------
sub _dateOutOfRange {
  my ($obj, $year, $month, $day) = @_;
  my $maxDays = 31;
  if ($month == 2) {
    $maxDays = 28 + !($year % 400) || (!($year % 4 ) && ($year % 100)) ? 1 : 0;
  }
  elsif ($month =~ m/^(?: 4 | 6 | 9 | 11 )$/x) {
    $maxDays = 30;
  }
  if ($day == $obj->{timeAndDate}->[2]  &&  $obj->getCronString=~m/^\*\s\*\s[\d\,]\s\*\s\*$/) {
    $maxDays = 0;
  }
  
  return $day > $maxDays ? 1 : 0;
}
#----------------------------------------------------------------------
sub _resetTimeAndDate {
  my ($obj, $from) = @_;
  for ( 0 .. ( $from - 1 ) ) { # Make sure we reset time/date for everything below
    $obj->{timeAndDate}->[ $_ ] = $_ == 2 ? 1 : 0; # If we're resetting DOM (2), it must be 1, else 0
  }
}
#----------------------------------------------------------------------
sub increaseUnit {
  my ($obj, $name) = @_;
  if ($name eq 'year') {
    $obj->{year}++;
    return;
  }
  
  $obj->{pointers}->{$name}++;
  if ($obj->{pointers}->{$name} > $#{ $obj->{possibilities}->{$name} }) {
    $obj->{pointers}->{$name} = 0;
    $obj->increaseUnit(
        $name eq 'minute' ? 'hour'
      : $name eq 'hour'   ? 'DOM'
      : $name eq 'DOM'    ? 'month'
      :                     'year'
    );
  }
}
#----------------------------------------------------------------------
1;
