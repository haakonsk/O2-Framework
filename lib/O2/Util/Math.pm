package O2::Util::Math;

use strict;

my $half;

#----------------------------------------------------
sub new {
  my ($pkg) = @_;
  
  # Determine what value to use for "one-half".  Because of the
  # perversities of floating-point hardware, we must use a value
  # slightly larger than 1/2.  We accomplish this by determining
  # the bit value of 0.5 and increasing it by a small amount in a
  # lower-order byte.  Since the lowest-order bits are still zero,
  # the number is mathematically exact.
  
  my $halfhex = unpack ('H*', pack ('d', 0.5));
  if (substr ($halfhex, 0, 2) ne '00' && substr ($halfhex, -2) eq '00') {
    # It's big-endian.
    substr ($halfhex, -4) = '1000';
  }
  else {
    # It's little-endian.
    substr ($halfhex, 0,4) = '0010';
  }
  
  $half = unpack ('d', pack ('H*', $halfhex));
  
  bless {}, $pkg;
}
#----------------------------------------------------
# "Nearest" routines (round to a multiple of any number)
sub nearest {
  my ($self, $target, @inputs) = @_;
  my @res;
  my $x;
  
  $target = abs $target if $target < 0;
  foreach $x (@inputs) {
    if ($x >= 0) {
      push @res, $target * int (($x + $half * $target) / $target);
    }
    else {
      push @res, $target * O2::Util::Math::ceil($self, ($x - $half * $target) / $target);
    }
  }
  return wantarray ? @res : $res[0];
}
#----------------------------------------------------
sub ceil {
  my ($self, $number) = @_;
  return index ($number, '.') == -1  ?  $number  :  int ($number) + ($number >= 0 ? 1 : 0);
}
#----------------------------------------------------
sub floor {
  my ($self, $number) = @_;
  return index ($number, '.') == -1  ?  $number  :  int ($number) - ($number <= 0 ? 1 : 0);
}
#----------------------------------------------------
sub min {
  my ($obj, @numbers) = @_;
  my $min = shift @numbers;
  foreach my $number (@numbers) {
    $min = $number if $number < $min;
  }
  return $min;
}
#----------------------------------------------------
sub max {
  my ($obj, @numbers) = @_;
  my $max = shift @numbers;
  foreach my $number (@numbers) {
    $max = $number if $number > $max;
  }
  return $max;
}
#----------------------------------------------------
1;
