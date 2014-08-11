package O2::DB::Util::Introspect::Index;

use strict;

#--------------------------------------------------------------------------------
sub new {
  my ($pkg, %params) = @_;
  foreach my $dataName (qw/indexName type/) {
    die "No $dataName supplied" unless exists $params{$dataName};
  }
  return bless \%params, $pkg;
}
#--------------------------------------------------------------------------------
sub indexName { # Deprecated
  my ($obj) = @_;
  return $obj->getName();
}
#--------------------------------------------------------------------------------
sub getName {
  my ($obj) = @_;
  return $obj->{indexName};
}
#--------------------------------------------------------------------------------
sub getColumnName {
  my ($obj) = @_;
  return $obj->{columnName};
}
#--------------------------------------------------------------------------------
sub type { # Deprecated
  my ($obj) = @_;
  return $obj->getType();
}
#--------------------------------------------------------------------------------
sub getType {
  my ($obj) = @_;
  return $obj->{type};
}
#--------------------------------------------------------------------------------
sub getColumnNames {
  my ($obj) = @_;
  return wantarray  ?  @{ $obj->{columnNames} }  :  $obj->{columnNames};
}
#--------------------------------------------------------------------------------
sub isUnique {
  my ($obj) = @_;
  return $obj->{isUnique};
}
#--------------------------------------------------------------------------------
sub isPrimaryKey {
  my ($obj) = @_;
  return $obj->getName() eq 'PRIMARY';
}
#--------------------------------------------------------------------------------
sub isSameIndexAs {
  my ($obj, $otherIndex) = @_;
  return 0 if $obj->isUnique() != $otherIndex->isUnique();
  my @otherIndexColumns = $otherIndex->getColumnNames();
  my @thisIndexColumns  = $obj->getColumnNames();
  return 0 if @otherIndexColumns != @thisIndexColumns;
  for my $i (0 .. $#thisIndexColumns) {
    # It's not the same index if the column names are the same, but in different order
    return 0 if $thisIndexColumns[$i] ne $otherIndexColumns[$i];
  }
  return 1;
}
#--------------------------------------------------------------------------------
1;
