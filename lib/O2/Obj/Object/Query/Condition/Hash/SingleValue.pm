package O2::Obj::Object::Query::Condition::Hash::SingleValue;

use strict;
use base 'O2::Obj::Object::Query::Condition::Hash';

#-----------------------------------------------------------------------------
sub getSql {
  my ($obj) = @_;
  my $tableName = $obj->getTableName();
  my $value     = $obj->getValue();
  my $sqlValue  = $obj->getSqlQuestionMarkValue( $obj->getOperator() , $value );
  my $sql       = sprintf "$tableName.name = ? and $tableName.value %s $sqlValue", $obj->getOperator();
  my @values = ( $obj->getFieldName() . '.' . $obj->getHashKey() );
  push @values, $value if defined $sqlValue;
  return ($sql, @values);
}
#-----------------------------------------------------------------------------
sub getValues {
  my ($obj) = @_;
  my @values = ( $obj->getValue() );
  return wantarray ? @values : \@values;
}
#-----------------------------------------------------------------------------
1;
