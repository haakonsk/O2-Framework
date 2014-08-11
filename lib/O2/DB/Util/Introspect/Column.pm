package O2::DB::Util::Introspect::Column;

use strict;

use O2 qw($context $db);

#--------------------------------------------------------------------------------
sub new {
  my ($pkg, %params) = @_;
  foreach my $dataName ( qw(columnName nullable size dataType primaryKey defaultValue) ) {
    die "No $dataName supplied" unless exists $params{$dataName};
  }
  return bless \%params, $pkg;
}
#--------------------------------------------------------------------------------
sub getName {
  my ($obj) = @_;
  return $obj->{columnName};
}
#--------------------------------------------------------------------------------
sub getDataType {
  my ($obj) = @_;
  return lc $obj->{dataType};
}
#--------------------------------------------------------------------------------
# No default values here
sub getSpecifiedSize {
  my ($obj) = @_;
  return $obj->{size};
}
#--------------------------------------------------------------------------------
sub getSize {
  my ($obj) = @_;
  return undef if $obj->getDataType() eq 'double'; # At least mysql doesn't understand f ex double(60)
  return $obj->{size} if $obj->{size};
  return  11 if $obj->getDataType() eq 'int';
  return 255 if $obj->getDataType() eq 'varchar';
  return undef;
}
#--------------------------------------------------------------------------------
sub isNullable {
  my ($obj) = @_;
  return $obj->{nullable} ? 1 : 0;
}
#--------------------------------------------------------------------------------
sub isPrimaryKey {
  my ($obj) = @_;
  return $obj->{primaryKey} || $obj->{autoIncrement} ? 1 : 0;
}
#--------------------------------------------------------------------------------
sub isAutoIncrement {
  my ($obj) = @_;
  return $obj->{autoIncrement} ? 1 : 0;
}
#--------------------------------------------------------------------------------
sub getDefaultValue {
  my ($obj) = @_;
  return $obj->{defaultValue};
}
#--------------------------------------------------------------------------------
1;
