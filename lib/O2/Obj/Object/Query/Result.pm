package O2::Obj::Object::Query::Result;

use strict;

use O2 qw($context $db);
use O2::Util::List qw(upush);

#-----------------------------------------------------------------------------
sub new {
  my ($package, $mgr, $query) = @_;
  my $obj = bless {}, $package;
  $obj->{mgr}   = $mgr;
  $obj->{query} = $query;
  return $obj;
}
#-----------------------------------------------------------------------------
sub getObjectIds {
  my ($obj) = @_;
  $obj->_performSearch() unless exists $obj->{ids};
  return @{ $obj->{ids} };
}
#-----------------------------------------------------------------------------
sub getObjects {
  my ($obj) = @_;
  $obj->_performSearch() unless exists $obj->{ids};
  return $context->getObjectsByIds( $obj->getObjectIds() );
}
#-----------------------------------------------------------------------------
sub getCount {
  my ($obj) = @_;
  return scalar @{ $obj->{ids} } if exists $obj->{ids};
  return $obj->{query}->getCount();
}
#-----------------------------------------------------------------------------
sub getMin {
  my ($obj, $fieldName) = @_;
  return $obj->{query}->getMin($fieldName);
}
#-----------------------------------------------------------------------------
sub getMax {
  my ($obj, $fieldName) = @_;
  return $obj->{query}->getMax($fieldName);
}
#-----------------------------------------------------------------------------
sub getDistinct {
  my ($obj, $fieldName) = @_;
  return $obj->{query}->getDistinct($fieldName);
}
#-----------------------------------------------------------------------------
sub getAll {
  my ($obj, @fieldNames) = @_;
  $obj->_performSearch() unless exists $obj->{ids};
  my $method = @fieldNames == 1 ? 'selectColumn' : 'fetchAll';
  return $db->$method( $obj->_getGetSql(@fieldNames), $obj->{ids} );
}
#-----------------------------------------------------------------------------
sub getOne {
  my ($obj, @fieldNames) = @_;
  $obj->_performSearch() unless exists $obj->{ids};
  return $db->fetch( $obj->_getGetSql(@fieldNames), $obj->{ids} );
}
#-----------------------------------------------------------------------------
sub search {
  my ($obj, %params) = @_;
  $obj->_performSearch() unless exists $obj->{ids};
  return $obj->{mgr}->search(
    %params,
    objectId => { in => $obj->{ids} },
  );
}
#-----------------------------------------------------------------------------
sub _getFieldByName {
  my ($obj, $fieldName) = @_;
  return $obj->{mgr}->getModel()->getFieldByName($fieldName) or die "Couldn't call model->getFieldByName($fieldName)";
}
#-----------------------------------------------------------------------------
sub _getFieldsByNames {
  my ($obj, @fieldNames) = @_;
  my @fields;
  foreach my $fieldName (@fieldNames) {
    push @fields, $obj->_getFieldByName($fieldName);
  }
  return @fields;
}
#-----------------------------------------------------------------------------
sub _getGetSql {
  my ($obj, @fieldNames) = @_;
  my @fields = $obj->_getFieldsByNames(@fieldNames);
  
  my (@tableNames, @fieldAndTableNames);
  foreach my $field (@fields) {
    my $tableName = $field->getTableName();
    my $fieldName = $field->getName();
    $fieldName    = 'objectId'                    if $fieldName eq 'id'                && $tableName eq 'O2_OBJ_OBJECT';
    $fieldName    =~ s{ \A meta (\w) }{lc $1}xmse if $fieldName =~ m{ \A meta(\w) }xms && $tableName eq 'O2_OBJ_OBJECT';
    upush @tableNames, $tableName;
    push  @fieldAndTableNames, "$tableName.$fieldName";
  }
  
  # Join on objectId:
  my $joinSql = '';
  for (my $i = 0; $i < $#tableNames; $i++) {
    $joinSql .= 'and ' if $i > 0;
    $joinSql .= "$tableNames[$i].objectId = $tableNames[$i+1].objectId ";
  }
  $joinSql .= 'and' if $joinSql;
  
  return 'select ' . join (', ', @fieldAndTableNames) . ' from ' . join (', ', @tableNames) . " where $joinSql $tableNames[0].objectId in (??)";
}
#-----------------------------------------------------------------------------
sub _performSearch {
  my ($obj) = @_;
  $obj->{ids} = [ $obj->{query}->getObjectIds() ];
}
#-----------------------------------------------------------------------------
1;
