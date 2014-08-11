package O2::Cgi::DateTime;

use strict;

use base 'O2::Obj::DateTime';

#-----------------------------------------------------------------------------
sub new {
  my ($package, %params) = @_;
  my $obj = $params{dateTime};
  $obj->{inputFieldFormat} = $params{format};
  $obj->{inputFieldName}   = $params{name};
  return bless $obj, 'O2::Cgi::DateTime';
}
#-----------------------------------------------------------------------------
sub getFormat {
  my ($obj) = @_;
  return $obj->{inputFieldFormat};
}
#-----------------------------------------------------------------------------
sub getInputFieldName {
  my ($obj) = @_;
  return $obj->{inputFieldName};
}
#-----------------------------------------------------------------------------
1;
