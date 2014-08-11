package O2::Util::NumberFormat;

# XXX: Escaping special characters not implemented
# XXX: Exponential notation not implemented

use strict;

use O2 qw($context);

#--------------------------------------------------------#
sub new {
  my ($pkg, $locale, $encoding) = @_;

  my $obj = bless {}, $pkg;

  if (defined $locale && $locale ne '' && ref $locale ne 'O2::Lang::Locale') {
    $locale = $context->getSingleton('O2::Lang::LocaleManager')->getLocale($locale);
  }
  $locale ||= $context->getLocale();

  require O2::Util::Math;
  require O2::Util::String;

  $obj->{locale}   = $locale;
  $obj->{math}     = O2::Util::Math->new();
  $obj->{string}   = O2::Util::String->new();
  $obj->{encoding} = $encoding || 'utf-8';
  return $obj;
}
#--------------------------------------------------------#
sub percentFormat {
  my ($obj, $number, $locale, %params) = @_;
  $locale ||= $obj->{locale};
  $number *= 100;
  return $obj->doFormat( $params{format} || $locale->getPercentFormat(), $number, %params );
}
#--------------------------------------------------------#
sub numberFormat {
  my ($obj, $number, $locale, %params) = @_;
  $locale ||= $obj->{locale};
  $number = $obj->{math}->nearest( delete $params{roundToNearest}, $number ) if $params{roundToNearest};
  return $obj->doFormat( $params{format} || $locale->getDecimalFormat(),  $number,  %params );
}
#--------------------------------------------------------#
sub moneyFormat {
  my ($obj, $number, $locale, %params) = @_;
  $locale ||= $obj->{locale};

  return $obj->doFormat( $params{format} || $locale->getCurrencyFormat(),  $number,  %params );
}
#--------------------------------------------------------#
sub byteFormat {
  my ($obj, $numBytes, $locale, $format, %params) = @_;

  $format ||= $locale ? $locale->getDecimalFormat() : '#,##0.##';

  return $obj->doFormat( $format, $numBytes,                         %params ) .  ' B' if $numBytes < 1024;
  return $obj->doFormat( $format, $numBytes / 1024,                  %params ) . ' kB' if $numBytes < 1024*1024;
  return $obj->doFormat( $format, $numBytes / (1024*1024),           %params ) . ' MB' if $numBytes < 1024*1024*1024;
  return $obj->doFormat( $format, $numBytes / (1024*1024*1024),      %params ) . ' GB' if $numBytes < 1024*1024*1024*1024;
  return $obj->doFormat( $format, $numBytes / (1024*1024*1024*1024), %params ) . ' TB';
}
#--------------------------------------------------------#
sub doFormat {
  my ($obj, $format, $number, %params) = @_;

  # The format may actually be two formats, separated by a semicolon (;)
  # The second format applies to negative numbers

  my $positiveNumberFormat = $format;
  my $negativeNumberFormat = $format;

  my $semicolonPos = index $format, ';';
  if ($semicolonPos != -1) {
    $positiveNumberFormat = substr $format, 0, $semicolonPos;
    $negativeNumberFormat = substr $format, $semicolonPos+1;
  }
  my ($prefix, $numberFormat, $suffix);
  if ($number >= 0) {
    ($prefix, $numberFormat, $suffix) = $obj->splitFormat($positiveNumberFormat);
  }
  else {
    ($prefix, $numberFormat, $suffix) = $obj->splitFormat($negativeNumberFormat);
  }

  return $obj->formatBasedOnSignificantDigits($numberFormat, $number) if index ($numberFormat, '@') != -1;

  # else (Pattern does not contain @-characters)
  $number = $obj->roundAndFormat($number, $numberFormat, %params);
  $number = $prefix . $number . $suffix;
  my $minusSign = $obj->{locale}->getMinusSignSymbol();
  my $plusSign  = $obj->{locale}->getPlusSignSymbol();
  $number =~ s{ -  }{$minusSign}xms;
  $number =~ s{ \+ }{$plusSign}xms;

  return $number;
}
#--------------------------------------------------------#
sub roundAndFormat {
  my ($obj, $number, $numberFormat, %params) = @_;
  my ($integerPartFormat, $decimalPartFormat) = $obj->splitNumberFormat( $numberFormat );
  my ($integerPart,       $decimalPart)       = $obj->splitNumber(       $number       );
 
  if (length ($decimalPartFormat) == 0  ||  ($obj->{string}->countChars($decimalPartFormat, '0') == 0 && !$decimalPart)) {
    $integerPart++ if substr ($decimalPart, 0, 1) =~ m{ \A [56789] \z }xms;
    return $obj->getIntegerPartStr($integerPartFormat, $integerPart, %params);
  }
  # If decimalPartFormat
  my ($decimalPartFormatted, $addThisToIntegerPart) = $obj->getDecimalPartStr($decimalPartFormat, $decimalPart);
  $addThisToIntegerPart = -($addThisToIntegerPart || 0) if $number < 0; # Opposite below zero
  $integerPart += $addThisToIntegerPart if $addThisToIntegerPart;
  $integerPart  = $obj->getIntegerPartStr($integerPartFormat, $integerPart, %params);
  return $integerPart . ($params{decimalSymbol} || $obj->{locale}->getDecimalSymbol()) . $decimalPartFormatted;
}
#--------------------------------------------------------#
# Get the decimal part of the number as a formatted string
sub getDecimalPartStr {
  my ($obj, $format, $decimalPart) = @_;

  my $minDigits = $obj->{string}->countChars($format, '0');
  my $maxDigits = length $format;

  return $decimalPart if length ($decimalPart) >= $minDigits  &&  length ($decimalPart) <= $maxDigits;

  if (length ($decimalPart) < $minDigits) {
    my $formattedDecPart = $decimalPart;
    my $zero = $obj->{locale}->getNativeZeroDigitSymbol();
    for (my $i = length ($decimalPart); $i < $minDigits; $i++) {
      $formattedDecPart .= $zero;
    }
    return $formattedDecPart;
  }

  # length($decimalPart) > $maxDigits:
  $decimalPart = $obj->roundAtPos("0.$decimalPart", $maxDigits);
  return ('0' x $minDigits, 1) if $decimalPart == 1;
  $decimalPart = length $decimalPart > 2  ?  substr $decimalPart, 2  :  '';
  return $decimalPart  .  ($obj->{locale}->getNativeZeroDigitSymbol() x ($minDigits - length $decimalPart))  if length ($decimalPart) < $minDigits;

  $decimalPart = substr $decimalPart, 0, $maxDigits;
  my $numChars = length $decimalPart;
  for (my $i = $numChars; $i > $minDigits; $i--) {
    next if substr ($decimalPart, -1) ne '0';
    $decimalPart = substr $decimalPart, 0, -1;
  }
  return $decimalPart;
}
#--------------------------------------------------------#
# Get the integer part of the number as a formatted string
sub getIntegerPartStr {
  my ($obj, $format, $integerPart, %params) = @_;

  my $numDigitsGroupRight = $obj->getNumDigitsGroup($format, 'intRight');
  my $numDigitsGroupOther = $obj->getNumDigitsGroup($format, 'intOther');
  if ($numDigitsGroupOther <= 0) {
    $numDigitsGroupOther = $numDigitsGroupRight;
  }

  return $integerPart if $numDigitsGroupRight <= 0;

  my ($minSignificantDigits, $maxSignificantDigits) = $obj->getNumSignificantDigits($format);
  my $formattedIntPart = '';
  my $grp = $params{groupSymbol} || $obj->{locale}->getGroupSymbol();
  for (my $pos = length $integerPart; $pos >= 0; $pos--) {
    my $revPos = length ($integerPart) - $pos;
    if ($numDigitsGroupOther == $numDigitsGroupRight || $revPos < $numDigitsGroupRight+2) {
      if ($revPos % $numDigitsGroupRight == 1) {
        $formattedIntPart = substr ($integerPart, $pos, 1) . $grp . $formattedIntPart;
      }
      else {
        $formattedIntPart = substr ($integerPart, $pos, 1) . $formattedIntPart;
      }
    }
    else {
      if (($revPos-$numDigitsGroupRight) % $numDigitsGroupOther == 1) {
        $formattedIntPart = substr ($integerPart, $pos, 1) . $grp . $formattedIntPart;
      }
      else {
        $formattedIntPart = substr ($integerPart, $pos, 1) . $formattedIntPart;
      }
    }
  }
  $formattedIntPart = substr ($formattedIntPart, 0, -1);
  return $formattedIntPart;
}
#--------------------------------------------------------#
sub getNumSignificantDigits {
  my ($obj, $numStr) = @_;

  my $pos = 0;
  my $minNum = $obj->{string}->countChars($numStr, '@');
  if ($minNum == 0) {
    return (0, 0);
  }
  my $maxNum = $obj->{string}->countChars(substr ($numStr, rindex ($numStr, '@')), '#') + $minNum;
  return ($minNum, $maxNum);
}
#--------------------------------------------------------#
# Get the number of digits in the specified group (intRight, intOther, decLeft, decOther)
sub getNumDigitsGroup {
  my ($obj, $num, $whichGroup) = @_;
  my $groupSize;

  my $pos = 0;
  if ($whichGroup eq 'intRight') {
    my $posRight = rindex $num, q{,};
    $groupSize = $posRight != -1 ? length ($num) - $posRight - 1 : '0';
  }
  elsif ($whichGroup eq 'intOther') {
    my $posRight  = rindex $num, q{,};
    my $posLeft   = rindex $num, q{,}, $pos+1;
    if ($posRight == -1) {
      $groupSize = 0;
    }
    elsif ($posLeft == -1) {
      $groupSize = length ($num) - rindex ($num, q{,}) - 1; # Like for intRight
    }
    else {
      $groupSize = $posRight - $posLeft - 1;
    }
  }
  elsif ($whichGroup eq 'decLeft') {
    my $posLeft = index $num, q{,};
    $groupSize = $posLeft != -1 ? $posLeft : '0';
  }
  elsif ($whichGroup eq 'decOther') {
    my $posLeft  = index $num, q{,};
    my $posRight = index $num, q{,}, $posLeft;
    if ($posLeft == -1) {
      $groupSize = 0;
    }
    elsif ($posRight == -1) {
      $groupSize = $posLeft;
    }
    else {
      $groupSize = $posRight - $posLeft - 1;
    }
    $groupSize = index ($num, q{,}, (my $pos = index ($num, q{,}))) - $pos + 1;
  }
  else {
    die "_getNumDigitsGroup: Invalid argument (whichGroup = $whichGroup). Valid values are 'intRight', 'intOther', 'decLeft' and 'decOther'.";
  }
  return $groupSize;
}
#--------------------------------------------------------#
sub splitFormat {
  my ($obj, $format) = @_;
  my ($prefix, $numberFormat, $suffix) = $format =~ m{ \A
                                                          (.*?)                  # Prefix
                                                          (
                                                           [-+\#0@]              # First character in number format
                                                           [\#0\,@]*             # The rest of the integer part of the number format
                                                           (?: [.] [\#0@]+)?     # Optional decimal separator and 1 or more characters after the dot.
                                                          )
                                                          ( \z | [^.\#0@] .* \z) # Suffix
                                                      }xms;
  $prefix = $obj->formatPrefixOrSuffix($prefix);
  $suffix = $obj->formatPrefixOrSuffix($suffix);
  return ($prefix, $numberFormat, $suffix);
}
#--------------------------------------------------------#
sub splitNumberFormat {
  my ($obj, $format) = @_;
  my $dotPos = index $format, '.';
  return ($format, '') if $dotPos == -1;
  my $integerPart = substr $format, 0, $dotPos;
  my $decimalPart = substr $format, $dotPos+1;
  return ($integerPart, $decimalPart);
}
#--------------------------------------------------------#
sub splitNumber {
  my ($obj, $number) = @_;
  return $obj->splitNumberFormat($number);
}
#--------------------------------------------------------#
sub formatPrefixOrSuffix {
  my ($obj, $format) = @_;

  my $currencySymbol = $obj->{locale}->getCurrencySymbol();
  my $currencyName   = $obj->{locale}->getCurrencyName();
  my $percentSign    = $obj->{locale}->getPercentSignSymbol();
  
#  $format =~s/[^\¤\%\s]+//ms;
  $format =~ s{ ¤¤¤ }{$currencyName}xms;
#  $format =~ s{ ¤¤  }{}xms;
  $format =~ s{ ¤   }{$currencySymbol}gxms;
  $format =~ s{ %   }{$percentSign}xms;
  return $format;
}
#--------------------------------------------------------#
sub formatBasedOnSignificantDigits {
  my ($obj, $format, $number) = @_;
  my $currentSignificantDigits = length ($number) - $obj->numZeroesFirstInNumber($number);
  my ($minSignificantDigits, $maxSignificantDigits) = $obj->getNumSignificantDigits($format);
  if ($currentSignificantDigits > $maxSignificantDigits) {
    $number = $obj->roundBasedOnSignificantDigits($number, $maxSignificantDigits);
  }
  $currentSignificantDigits = length ($number) - $obj->numZeroesFirstInNumber($number) - (!$obj->isInteger($number) ? 1 : 0);
  if ($currentSignificantDigits < $minSignificantDigits) {
    $number = $obj->zeroPad($number, $minSignificantDigits-$currentSignificantDigits);
  }
  return $number;
}
#--------------------------------------------------------#
# How many zeroes before any of the significant digits?
sub numZeroesFirstInNumber {
  my ($obj, $num) = @_;
  my ($zeroesAndDots) = $num =~ m{ \A ([.0]*) [^.0] }xms; # Fix this. Fix what?
  my $numZeroes    = $obj->{string}->countChars($zeroesAndDots, '0');
  return $numZeroes;
}
#--------------------------------------------------------#
sub isInteger {
  my ($obj, $int) = @_;
  return $int =~ m{ \A ([+-]? \d+) \z }xms;
}
#--------------------------------------------------------#
sub roundBasedOnSignificantDigits {
  my ($obj, $num, $maxSignificantDigits) = @_;
  my $numDigits = $obj->numDigits($num);
  $maxSignificantDigits += $obj->numZeroesFirstInNumber($num);
  return $obj->roundAtPos($num, $maxSignificantDigits-1) if $numDigits > $maxSignificantDigits;
  return $num;
}
#--------------------------------------------------------#
# How many digits in the given number?
sub numDigits {
  my ($obj, $num) = @_;
  return $obj->{string}->countChars("$num", '0123456789');
}
#--------------------------------------------------------#
# Rounds a number at the specified position (offset)
# Ex: roundAtPos(12.3456,    3) == 12.35
#     roundAtPos(12345.6789, 3) == 12350
sub roundAtPos {
  my ($obj, $num, $roundingPosition) = @_;
  my $oldNum = $num;
  my $valueOfDigitAtRoundingPosition = $obj->getValueOfDigitAtPosition($num, $roundingPosition);
  return $obj->{math}->nearest($valueOfDigitAtRoundingPosition, $num);
}
#--------------------------------------------------------#
# How much does a 1 in this position count? (10, 1, 0.1, 0.01, ...?)
sub getValueOfDigitAtPosition {
  my ($obj, $numStr, $digitPos) = @_;
  my $dotPos = index $numStr, '.';
  return 10**(length (substr $numStr, 0, $dotPos)-$digitPos-1) if $dotPos  > $digitPos;
  return 10**(length ($numStr) - $digitPos - 1)                if $dotPos == -1;
  return 10**($dotPos-$digitPos-1);
}
#--------------------------------------------------------#
# Pads string representing a number with zeroes at the end.
sub zeroPad {
  my ($obj, $numStr, $numPad) = @_;
  my $zero = $obj->{locale}->getNativeZeroDigitSymbol();
  $numStr .= '.' if $obj->{string}->countChars($numStr, '.') <= 0;
  for my $i (0..$numPad-1) {
    $numStr .= $zero;
  }
  return $numStr;
}
#--------------------------------------------------------#
sub getMixedFraction {
  my ($obj, $number) = @_;
  my ($int, $fraction) = split /\./, "$number";
  $fraction ||= '';
  my $numDecimals = length $fraction;
  $fraction = 0 + "0.$fraction";
  my $denominator = 10 ** $numDecimals;
  my $numerator   = $fraction * $denominator;
 OUTER_LOOP:
  while (1) {
    for my $i (2 .. $numerator) {
      if ($numerator % $i == 0  &&  $denominator % $i == 0) {
        $numerator   /= $i;
        $denominator /= $i;
        next OUTER_LOOP;
      }
    }
    last;
  }
  return $int                      if $numerator == 0;
  return "$numerator/$denominator" if $int       == 0;
  return "$int $numerator/$denominator";
}
#--------------------------------------------------------#
1;
