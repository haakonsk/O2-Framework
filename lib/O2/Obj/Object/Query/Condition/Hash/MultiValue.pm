package O2::Obj::Object::Query::Condition::Hash::MultiValue;

use strict;
use base 'O2::Obj::Object::Query::Condition::Hash';

#-----------------------------------------------------------------------------
sub getSql {
  my ($obj) = @_;
  my @values = $obj->getValues();
  my $sql = sprintf "%s.name = ? and %s.value %s (%s)", $obj->getTableName, $obj->getFieldName(), $obj->getOperator(), '?' x scalar @values;
  return ( $sql, $obj->getHashKey(), @values );
}
#-----------------------------------------------------------------------------
1;
