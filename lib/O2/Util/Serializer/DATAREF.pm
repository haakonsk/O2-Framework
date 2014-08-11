package O2::Util::Serializer::DATAREF;

use strict;

use base 'O2::Util::Serializer';

#------------------------------------------------------------
sub new {
  my ($pkg, %args) = @_;
  return bless {}, $pkg;
}
#------------------------------------------------------------
sub freeze {
  my ($obj, $structure) = @_;
  return $structure;
}
#------------------------------------------------------------
sub thaw {
  my ($obj, $freezedStructure) = @_;
  return $freezedStructure;
}
#------------------------------------------------------------
1;
