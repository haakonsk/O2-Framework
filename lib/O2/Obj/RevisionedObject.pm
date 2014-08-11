package O2::Obj::RevisionedObject;

# Class representing a serialized, revisioned object

use strict;

use base 'O2::Obj::Object';

use O2 qw($context);

#-------------------------------------------------------------------------------
sub getUnserializedObject {
  my ($obj) = @_;
  my $unserializedRaw = $context->getSingleton('O2::Data')->undump( $obj->getSerializedObject() ) or die "Error in dump";
  return $context->getSingleton('O2::Mgr::UniversalManager')->unserializeObject( $obj->getSerializedObject() );
}
#-------------------------------------------------------------------------------
sub isSerializable {
  return 0;
}
#-------------------------------------------------------------------------------
sub isDeletable {
  return 1;
}
#-------------------------------------------------------------------------------
1;
