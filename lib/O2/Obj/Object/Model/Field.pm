package O2::Obj::Object::Model::Field;

use strict;

use O2::Util::List qw(contains);

#-----------------------------------------------------------------------------
sub new {
  my ($pkg, %params) = @_;
  return bless {
    model => $params{model},
    data  => $params{field},
  }, $pkg;
}
#-----------------------------------------------------------------------------
sub getFieldInfo {
  my ($obj) = @_;
  return $obj->{data};
}
#-----------------------------------------------------------------------------
sub setName {
  my ($obj, $name) = @_;
  $obj->{data}->{name} = $name;
}
#-----------------------------------------------------------------------------
sub getName {
  my ($obj) = @_;
  return $obj->{data}->{name};
}
#-----------------------------------------------------------------------------
sub getTableFieldName {
  my ($obj) = @_;
  my $fieldName = $obj->getName();
  return $fieldName unless $obj->isMetaField();
  return 'objectId'     if $fieldName eq 'id';
  
  $fieldName =~ s{ \A meta (\w) }{lc $1}xmse;
  return $fieldName;
}
#-----------------------------------------------------------------------------
sub setSingularName {
  my ($obj, $singularName) = @_;
  $obj->{data}->{singularName} = $singularName;
}
#-----------------------------------------------------------------------------
sub getSingularName {
  my ($obj) = @_;
  return $obj->{data}->{singularName};
}
#-----------------------------------------------------------------------------
sub setPluralName {
  my ($obj, $pluralName) = @_;
  $obj->{data}->{pluralName} = $pluralName;
}
#-----------------------------------------------------------------------------
sub getPluralName {
  my ($obj) = @_;
  return $obj->{data}->{pluralName} || $obj->{data}->{name};
}
#-----------------------------------------------------------------------------
sub setType {
  my ($obj, $type) = @_;
  $obj->{data}->{type} = $type;
}
#-----------------------------------------------------------------------------
sub getType {
  my ($obj) = @_;
  return $obj->{data}->{type} || '';
}
#-----------------------------------------------------------------------------
sub setLength {
  my ($obj, $length) = @_;
  $obj->{data}->{length} = $length;
}
#-----------------------------------------------------------------------------
sub getLength {
  my ($obj) = @_;
  return $obj->{data}->{length};
}
#-----------------------------------------------------------------------------
sub isObjectType {
  my ($obj) = @_;
  return $obj->getType() eq 'object'  ||  $obj->getType() =~ m{ :: }xms;
}
#-----------------------------------------------------------------------------
sub isFloatingPointType {
  my ($obj) = @_;
  return $obj->getType() eq 'float' || $obj->getType() eq 'double' || $obj->getType() eq 'decimal';
}
#-----------------------------------------------------------------------------
sub isTextType {
  my ($obj) = @_;
  my $type = $obj->getType();
  return $type eq 'text' || $type eq 'mediumtext' || $type eq 'longtext';
}
#-----------------------------------------------------------------------------
sub isNumericType {
  my ($obj) = @_;
  my $type = $obj->getType();
  return $obj->isFloatingPointType() || $type eq 'bit' || $type eq 'int' || $type eq 'tinyint' || $type eq 'epoch';
}
#-----------------------------------------------------------------------------
sub setListType {
  my ($obj, $listType) = @_;
  $obj->{data}->{listType} = $listType;
}
#-----------------------------------------------------------------------------
sub getListType {
  my ($obj, $dontReturnNone) = @_;
  return '' if ( !$obj->{data}->{listType} || $obj->{data}->{listType} eq 'none')  &&  $dontReturnNone;
  return $obj->{data}->{listType};
}
#-----------------------------------------------------------------------------
sub isMetaField {
  my ($obj) = @_;
  return 0 if $obj->getClassName() ne 'O2::Obj::Object';
  return $obj->getName() eq 'id' || $obj->getName() =~ m{ \A meta }xms;
}
#-----------------------------------------------------------------------------
sub setMultilingual {
  my ($obj, $multilingual) = @_;
  $obj->{data}->{multilingual} = $multilingual;
}
#-----------------------------------------------------------------------------
sub getMultilingual {
  my ($obj) = @_;
  return $obj->{data}->{multilingual} || 0;
}
#-----------------------------------------------------------------------------
sub isMultilingual {
  my ($obj) = @_;
  return $obj->getMultilingual();
}
#-----------------------------------------------------------------------------
sub setNotNull {
  my ($obj, $notNull) = @_;
  $obj->{data}->{notNull} = $notNull;
}
#-----------------------------------------------------------------------------
sub getNotNull {
  my ($obj) = @_;
  return $obj->{data}->{notNull} || 0;
}
#-----------------------------------------------------------------------------
sub setClassName {
  my ($obj, $className) = @_;
  $obj->{data}->{className} = $className;
}
#-----------------------------------------------------------------------------
sub getClassName {
  my ($obj) = @_;
  return $obj->{data}->{className};
}
#-----------------------------------------------------------------------------
sub setDefaultValue {
  my ($obj, $defaultValue) = @_;
  $obj->{data}->{defaultValue} = $defaultValue;
}
#-----------------------------------------------------------------------------
sub getDefaultValue {
  my ($obj) = @_;
  return $obj->{data}->{defaultValue};
}
#-----------------------------------------------------------------------------
sub getGetAccessor {
  my ($obj) = @_;
  if ($obj->getType() eq 'bit' && $obj->getName() =~ m{ (?: is | has) (\w) }xms && $1 eq uc $1) {
    return $obj->getName();
  }
  return 'get' . ucfirst $obj->getName();
}
#-----------------------------------------------------------------------------
sub getSetAccessor {
  my ($obj) = @_;
  return 'set' . ucfirst $obj->getName();
}
#-----------------------------------------------------------------------------
sub getIdSetAccessor {
  my ($obj) = @_;
  die "Can only call method getIdSetAccessor on object type fields" unless $obj->isObjectType();
  my $setter = 'set' . ucfirst $obj->getName();
  if ($setter !~ m{ Ids \z }xms && $obj->getListType() ne 'none') {
    $setter =~ s{ ies \z }{y}xms;
    $setter =~ s{   s \z }{}xms;
    return $setter . 'Ids';
  }
  if ($setter !~ m{ Id \z }xms && $obj->getListType() eq 'none') {
    return $setter . 'Id';
  }
  return $setter;
}
#-----------------------------------------------------------------------------
sub getIdGetAccessor {
  my ($obj) = @_;
  my $getter = $obj->getIdSetAccessor();
  $getter    =~ s{ \A set }{get}xms;
  return $getter;
}
#-----------------------------------------------------------------------------
sub getObjectGetAccessor {
  my ($obj) = @_;
  die "Can only call method getObjectGetAccessor on object type fields" unless $obj->isObjectType();
  my $setter = 'get' . ucfirst $obj->getName();
  $setter = $obj->getModel()->getManager()->_removeIds($setter) if $setter =~ m{ Ids? \z }xms;
  return $setter;
}
#-----------------------------------------------------------------------------
sub getObjectSetAccessor {
  my ($obj) = @_;
  my $getter = $obj->getObjectGetAccessor();
  $getter    =~ s{ \A get }{set}xms;
  return $getter;
}
#-----------------------------------------------------------------------------
# returns true field may contain several values
sub isListField {
  my ($obj) = @_;
  return ($obj->{data}->{multilingual} || $obj->{data}->{listType} ne 'none') && !$obj->isMetaField();
}
#-----------------------------------------------------------------------------
# returns true if field should be stored in the class table
sub isTableField {
  my ($obj) = @_;
  return !$obj->{data}->{multilingual} && $obj->{data}->{listType} eq 'none' && !$obj->isMetaField();
}
#-----------------------------------------------------------------------------
sub getValidValues {
  my ($obj) = @_;
  return @{ $obj->{data}->{validValues} || [] };
}
#-----------------------------------------------------------------------------
sub setValidValues {
  my ($obj, @validValues) = @_;
  $obj->{data}->{validValues} = \@validValues;
}
#-----------------------------------------------------------------------------
sub getComment {
  my ($obj) = @_;
  $obj->_updateComments();
  return $obj->{data}->{comment} if $obj->{data}->{comment};
}
#-----------------------------------------------------------------------------
sub setComment {
  my ($obj, $comment) = @_;
  $obj->_updateComments();
  $obj->{data}->{comment} = $comment;
}
#-----------------------------------------------------------------------------
sub _updateComments {
  my ($obj) = @_;
  return if $obj->{commentsAreRead};
  
  $obj->{commentsAreRead} = 1;
  $obj->getModel()->importFieldComments( $obj->getClassName() );
}
#-----------------------------------------------------------------------------
sub getModel {
  my ($obj) = @_;
  return $obj->{model};
}
#-----------------------------------------------------------------------------
sub getListTableName {
  my ($obj) = @_;
  my $type = $obj->getType();
  return 'O2_OBJ_OBJECT_TEXT'    if $obj->isTextType();
  return 'O2_OBJ_OBJECT_VARCHAR' if $type eq 'varchar' || $type eq 'char';
  return 'O2_OBJ_OBJECT_INT'     if $type eq 'int'     || $type eq 'epoch';
  return 'O2_OBJ_OBJECT_DATE'    if $type eq 'date';
  return 'O2_OBJ_OBJECT_FLOAT'   if $type eq 'float'   || $type eq 'decimal' || $type eq 'double';
  return 'O2_OBJ_OBJECT_BIT'     if $type eq 'bit';
  return 'O2_OBJ_OBJECT_OBJECT'  if $obj->isObjectType();
  die sprintf "Didn't find list table for field '%s' of type '$type'", $obj->getName();
}
#-----------------------------------------------------------------------------
# In which database table do we find this field?
sub getTableName {
  my ($obj) = @_;
  return $obj->getListTableName() if $obj->isListField();
  
  my $className = $obj->getClassName();
  my $tableName = uc $className;
  $tableName    =~ s{ :: }{_}xmsg;
  return $tableName;
}
#-----------------------------------------------------------------------------
sub validateValidValues {
  my ($obj, @values) = @_;
  my @validValues = $obj->getValidValues() or return;
  foreach my $value (@values) {
    if ($value && @validValues && !contains(@validValues, $value)) {
      die sprintf "Value of '%s' ($value) not among valid values: %s", $obj->getName(), join (', ', @validValues);
    }
  }
}
#-----------------------------------------------------------------------------
sub getTestValue {
  my ($obj) = @_;
  return "'$obj->{data}->{testValue}'" if $obj->{data}->{testValue};
  return ' $newObj->getManager()->' . $obj->{data}->{testValueMethod} . '() ' if $obj->{data}->{testValueMethod};
  return '';
}
#-----------------------------------------------------------------------------
1;
