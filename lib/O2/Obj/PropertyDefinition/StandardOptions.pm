package O2::Obj::PropertyDefinition::StandardOptions;

use strict;

#-------------------------------------------------------------------------------
sub new {
  my ($pkg, %init) = @_;
  return bless \%init, $pkg;
}
#-------------------------------------------------------------------------------
sub test {
  my ($obj, %params) = @_;
  return ({
    name  => 'Test1',
    value => 'test1',
  });
}
#-------------------------------------------------------------------------------
1;
