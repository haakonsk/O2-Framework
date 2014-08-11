package O2::DB::Util::Introspect;

use strict;

use O2 qw($context $config);

#--------------------------------------------------------------------------------
sub new {
  my ($pkg, %params) = @_;
  return bless {}, $pkg;
}
#--------------------------------------------------------------------------------
sub getTables {
  my ($obj, $pattern) = @_;

  $pattern =~ s/\*/.*/g;

  my $dbh = $context->getDbh()->getDbh(); # Grab the DBI-dbh

  my @tableNames;
  my $sth = $dbh->table_info('%', '', '%', 'TABLE');
  $sth->execute();
  my $tableInfos = $sth->fetchall_arrayref( {} );
  @tableNames = map { $_->{TABLE_NAME} } @{$tableInfos};

  my @tables;
  require O2::DB::Util::Introspect::Table;
  foreach my $tableName (@tableNames) {
    next unless $tableName =~ m/^$pattern/;
    push @tables, O2::DB::Util::Introspect::Table->new( tableName => $tableName );
  }
  return @tables;
}
#--------------------------------------------------------------------------------
sub getTable {
  my ($obj, $tableName) = @_;
  foreach my $table ($obj->getTables($tableName)) {
    return $table if $table->tableName() eq $tableName;
  }
  return;
}
#--------------------------------------------------------------------------------
sub tableExists {
  my ($obj, $tableName) = @_;
  foreach my $table ($obj->getTables($tableName)) {
    return 1 if $table->tableName() eq $tableName;
  }
  return 0;
}
#--------------------------------------------------------------------------------
sub getCharacterSet {
  return $context->getDbh()->fetch( "select default_character_set_name from information_schema.SCHEMATA where schema_name = ?", $config->get('o2.database.dataSource') );
}
#--------------------------------------------------------------------------------
sub getCollation {
  return $context->getDbh()->fetch( "select default_collation_name from information_schema.SCHEMATA where schema_name = ?", $config->get('o2.database.dataSource') );
}
#--------------------------------------------------------------------------------
1;

__END__

    COLUMN_NAME: The column identifier.

    DATA_TYPE: The concise data type code.

    TYPE_NAME: A data source dependent data type name.

    COLUMN_SIZE: The column size. This is the maximum length in characters for character data types, the number of digits or bits for numeric data types or the length in the representation of temporal types. See the relevant specifications for detailed information.

    BUFFER_LENGTH: The length in bytes of transferred data.

    DECIMAL_DIGITS: The total number of significant digits to the right of the decimal point.

    NUM_PREC_RADIX: The radix for numeric precision. The value is 10 or 2 for numeric data types and NULL (undef) if not applicable.

    NULLABLE: Indicates if a column can accept NULLs. The following values are defined:

      SQL_NO_NULLS          0
      SQL_NULLABLE          1
      SQL_NULLABLE_UNKNOWN  2

    REMARKS: A description of the column.

    COLUMN_DEF: The default value of the column.

    SQL_DATA_TYPE: The SQL data type.

    SQL_DATETIME_SUB: The subtype code for datetime and interval data types.

    CHAR_OCTET_LENGTH: The maximum length in bytes of a character or binary data type column.

    ORDINAL_POSITION: The column sequence number (starting with 1).

    IS_NULLABLE: Indicates if the column can accept NULLs. Possible values are: 'NO', 'YES' and ''.

    SQL/CLI defines the following additional columns:

      CHAR_SET_CAT
      CHAR_SET_SCHEM
      CHAR_SET_NAME
      COLLATION_CAT
      COLLATION_SCHEM
      COLLATION_NAME
      UDT_CAT
      UDT_SCHEM
      UDT_NAME
      DOMAIN_CAT
      DOMAIN_SCHEM
      DOMAIN_NAME
      SCOPE_CAT
      SCOPE_SCHEM
      SCOPE_NAME
      MAX_CARDINALITY
      DTD_IDENTIFIER
      IS_SELF_REF

    Drivers capable of supplying any of those values should do so in the corresponding column and supply undef values for the others.

    Drivers wishing to provide extra database/driver specific information should do so in extra columns beyond all those listed above, and use lowercase field names with the driver-specific prefix (i.e., 'ora_...'). Applications accessing such fields should do so by name and not by column number.

    The result set is ordered by TABLE_CAT, TABLE_SCHEM, TABLE_NAME and ORDINAL_POSITION.

    Note: There is some overlap with statement attributes (in perl) and SQLDescribeCol (in ODBC). However, SQLColumns provides more metadata.

    See also "Catalog Methods" and "Standards Reference Information".
