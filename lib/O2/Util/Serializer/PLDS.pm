package O2::Util::Serializer::PLDS;

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
  require O2::Data;
  my $data = O2::Data->new();
  return $data->dump($structure);
}
#------------------------------------------------------------
sub thaw {
  my ($obj, $freezedStructure) = @_;
  require O2::Data;
  my $data = O2::Data->new();
  return $data->undump($freezedStructure);
}
#------------------------------------------------------------
1;
