package O2::Obj::Object::Query::Condition::Scalar;

use strict;
use base 'O2::Obj::Object::Query::Condition';

#-----------------------------------------------------------------------------
sub getSql {
  my ($obj) = @_;
  my $tableName = $obj->getTableName();
  my $value     = $obj->getValue();
  my $operator  = $obj->getOperator();
  my $fieldName = $obj->getFieldName();
  my ($sql, @placeHolders);
  
  if ($obj->getListType() eq 'array') {
    if (my ($sign, $number) = $value =~ m{ \A time ([+-]) (\d+) \z }xms) {
      $sql = "$tableName.name like ? and $tableName.value $operator unix_timestamp() $sign ?";
      @placeHolders = ($fieldName . '.%', $number);
    }
    else {
      $sql = "($tableName.name like ? and $tableName.value $operator ?)";
      @placeHolders = ($fieldName . '.%', $value);
    }
  }
  else {
    if (my ($sign, $number) = $value =~ m{ \A time ([+-]) (\d+) \z }xms) {
      $sql = "$tableName.$fieldName $operator unix_timestamp() $sign ?";
      @placeHolders = ($number);
    }
    else {
      my $sqlValue = $obj->getSqlQuestionMarkValue($operator, $value);
      $sql = "$tableName.$fieldName $operator " . (defined $sqlValue ? $sqlValue : '');
      @placeHolders = ($value) if defined $sqlValue;
    }
  }
  
  return ($sql, @placeHolders);
}
#-----------------------------------------------------------------------------
sub getValues {
  my ($obj) = @_;
  my @values = ( $obj->getValue() );
  return wantarray ? @values : \@values;
}
#-----------------------------------------------------------------------------
1;
