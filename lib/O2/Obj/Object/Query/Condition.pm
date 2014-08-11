package O2::Obj::Object::Query::Condition;

use strict;
use base 'O2::Obj::Object';

#-----------------------------------------------------------------------------
sub setFieldName {
  my ($obj, $fieldName) = @_;
  $fieldName =~ s{ \A meta (\w) }{lc $1}xmse;
  $fieldName = 'objectId' if $fieldName eq 'id';
  $obj->setModelValue('fieldName', $fieldName);
}
#-----------------------------------------------------------------------------
sub setField {
  my ($obj, $field) = @_;
  $obj->setFieldName( $field->getName()      );
  $obj->setTableName( $field->getTableName() );
  $obj->setListType(  $field->getListType()  );
}
#-----------------------------------------------------------------------------
sub getUsedTables {
  my ($obj) = @_;
  return $obj->getTableName();
}
#-----------------------------------------------------------------------------
sub getSqlQuestionMarkValue {
  my ($obj, $operator, $value) = @_;
  return     if $operator =~ m{ \A is }xms; # There's no value for "is null" or "is not null"
  return '?' if $operator eq '=' && $value =~ m{ \A \d+ \z }xms; # Not necessary to cast in this situation
  return $obj->getForceNumeric($value) ? "CAST(? as decimal)" : '?';
}
#-----------------------------------------------------------------------------
1;
