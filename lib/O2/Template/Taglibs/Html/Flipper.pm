package O2::Template::Taglibs::Html::Flipper;

use strict;

#----------------------------------------------------
sub TIESCALAR {
  my ($package, @values) = @_;
  bless \@values, $package;
  return \@values;
}
#----------------------------------------------------
sub FETCH {
  my ($obj) = @_;
  push @{$obj}, shift @{$obj};
  return $obj->[-1];
}
#----------------------------------------------------
sub STORE {
  my ($obj, $value) = @_;
  unshift @{$obj}, $value;
  return $value;
}
#----------------------------------------------------
1;
