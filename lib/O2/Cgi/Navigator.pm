package O2::Cgi::Navigator;

# Locate the origin from this request

use strict;

#------------------------------------------------------------
sub new {
  my ($package, %params) = @_;
  return bless \%params, $package;
}
#------------------------------------------------------------
sub method {
  my ($obj) = @_;
  return 1;
}
#------------------------------------------------------------
1;
