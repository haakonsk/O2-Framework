package O2::DB::Util;

use strict;

#-----------------------------------------------------------------------------
sub new {
  my ($pkg, %params) = @_;
  return bless \%params, $pkg;
}
#-----------------------------------------------------------------------------
sub encodePlaceHolders {
  my ($obj, @placeHolders) = @_;
  return @placeHolders unless @placeHolders;

  require Encode;
  my @encodedPlaceHolders;
  foreach my $value (@placeHolders) {
    if ('ARRAY' eq ref $value) {
      my @innerValues;
      foreach my $innerValue (@{$value}) {
        push @innerValues, Encode::encode('utf-8', $innerValue);
      }
      push @encodedPlaceHolders, \@innerValues;
    }
    else {
      push @encodedPlaceHolders, Encode::encode('utf-8', $value);
    }
  }
  return @encodedPlaceHolders;
}
#-----------------------------------------------------------------------------
sub decodeResult {
  my ($obj, $result) = @_;
  return $result;
}
#-----------------------------------------------------------------------------
1;
