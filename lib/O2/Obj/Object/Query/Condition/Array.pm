package O2::Obj::Object::Query::Condition::Array;

use strict;
use base 'O2::Obj::Object::Query::Condition';

#-----------------------------------------------------------------------------
sub getSql {
  my ($obj) = @_;
  
  my $tableName = $obj->getTableName();
  my $fieldName = $obj->getFieldName();
  my $operator  = $obj->getOperator();
  
  my @values = $obj->getValues();
  die "Don't know how to handle array condition when there aren't any elements in the array. Field name: $fieldName, operator: $operator" unless @values;
  
  my ($sql, @placeHolders);
  my @questionMarks = map { '?' } @values;
  
  if ($obj->getListType() eq 'array') {
    if ($operator eq 'eqAll' && @values >= 2) {
      $sql = "select objectId from $tableName where name like ? and value = ?";
      push @placeHolders, "$fieldName.%", shift @values;
      my $lastValue = pop @values;
      foreach my $value (@values) {
        $sql = "select objectId from $tableName where $tableName.objectId in ($sql) and $tableName.name like ? and $tableName.value = ?";
        push @placeHolders, "$fieldName.%", $value;
      }
      $sql = "$tableName.objectId in ($sql) and $tableName.name like ? and $tableName.value = ?";
      push @placeHolders, "$fieldName.%", $lastValue;
    }
    elsif ($operator eq 'likeAll' || $operator eq 'likeAny') {
      $sql  = "($tableName.name like ? and ";
      $sql .= '(' if $operator eq 'likeAny';
      push @placeHolders, "$fieldName.%";
      my @sqls;
      foreach my $value (@values) {
        push @sqls, "$tableName.value like ?";
        push @placeHolders, $value;
      }
      $sql .= join  ' or ', @sqls if $operator eq 'likeAny';
      $sql .= join ' and ', @sqls if $operator eq 'likeAll';
      $sql .= ')' if $operator eq 'likeAny';
      $sql .= ')';
    }
    else {
      $operator = 'in' if $operator eq 'eqAll';
      $sql = sprintf "($tableName.name like ? and $tableName.value $operator (%s))", join ', ', @questionMarks;
      @placeHolders = ( "$fieldName.%", @values );
    }
  }
  else {
    if ($operator eq 'likeAny' || $operator eq 'likeAll') {
      my @sqls;
      foreach my $value (@values) {
        push @sqls, "$tableName.$fieldName like ?";
        push @placeHolders, $value;
      }
      $sql = join  ' or ', @sqls if $operator eq 'likeAny';
      $sql = join ' and ', @sqls if $operator eq 'likeAll';
      $sql = "($sql)" if @values >= 2;
    }
    else {
      $operator = 'in' if $operator eq 'eqAll';
      $sql = sprintf "$tableName.$fieldName $operator (%s)", join ', ', @questionMarks;
      @placeHolders = @values;
    }
  }
  
  return ($sql, @placeHolders);
}
#-----------------------------------------------------------------------------
1;
