package O2::DB::Util::Introspect::Table;

use strict;

use O2 qw($context $db $config);
use O2::Util::List qw(upush);

#--------------------------------------------------------------------------------
sub new {
  my ($pkg, %params) = @_;
  die "No tableName supplied" unless $params{tableName};
  return bless { tableName => $params{tableName} }, $pkg;
}
#--------------------------------------------------------------------------------
sub tableName {
  my ($obj) = @_;
  return $obj->getName();
}
#--------------------------------------------------------------------------------
sub getName {
  my ($obj) = @_;
  return $obj->{tableName};
}
#--------------------------------------------------------------------------------
sub getColumns {
  my ($obj, $pattern) = @_;
  $pattern = '' unless length $pattern;
  $pattern =~ s/\*/.*/g;
  
  my $dbh = $db->getDbh();
  
  my %primaryKeys = map { $_ => 1 } $obj->getPrimaryKeyColumnNames();
  
  my $columnInfos;
  my @columns;
  my $sth = $dbh->column_info(undef, undef, $obj->tableName(), '%');
  $sth->execute();
  $columnInfos = $sth->fetchall_arrayref( {} );
 COLUMN:
  foreach my $column ( $db->fetchAll('desc ' . $obj->tableName()) ) {
    foreach my $columnInfo (@{$columnInfos}) {
      if ($columnInfo->{COLUMN_NAME} eq $column->{Field}) {
        $columnInfo->{IS_AUTO_INCREMENT}  =  ($column->{Extra} =~ m{ auto_increment }xms )  ?  1  :  0;
        next COLUMN;
      }
    }
  }
  require O2::DB::Util::Introspect::Column;
  foreach my $columnInfo (sort { $a->{ORDINAL_POSITION} <=> $b->{ORDINAL_POSITION} } @{ $columnInfos }) {
    next if $columnInfo->{COLUMN_NAME} !~ m{ \A $pattern }xms;
    
    push @columns, O2::DB::Util::Introspect::Column->new(
      columnName    => $columnInfo->{COLUMN_NAME},
      nullable      => $columnInfo->{IS_NULLABLE} eq 'NO' ? 0 : 1,
      size          => $columnInfo->{COLUMN_SIZE},
      dataType      => $columnInfo->{TYPE_NAME},
      autoIncrement => $columnInfo->{IS_AUTO_INCREMENT} ? 1 : 0,
      defaultValue  => $columnInfo->{COLUMN_DEF},
      primaryKey    => $primaryKeys{ $columnInfo->{COLUMN_NAME} } || 0,
    );
  }
  return @columns;
}
#--------------------------------------------------------------------------------
sub _updateIndexes {
  my ($obj, $indexes, $indexName, $columnName, $type, $position, $isUnique) = @_;
  if ($indexes->{$indexName}) {
    $indexes->{$indexName}->{columnNames}->[$position] = $columnName;
  }
  else {
    require O2::DB::Util::Introspect::Index;
    my $index = O2::DB::Util::Introspect::Index->new(
      indexName  => $indexName,
      type       => $type,
      columnName => $columnName,
      isUnique   => $isUnique,
    );
    $index->{columnNames} = [];
    $index->{columnNames}->[$position] = $columnName;
    $indexes->{$indexName} = $index;
  }
}
#--------------------------------------------------------------------------------
sub getIndexes {
  my ($obj, $pattern) = @_;
  $pattern = '' unless defined $pattern;
  $pattern =~ s/\*/.*/g;
  
  if (!$obj->{indexes} || !@{ $obj->{indexes} }) { # Caching
    my %indexes;
    my $dbh = $db->getDbh(); # Grab the DBI-dbh
    
    my @indexRows = $db->fetchAll( 'show index from ' . $obj->tableName() );
    foreach my $indexRow (@indexRows) {
      next if !$indexRow->{Key_name} || $indexRow->{Key_name} !~ m{ \A $pattern }xms;
      $obj->_updateIndexes( \%indexes, $indexRow->{Key_name}, $indexRow->{Column_name}, $indexRow->{Index_type}, $indexRow->{Seq_in_index}-1, !$indexRow->{Non_unique} );
    }
    $obj->{indexes} = [ values %indexes ];
  }
  return @{ $obj->{indexes} };
}
#--------------------------------------------------------------------------------
# If the column is part of an index
sub hasIndexOnColumn {
  my ($obj, $column) = @_;
  my $columnName = ref $column ? $column->getName() : $column;
  foreach my $index ($obj->getIndexes()) {
    foreach my $colName ($index->getColumnNames()) {
      return 1 if $colName eq $columnName;
      return 1 if $obj->getName() eq 'O2_OBJ_OBJECT'  &&  'meta' . ucfirst($colName) eq $columnName;
    }
  }
  return 0;
}
#--------------------------------------------------------------------------------
sub hasIndexName {
  my ($obj, $indexName) = @_;
  foreach my $index ($obj->getIndexes()) {
    return 1 if $index->getName() eq $indexName;
  }
  return 0;
}
#--------------------------------------------------------------------------------
# If there's an index on the column, and that column is the first (most significant) column in the index
sub hasPrimaryIndexOnColumn {
  my ($obj, $field) = @_;
  my $columnName = ref $field ? $field->getName() : $field;
  foreach my $index ($obj->getIndexes()) {
    my $colName = [ $index->getColumnNames() ]->[0];
    return 1 if $colName eq $columnName;
    if ($obj->getName() eq 'O2_OBJ_OBJECT') {
      return 1 if 'meta' . ucfirst($colName) eq $columnName;
      return 1 if $columnName eq 'id' && $colName eq 'objectId';
    }
  }
  return 0;
}
#--------------------------------------------------------------------------------
sub getColumn {
  my ($obj, $columnName) = @_;
  my @columns = $obj->getColumns($columnName . '\z');
  return scalar(@columns) ? $columns[0] : undef;
}
#--------------------------------------------------------------------------------
sub hasColumn {
  my ($obj, $columnName) = @_;
  my @columns = $obj->getColumns();
  foreach my $column (@columns) {
    return 1 if $column->getName() eq $columnName;
  }
  return 0;
}
#--------------------------------------------------------------------------------
sub getPrimaryKeyColumnNames {
  my ($obj) = @_;
  my $dbh = $db->getDbh(); # Grab the DBI-dbh
  my @columnNames = $dbh->primary_key( undef, undef, $obj->tableName() );
  my @columns = $db->fetchAll('desc ' . $obj->tableName());
  foreach my $column (@columns) {
    upush @columnNames, $column->{Field} if $column->{Key} =~ m{ pri }xmsi;
  }
  return @columnNames;
}
#--------------------------------------------------------------------------------
sub getCharacterSet {
  my ($obj) = @_;
  return $db->fetch(
    "select CCSA.character_set_name from information_schema.`TABLES` t, information_schema.`COLLATION_CHARACTER_SET_APPLICABILITY` CCSA where CCSA.collation_name = t.table_collation and t.table_schema = ? and TABLE_NAME = ?",
    $config->get('o2.database.dataSource'), $obj->getName(),
  );
}
#--------------------------------------------------------------------------------
sub getCollation {
  my ($obj) = @_;
  return $db->fetch(
    "select CCSA.collation_name from information_schema.`TABLES` t, information_schema.`COLLATION_CHARACTER_SET_APPLICABILITY` CCSA where CCSA.collation_name = t.table_collation and t.table_schema = ? and TABLE_NAME = ?",
    $config->get('o2.database.dataSource'), $obj->getName(),
  );
}
#--------------------------------------------------------------------------------
1;
