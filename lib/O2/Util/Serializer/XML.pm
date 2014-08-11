package O2::Util::Serializer::XML;

# XXX Freezing and thawing an object seems to turn undef values into empty hash refs.

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
  require O2::Util::XMLGenerator;
  my $xmlGenerator = O2::Util::XMLGenerator->new();
  return $xmlGenerator->toXml( object => $structure );
}
#------------------------------------------------------------
sub thaw {
  my ($obj, $freezedStructure) = @_;
  require XML::Simple; 
  my $xmlSimple = XML::Simple->new();
  return $xmlSimple->XMLin($freezedStructure);
}
#------------------------------------------------------------
1;
