package O2::Dispatch::ModPerlGlobals::Context;

use strict;

use Tie::Scalar;
our @ISA = qw(Tie::StdScalar);

#------------------------------------------------------------------------------------------------------------
sub TIESCALAR {
  my ($className) = @_;
  return bless {}, $className;
}
#------------------------------------------------------------------------------------------------------------
sub FETCH {
  my ($obj) = @_;
  my $context = $obj->{ $ENV{O2REQUESTID} };
  if (!$context) {
    require O2::Context;
    $context = O2::Context->new();
    $obj->STORE($context);
  }
  return $context;
}
#------------------------------------------------------------------------------------------------------------
sub STORE {
  my ($obj, $context) = @_;
  $obj->{ $ENV{O2REQUESTID} } = $context;
}
#------------------------------------------------------------------------------------------------------------
sub DESTROY {
  my ($obj) = @_;
}
#------------------------------------------------------------------------------------------------------------
1;
