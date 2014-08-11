package O2::Obj::Object::Query::Condition::SubQuery;

use strict;
use base 'O2::Obj::Object::Query::Condition';

use O2::Util::List qw(upush);

#-----------------------------------------------------------------------------
sub getSql {
  my ($obj) = @_;
  my $subQuery = $obj->getQuery();
  my ($subSql, @placeHolders) = $subQuery->getSql();
  my $sql;
  if ($obj->getListType() eq 'none') {
    $sql = sprintf "%s.%s %s ($subSql)", $obj->getTableName(), $obj->getFieldName(), $obj->getOperator();
  }
  elsif ($obj->getListType() eq 'array') {
    $sql = sprintf "%s.name like ? and %s.value %s ($subSql)", $obj->getTableName(), $obj->getTableName(), $obj->getOperator();
    unshift @placeHolders, $obj->getFieldName() . '.%'
  }
  return ($sql, @placeHolders);
}
#-----------------------------------------------------------------------------
sub deletePermanently {
  my ($obj) = @_;
  $obj->getQuery()->deletePermanently();
  $obj->SUPER::deletePermanently();
}
#-----------------------------------------------------------------------------
sub delete {
  my ($obj) = @_;
  $obj->getQuery()->delete();
  $obj->SUPER::delete();
}
#-----------------------------------------------------------------------------
1;
