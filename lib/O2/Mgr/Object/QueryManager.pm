package O2::Mgr::Object::QueryManager;

use strict;
use base 'O2::Mgr::ObjectManager';

use O2::Obj::Object::Query;

use O2 qw($context);
use O2::Util::List qw(upush);
use B qw(svref_2object);

#-----------------------------------------------------------------------------
sub initModel {
  my ($obj, $model) = @_;
  $obj->SUPER::initModel($model);
  $model->registerFields(
    'O2::Obj::Object::Query',
    # Your class definition goes here:
    #-----------------------------------------------------------------------------
    className         => { type => 'varchar', testValue => 'O2::Obj::Object'                                     }, # We're searching for objects of this class and its sub classes
    conditionGroups   => { type => 'O2::Obj::Object::Query::ConditionGroup', listType => 'array'                 }, # One condition group will be created for each field
    joinWith          => { type => 'varchar', length => '3', defaultValue => 'and', validValues => ['and', 'or'] }, # If the condition groups are going to be joined with 'and' or 'or'
    orderBy           => { type => 'varchar', testValue => 'metaStatus'                                          },
    skip              => { type => 'int'                                                                         },
    limit             => { type => 'int'                                                                         },
    inFolderCondition => { type => 'O2::Obj::Object::Query::Condition'                                           }, # Matching objects must be found in one of the given folders or one of its child/grand-child etc folders.
    searchArchiveToo  => { type => 'bit'                                                                         },
    title             => { type => 'varchar', multilingual => 1                                                  },
    debug             => { type => 'bit'                                                                         },
    unionQuery        => { type => 'O2::Obj::Object::Query'                                                      }, # Object IDs returned from unionQuery will be added to object IDs otherwise gathered by original/parent query.
    #-----------------------------------------------------------------------------
  );
}
#-----------------------------------------------------------------------------
{
  my %seenFields;
  
  sub _getFieldsByName {
    my ($obj, $model, $fieldName, %params) = @_;
    $fieldName = 'metaParentId' if $fieldName eq '-ancestorId';
    my $allowSubClassField = $params{allowSubClassField};
    my $seenFieldsKey = $model->getClassName() . "::$fieldName" . ($allowSubClassField ? '-allowSubClassField' : '');
    
    my @fields = @{  $seenFields{$seenFieldsKey} || []  };
    return @fields if @fields;
    
    my $field = eval { $model->getFieldByName($fieldName) };
    $seenFields{$seenFieldsKey} ||= [];
    if ($field) {
      push $seenFields{$seenFieldsKey}, $field;
      return ($field);
    }
    elsif (!$allowSubClassField) {
      die "Didn't find field '$fieldName'";
    }
    
    my $className = $model->getClassName();
    my $objectIntrospect = $context->getSingleton('O2::Util::ObjectIntrospect');
    $objectIntrospect->setClass($className);
    my @subClassManagers = map { $context->getUniversalMgr()->objectClassNameToManagerClassName($_) } $objectIntrospect->getSubClassesRecursive();
    foreach my $mgrClass (@subClassManagers) {
      my $model = $context->getSingleton($mgrClass)->getModel();
      my $field = eval { $model->getFieldByName($fieldName) } if $model->hasOwnField($fieldName);
      if ($field) {
        push $seenFields{$seenFieldsKey}, $field if $field;
      }
    }
    
    @fields = @{  $seenFields{$seenFieldsKey}  };
    if (@fields) {
      warn sprintf "Didn't find field '$fieldName' in %s, so tried its sub classes and found it in %s", $model->getClassName(), join (', ', map { $_->getModel()->getClassName() } @fields) if $params{debug};
      return @fields;
    }
    
    die "Didn't find field '$fieldName'";
  }
}
#-----------------------------------------------------------------------------
sub _addScalarCondition {
  my ($obj, $conditionGroup, $model, $fieldName, $operator, $value, $isNumericArgument) = @_;
  my $object = $conditionGroup->getQuery();
  my @fields = $obj->_getFieldsByName( $model, $fieldName, debug => $object->getDebug(), allowSubClassField => 1 );
  my $firstField = shift @fields;
  if (@fields) {
    foreach my $field (@fields) {
      my $unionQuery = $object->clone();
      my $unionQueryConditionGroup = [ $unionQuery->getConditionGroups() ]->[-1]; # A little hack..
      $obj->_addScalarConditionII($unionQuery, $unionQueryConditionGroup, $field, $operator, $value, $isNumericArgument);
      $object->addUnionQuery($unionQuery);
    }
  }
  $obj->_addScalarConditionII($object, $conditionGroup, $firstField, $operator, $value, $isNumericArgument);
}
#-----------------------------------------------------------------------------
sub _addScalarConditionII {  
  my ($obj, $object, $conditionGroup, $field, $operator, $value, $isNumericArgument) = @_;
  my $condition = $context->getSingleton('O2::Mgr::Object::Query::Condition::ScalarManager')->newObject();
  $condition->setField(        $field    );
  $condition->setOperator(     $operator );
  $condition->setValue(        $value    );
  $condition->setForceNumeric( 1         ) if $isNumericArgument;
  
  if ($field->getName() eq '-ancestorId') {
    $object->setInFolderCondition($condition);
  }
  else {
    $conditionGroup->addCondition($condition);
  }
}
#-----------------------------------------------------------------------------
sub _addArrayCondition {
  my ($obj, $conditionGroup, $model, $fieldName, $operator, $values) = @_;
  my $object = $conditionGroup->getQuery();
  my @fields = $obj->_getFieldsByName( $model, $fieldName, debug => $object->getDebug(), allowSubClassField => 1 );
  my $firstField = shift @fields;
  if (@fields) {
    foreach my $field (@fields) {
      my $unionQuery = $object->clone();
      my $unionQueryConditionGroup = [ $unionQuery->getConditionGroups() ]->[-1]; # A little hack..
      $obj->_addArrayConditionII($unionQuery, $unionQueryConditionGroup, $field, $operator, $values);
      $object->addUnionQuery($unionQuery);
    }
  }
  $obj->_addArrayConditionII($object, $conditionGroup, $firstField, $operator, $values);
}
#-----------------------------------------------------------------------------
sub _addArrayConditionII {
  my ($obj, $object, $conditionGroup, $field, $operator, $values) = @_;
  my $condition = $context->getSingleton('O2::Mgr::Object::Query::Condition::ArrayManager')->newObject();
  $condition->setField(    $field     );
  $condition->setOperator( $operator  );
  $condition->setValues(   @{$values} );
  
  if ($field->getName() eq '-ancestorId') {
    $object->setInFolderCondition($condition);
  }
  else {
    $conditionGroup->addCondition($condition);
  }
}
#-----------------------------------------------------------------------------
sub _addSubQueryCondition {
  my ($obj, $conditionGroup, $model, $condition, $thisTableFieldName, $otherTableFieldName, $params) = @_;
  my $object = $conditionGroup->getQuery();
  my @fields = $obj->_getFieldsByName( $model, $thisTableFieldName, debug => $object->getDebug(), allowSubClassField => 1 );
  my $firstField = shift @fields;
  if (@fields) {
    foreach my $field (@fields) {
      my $unionQuery = $object->clone();
      my $unionQueryConditionGroup = [ $unionQuery->getConditionGroups() ]->[-1]; # A little hack..
      $obj->_addSubQueryConditionII($unionQuery, $unionQueryConditionGroup, $field, $condition, $otherTableFieldName, $params);
      $object->addUnionQuery($unionQuery);
    }
  }
  $obj->_addSubQueryConditionII($object, $conditionGroup, $firstField, $condition, $otherTableFieldName);
}
#-----------------------------------------------------------------------------
sub _addSubQueryConditionII {
  my ($obj, $object, $conditionGroup, $field, $condition, $otherTableFieldName, $params) = @_;
  
  my $otherClassName = $field->getType();
  die "Not a class name: $otherClassName" if $otherClassName !~ m{ ::Obj:: }xms;
  
  my $otherMgr = $context->getUniversalMgr()->getManagerByClassName($otherClassName);
  my $subQuery = $obj->newObjectBySearchParams( $otherMgr, $otherTableFieldName => $condition, -debug => $object->getDebug() );
  $conditionGroup->addSubQueryCondition($field, 'in', $subQuery);
  
  # We may not have gone through all the search parameters before calling clone, so we must make sure to include the remaining parameters also:
  my $mgr = $context->getSingleton( $object->getManagerClassName() );
  $obj->_addConditionGroups(  $object, $mgr, %{ $params || {} }  ) if $params && %{$params};
}
#-----------------------------------------------------------------------------
sub newObjectBySearchParams {
  my ($obj, $mgr, %params) = @_;
  die "First parameter to 'newObjectBySearchParams' should be a manager object" if !ref ($mgr) || ref ($mgr) !~ m{ ::Mgr:: }xms;
  
  $params{metaStatus} ||= { notIn => [ qw(trashed trashedAncestor deleted) ] } if !$params{objectId} && !delete $params{isEitherQuery};
  $obj->validateSearchFields($mgr, %params);
  $obj->isaToMetaClassNameIn(\%params);
  
  my $object = $obj->newObject();
  $object->setClassNameByManagerClassName(ref $mgr);
  $object->setSkip(             delete $params{-skip}    ) if exists $params{-skip};
  $object->setLimit(            delete $params{-limit}   ) if exists $params{-limit};
  $object->setOrderBy(          delete $params{-orderBy} ) if exists $params{-orderBy};
  $object->setSearchArchiveToo( 1                        ) if delete $params{-searchArchiveToo};
  $object->setDebug(            1                        ) if delete $params{-debug};
  
  $obj->_addConditionGroups($object, $mgr, %params);
  return $object;
}
#-----------------------------------------------------------------------------
sub _addConditionGroups {
  my ($obj, $object, $mgr, %params) = @_;
  my %unprocessedParams = %params;
  my $model = $mgr->getModel();
  
  # Going through fields:
  while (my ($name, $condition) = each %params) {
    delete $unprocessedParams{$name};
    my $conditionRef   = ref $condition;
    my $conditionGroup = $object->newConditionGroup();
    
    if (my ($thisTableFieldName, $otherTableFieldName) = $name =~ m{ \A (.+?) -> (.*) \z }xms) { # 'abc->def' => $value
      $obj->_addSubQueryCondition($conditionGroup, $model, $condition, $thisTableFieldName, $otherTableFieldName, \%unprocessedParams);
    }
    elsif ($conditionRef eq 'HASH') { # 'abc' => { %conditions }
      if ($name eq '-either') {
        my $subQuery = $obj->newObjectBySearchParams( $mgr, %{$condition}, isEitherQuery => 1 );
        $subQuery->setJoinWith('or');
        $conditionGroup->addEitherSubQueryCondition($subQuery);
      }
      else {
        # Going through conditions for the field:
        while (my ($operator, $value) = each %{$condition}) {
          my $isNumericArgument = $obj->isNumericByRef(  ref svref_2object( \$condition->{$operator} )  );
          my $valueRef = ref $value;
          if ($operator eq '-either') {
            my $eitherConditionField = $model->getFieldByName($name);
            $conditionGroup->setJoinWith('or');
            foreach my $eitherCondition (@{$value}) {
              my ($eitherConditionOperator, $eitherConditionValue) = %{$eitherCondition};
              my $eitherConditionIsNumericArgument = $obj->isNumericByRef(  ref svref_2object( \$eitherCondition->{$eitherConditionOperator} )  );
              $conditionGroup->addScalarCondition($eitherConditionField, $obj->getSqlOperator($eitherConditionOperator), $eitherConditionValue, $eitherConditionIsNumericArgument);
            }
          }
          elsif (my ($fieldName, $hashKey) = $name =~ m[ (\w+)  { (\w+) } \z ]xms) { # 'abc{def}' => { %conditions }
            my ($field) = $obj->_getFieldsByName( $model, $fieldName, debug => $object->getDebug() );
            $operator = $obj->getSqlOperator($operator);
            $conditionGroup->addHashCondition($field, $hashKey, $operator, $value, $isNumericArgument);
          }
          elsif ($valueRef eq 'ARRAY') { # Ex: 'abc' => { in => [ @values ] }
            $operator = $obj->getSqlOperator($operator);
            $obj->_addArrayCondition($conditionGroup, $model, $name, $operator, $value);
          }
          else { # 'abc' => $value
            $operator = $obj->getSqlOperator($operator);
            $obj->_addScalarCondition($conditionGroup, $model, $name, $operator, $value, $isNumericArgument);
          }
        }
      }
    }
    elsif ($conditionRef =~ m{ ::Obj:: }xms) { # 'abc' => $object
      my $isNumericArgument = $obj->isNumericByRef(  ref svref_2object( \$params{$name} )  );
      my $valueObject = $condition;
      die "No objectId" unless $valueObject->getId();
      if (my ($fieldName, $hashKey) = $name =~ m[ (\w+)  { (\w+) } \z ]xms) { # 'abc{def}' => $object
        my ($field) = $obj->_getFieldsByName( $model, $fieldName, debug => $object->getDebug() );
        $conditionGroup->addHashCondition( $field, $hashKey, '=', $valueObject->getId(), $isNumericArgument );
      }
      else { # 'abc' => $object
        $obj->_addScalarCondition( $conditionGroup, $model, $name, '=', $valueObject->getId() );
      }
    }
    elsif (!$conditionRef) { # 'abc' => $value
      my $isNumericArgument = $obj->isNumericByRef(  ref svref_2object( \$params{$name} )  );
      if (my ($fieldName, $hashKey) = $name =~ m[ (\w+)  { (\w+) } \z ]xms) { # 'abc{def}' => $value
        my ($field) = $obj->_getFieldsByName( $model, $fieldName, debug => $object->getDebug() );
        $conditionGroup->addHashCondition($field, $hashKey, '=', $condition, $isNumericArgument);
      }
      else { # 'abc' => $value
        $obj->_addScalarCondition($conditionGroup, $model, $name, '=', $condition, $isNumericArgument);
      }
    }
  }
}
#-----------------------------------------------------------------------------
sub updateObjectBySearchParams {
  my ($obj, $query, %searchParams) = @_;
  
  my $meta = $query->{_metaObject};
  my $id   = $query->getId();
  
  my $mgr = $context->getUniversalMgr()->getManagerByClassName( $query->getClassName() );
  $query  = $obj->newObjectBySearchParams($mgr, %searchParams);
  
  %{ $query->{_metaObject} } = %{$meta};
  $query->setId($id);
  
  return $query;
}
#-----------------------------------------------------------------------------
sub validateSearchFields {
  my ($obj, $mgr, %params) = @_;
  my $model = $mgr->getModel();
  foreach my $fieldName (keys %params) {
    next if $fieldName =~ m[ -either | -limit | -skip | -orderBy | -debug | -isa | -ancestorId | -searchArchiveToo | -> | {\w+} ]xms;
    
    $fieldName = 'id' if $fieldName eq 'objectId';
    die "Invalid field '$fieldName' in objectSearch or objectIdSearch" unless $obj->_getFieldsByName( $model, $fieldName, debug => $params{-debug}, allowSubClassField => 1 );
  }
  return 1;
}
#-----------------------------------------------------------------------------
sub getSqlOperator {
  my ($obj, $operator) = @_;
  return '='           if $operator eq '='  || $operator eq 'eq';
  return '<'           if $operator eq '<'  || $operator eq 'lt';
  return '<='          if $operator eq '<=' || $operator eq 'le';
  return '>'           if $operator eq '>'  || $operator eq 'gt';
  return '>='          if $operator eq '>=' || $operator eq 'ge';
  return '!='          if $operator eq '!=' || $operator eq 'ne' || $operator eq '<>';
  return 'in'          if $operator eq 'in';
  return 'like'        if $operator eq 'like';
  return 'not like'    if $operator eq 'not like'    || $operator eq 'notLike';
  return 'not in'      if $operator eq 'not in'      || $operator eq 'notIn';
  return 'is null'     if $operator eq 'is null'     || $operator eq 'isNull';
  return 'is not null' if $operator eq 'is not null' || $operator eq 'isNotNull';
  return $operator     if $operator eq 'eqAll'       || $operator eq 'likeAll' || $operator eq 'likeAny';
  die "Invalid operator: $operator";
}
#-----------------------------------------------------------------------------
sub isaToMetaClassNameIn {
  my ($obj, $params) = @_;
  if ($params->{-isa}) {
    my $isaClass = delete $params->{-isa};
    my $objectIntrospect = $context->getSingleton('O2::Util::ObjectIntrospect');
    $objectIntrospect->setClass($isaClass);
    my @inClasses = ( $isaClass, $objectIntrospect->getSubClassesRecursive() );
    upush @inClasses, @{ $params->{metaClassName}->{in} || [] };
    $params->{metaClassName}->{in} = \@inClasses;
  }
}
#-----------------------------------------------------------------------------
sub isNumericByRef {
  my ($obj, $ref) = @_;
  return $ref eq 'B::IV' || $ref eq 'B::NV'; # Looks like IV is integer and NV is float
}
#-----------------------------------------------------------------------------
sub save {
  my ($obj, $object) = @_;
  $object->setMetaName('Query') unless $object->getMetaName();
  $obj->SUPER::save($object);
}
#-----------------------------------------------------------------------------
1;
