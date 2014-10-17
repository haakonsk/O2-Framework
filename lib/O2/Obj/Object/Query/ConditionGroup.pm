package O2::Obj::Object::Query::ConditionGroup;

use strict;
use base 'O2::Obj::Object';

use O2 qw($context);
use O2::Util::List qw(upush);

#-----------------------------------------------------------------------------
sub getQuery {
  my ($obj) = @_;
  return $obj->{query} if $obj->{query};
  
  die "Can't find query object. Condition group not saved." unless $obj->getId();
  
  my ($id) = $context->getSingleton('O2::Mgr::Object::QueryManager')->objectIdSearch(
    conditionGroups => $obj->getId(),
  );
  die "Can't find query object" unless $id;
  return $obj->{query} = $context->getObjectById($id) or die "Can't find query object: Couldn't instantiate $id";
}
#-----------------------------------------------------------------------------
sub addEitherSubQueryCondition {
  my ($obj, $subQuery) = @_;
  my $idField = $obj->getManager()->getModel()->getFieldByName('id');
  $obj->addSubQueryCondition($idField, 'in', $subQuery);
}
#-----------------------------------------------------------------------------
sub addSubQueryCondition {
  my ($obj, $field, $operator, $subQuery) = @_;
  my $condition = $context->getSingleton('O2::Mgr::Object::Query::Condition::SubQueryManager')->newObject();
  $condition->setField(    $field    );
  $condition->setOperator( $operator );
  $condition->setQuery(    $subQuery );
  $obj->addCondition($condition);
}
#-----------------------------------------------------------------------------
sub addHashCondition {
  my ($obj, $field, $hashKey, $operator, $value, $isNumericArgument) = @_;
  my $condition = $context->getSingleton('O2::Mgr::Object::Query::Condition::Hash::' . (ref $value ? 'Multi' : 'Single') . 'ValueManager')->newObject();
  $condition->setField(    $field    );
  $condition->setHashKey(  $hashKey  );
  $condition->setOperator( $operator );
  if (ref $value) {
    $condition->setValues( @{$value} );
  }
  else {
    $condition->setValue(        $value );
    $condition->setForceNumeric( 1      ) if $isNumericArgument;
  }
  $obj->addCondition($condition);
}
#-----------------------------------------------------------------------------
sub addScalarCondition {
  my ($obj, $field, $operator, $value, $isNumericArgument) = @_;
  my $condition = $context->getSingleton('O2::Mgr::Object::Query::Condition::ScalarManager')->newObject();
  $condition->setField(        $field    );
  $condition->setOperator(     $operator );
  $condition->setValue(        $value    );
  $condition->setForceNumeric( 1         ) if $isNumericArgument;
  $obj->addCondition($condition);
}
#-----------------------------------------------------------------------------
sub addCondition {
  my ($obj, $condition) = @_;
  my @conditions = $obj->getConditions();
  $obj->setConditions(@conditions, $condition);
}
#-----------------------------------------------------------------------------
sub getSql {
  my ($obj) = @_;
  my $sql = '';
  my (@placeHolders, @subSqls);
  foreach my $condition ($obj->getConditions()) {
    my ($_sql, @_placeHolders) = $condition->getSql();
    push @subSqls,      $_sql;
    push @placeHolders, @_placeHolders;
  }
  $sql = join ( ' ' . $obj->getJoinWith() . ' ', @subSqls );
  $sql = "($sql)" if @subSqls > 1;
  return ($sql, @placeHolders);
}
#-----------------------------------------------------------------------------
sub getUsedTables {
  my ($obj) = @_;
  my @tableNames;
  foreach my $condition ($obj->getConditions()) {
    upush @tableNames, $condition->getUsedTables();
  }
  return @tableNames;
}
#-----------------------------------------------------------------------------
sub deletePermanently {
  my ($obj) = @_;
  foreach my $condition ($obj->getConditions()) {
    $condition->deletePermanently();
  }
  $obj->SUPER::deletePermanently();
}
#-----------------------------------------------------------------------------
sub delete {
  my ($obj) = @_;
  foreach my $condition ($obj->getConditions()) {
    $condition->delete();
  }
  $obj->SUPER::delete();
}
#-----------------------------------------------------------------------------
1;
