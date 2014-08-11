package O2::DB::Util::SchemaManager;

use strict;

use O2 qw($context $db $config);

#--------------------------------------------------------------------------------
sub new {
  my ($pkg, %params) = @_;
  return bless {}, $pkg;
}
#--------------------------------------------------------------------------------
sub createTable {
  my ($obj, %table) = @_;

  my $query = "create table $table{name} ( ";
  my @primaryKeys;
  foreach my $column (@{ $table{columns} }) {
    $query .= $obj->_getColumnDefinition(
      columnName => $column->{name},
      %{$column},
    );
    $query .= ', ';
    push @primaryKeys, $column->{name} if $column->{primaryKey} || $column->{autoIncrement};
  }
  $query
    = @primaryKeys
    ? $query . $obj->getPrimaryKeysSql(@primaryKeys)
    : substr $query, 0, -2
    ;
  $query .= sprintf ") ENGINE=InnoDB DEFAULT CHARSET=%s DEFAULT COLLATE=%s", $config->get('o2.database.characterSet'), $config->get('o2.database.dbCollation');
  return $obj->_performSql($query);
}
#--------------------------------------------------------------------------------
sub renameTable {
  my ($obj, $oldTableName, $newTableName) = @_;
  return $obj->_performSql("rename table $oldTableName to $newTableName");
}
#--------------------------------------------------------------------------------
sub dropTable {
  my ($obj, $tableName) = @_;
  return $obj->_performSql("drop table $tableName");
}
#--------------------------------------------------------------------------------
sub addColumn { # Note: Not allowed to add a primary key column if there's already a column that is auto_increment.
  my ($obj, %params) = @_;
  foreach ( qw(tableName columnName type) ) {
    die "Missing required parameter $_" unless $params{$_};
  }
  my $table = $obj->_getTable( $params{tableName} );
  my @primaryKeys = $params{primaryKey} || $params{autoIncrement} ? ($params{columnName}) : ();
  foreach my $column ($table->getColumns()) {
    push @primaryKeys, $column->getName() if $column->isPrimaryKey();
  }
  $db->startTransaction();
  $obj->_performSql( "alter table $params{tableName} add " . $obj->_getColumnDefinition(%params) );
  $obj->_fixPrimaryKeys($table, @primaryKeys);
  $db->endTransaction();
  return 1;
}
#--------------------------------------------------------------------------------
sub renameColumn {
  my ($obj, $tableName, $oldColumnName, $newColumnName, $sql) = @_;
  my $query;
  $query = "alter table $tableName ";
  my $table  = $obj->_getTable($tableName);
  my $column = $sql ? $obj->_getColumnFromSql($newColumnName, $sql) : $table->getColumn($oldColumnName);
  die "Couldn't rename column $oldColumnName to $newColumnName in $tableName. sql: $sql" unless $column;
  
  $query .= "change `$oldColumnName` " . $obj->_getColumnDefinition(
    $obj->_getColumnParams($tableName, $column),
    columnName => $newColumnName,
  );
  return $obj->_performSql($query);
}
#--------------------------------------------------------------------------------
sub alterColumn {
  my ($obj, %params) = @_;
  my $tableName  = $params{tableName};
  my $columnName = $params{columnName};
  my $column = $obj->_getTable($tableName)->getColumn($columnName);
  
  %params = ( $obj->_getColumnParams($tableName, $column), %params );
  return $obj->_performSql( "alter table $tableName modify " . $obj->_getColumnDefinition(%params) );
}
#--------------------------------------------------------------------------------
sub dropColumn {
  my ($obj, $tableName, $columnName) = @_;
  return $obj->_performSql("alter table $tableName drop column `$columnName`");
}
#--------------------------------------------------------------------------------
sub addIndex {
  my ($obj, $tableName, $indexName, $columnNames, $isUnique) = @_;
  return unless @{$columnNames};
  
  $obj->_performSql("create " . ($isUnique ? 'unique' : '') . " index `$indexName` on $tableName (`" . join ('`, `', @{$columnNames}) . '`)');
  return 1;
}
#--------------------------------------------------------------------------------
sub changeIndex {
  my ($obj, $tableName, $indexName, $columnNames, $isUnique) = @_;
  $obj->dropIndex($tableName, $indexName);
  return $obj->addIndex($tableName, $indexName, $columnNames, $isUnique);
}
#--------------------------------------------------------------------------------
sub dropIndex {
  my ($obj, $tableName, $indexName) = @_;
  $obj->_performSql("drop index `$indexName` on $tableName");
  return 1;
}
#--------------------------------------------------------------------------------
sub dropPrimaryKeys {
  my ($obj, $tableName) = @_;
  if ($obj->_getTable($tableName)->getPrimaryKeyColumnNames()) {
    return $obj->_performSql("alter table $tableName drop primary key");
  }
  return 1; # No primary key to delete
}
#--------------------------------------------------------------------------------
sub addPrimaryKeys {
  my ($obj, $tableName, @primaryKeys) = @_;
  return unless @primaryKeys;
  return $obj->_performSql("alter table $tableName add primary key (" . join(', ', @primaryKeys) . ')');
}
#--------------------------------------------------------------------------------
sub getPrimaryKeysSql {
  my ($obj, @primaryKeys) = @_;
  return 'primary key (' . join(', ', @primaryKeys) . ')';
}
#--------------------------------------------------------------------------------
sub createTableForClass {
  my ($obj, $className) = @_;
  my $model = $obj->_getModel($className);
  my $sql = $obj->_getCreateTableSqlFromModel($model);
  $obj->_performSql($sql);
  $obj->updateIndexesFromModel($model);
}
#--------------------------------------------------------------------------------
sub updateTableForClass {
  my ($obj, $className, %params) = @_;
  my $model = $obj->_getModel($className);
  my $sql = $obj->_getCreateTableSqlFromModel($model);
  $obj->updateTableFromSql($sql, %params);
  $obj->updateIndexesFromModel($model, %params);
}
#--------------------------------------------------------------------------------
sub _getModel {
  my ($obj, $className) = @_;
  return $context->getSingleton('O2::Model::Generator')->getModel($className);
}
#--------------------------------------------------------------------------------
sub _getCreateTableSqlFromModel {
  my ($obj, $model) = @_;
  my $target = $context->getSingleton('O2::Model::Generator')->instantiateClass('O2::Model::Target::Sql');
  return $target->generateSql($model);
}
#--------------------------------------------------------------------------------
sub updateTableFromSql {
  my ($obj, $sql, %params) = @_;
  return unless $sql;
  
  my ($tableName) = $sql =~ m{ \A \s* create \s+ table (?: \s+ if \s+ not \s+ exists)? \s+ ([^\s]+?)  \s* \(}xmsi;
  die "Didn't find tablename in create table query: $sql" unless $tableName;
  
  my $table = $obj->_getTable($tableName);
  return $obj->_performSql($sql) unless $table;
  
  my @modelColumns = $obj->_getColumnsFromSql($sql);
  
  # Delete columns that are not in the definition
  foreach my $dbColumn ($table->getColumns()) {
    my $foundColumn = 0;
    foreach my $modelColumn (@modelColumns) {
      if ($dbColumn->getName() eq $modelColumn->getName()) {
        $foundColumn = 1;
      }
      elsif ( lc ($dbColumn->getName())  eq  lc ($modelColumn->getName()) ) { # Differs in upper-/lowercasing
        loginfo 'Renaming column "' . $dbColumn->getName() . '" to "' . $modelColumn->getName() . "\" in table $tableName";
        $obj->renameColumn($tableName, $dbColumn->getName(), $modelColumn->getName(), $sql);
        printf "Renamed column %s to %s in table $tableName\n", $dbColumn->getName(), $modelColumn->getName() if $params{printChangesToStdOut};
        $foundColumn = 1;
      }
    }
    if (!$foundColumn && $params{okToDrop}) {
      warning 'Dropping column "' . $dbColumn->getName() . "\" in table $tableName";
      # XXX Create backup of the dropped data
      $obj->dropColumn( $tableName, $dbColumn->getName() );
      printf "Dropped column %s in table $tableName\n", $dbColumn->getName() if $params{printChangesToStdOut};
    }
  }
  
  # Add or alter columns
  my @newPrimaryKeys;
  my @autoIncrementColumns;
  foreach my $modelColumn (@modelColumns) {
    my %columnParams = $obj->_getColumnParams($tableName, $modelColumn);
    push @newPrimaryKeys,       $modelColumn->getName() if $modelColumn->isPrimaryKey();
    push @autoIncrementColumns, $modelColumn->getName() if $modelColumn->isAutoIncrement();
    if ($table->hasColumn( $modelColumn->getName() )) {
      my $dbColumn = $table->getColumn( $modelColumn->getName() );
      my $dataTypeModel = $modelColumn->getDataType();
      my $dataTypeDb    = $dbColumn->getDataType();
      my $changeStr = '';
      $changeStr .= sprintf "-DataType changed from '%s' to '%s'\n",   $dataTypeDb,                  $dataTypeModel                  if $dataTypeModel                  ne $dataTypeDb;
      $changeStr .= sprintf "-Nullable changed from %d to %d\n",       $dbColumn->isNullable(),      $modelColumn->isNullable()      if $modelColumn->isNullable()      ne $dbColumn->isNullable();
      $changeStr .= sprintf "-Auto-increment changed from %d to %d\n", $dbColumn->isAutoIncrement(), $modelColumn->isAutoIncrement() if $modelColumn->isAutoIncrement() ne $dbColumn->isAutoIncrement();
      $changeStr .= sprintf "-Is primary key changed from %d to %d\n", $dbColumn->isPrimaryKey(),    $modelColumn->isPrimaryKey()    if $modelColumn->isPrimaryKey()    ne $dbColumn->isPrimaryKey();
      
      my $defaultValueModel = $modelColumn->getDefaultValue();
      my $defaultValueDb    = $dbColumn->getDefaultValue();
      $defaultValueModel    = '' unless defined $defaultValueModel;
      $defaultValueDb       = '' unless defined $defaultValueDb;
      if (  ( $defaultValueModel ne $defaultValueDb || length ($defaultValueModel) != length ($defaultValueDb)                       )
        && !( $dbColumn->isPrimaryKey() && length ($defaultValueDb) == 1 && $defaultValueDb == 0 && length ($defaultValueModel) == 0 )
      ) {
        $changeStr .= sprintf "-Default value changed from '%s' to '%s'\n", $defaultValueDb, $defaultValueModel;
      }
      
      if ( $modelColumn->getSpecifiedSize() && $dbColumn->getSize() && $modelColumn->getSpecifiedSize() ne $dbColumn->getSize() ) {
        $changeStr .= sprintf "-Size changed from '%s' to '%s'\n", $dbColumn->getSpecifiedSize(), $modelColumn->getSpecifiedSize() if $dataTypeModel ne 'float' && $dataTypeModel ne 'double';
      }
      
      if ($changeStr) {
        $changeStr = sprintf "Altered column '%s' in table $tableName:\n$changeStr", $modelColumn->getName();
        $obj->alterColumn(%columnParams) or die "Error altering column $dbColumn in $tableName: $@";
        print $changeStr if $params{printChangesToStdOut};
        loginfo $changeStr;
      }
    }
    else {
      $obj->addColumn(%columnParams) or die "Error adding column: $@";
      loginfo 'Added column "' . $modelColumn->getName() . "\" to table $tableName", %columnParams;
      printf "Added column %s in table $tableName\n", $modelColumn->getName() if $params{printChangesToStdOut};
    }
  }
  $obj->_fixPrimaryKeys($table, @newPrimaryKeys);
  foreach my $columnName (@autoIncrementColumns) {
    $obj->_setColumnToAutoIncrement($tableName, $columnName);
  }
}
#--------------------------------------------------------------------------------
# If an index exists in the database, but with a different name than it's defined with in initModel, then we keep that index,
# since it's not possible to rename indexes without dropping and recreating the index, which is very time consuming.
sub updateIndexesFromModel {
  my ($obj, $model, %params) = @_;
  my $tableName = $model->getTableName();
  my $table = $obj->_getTable($tableName);
  my @modelIndexes = $model->getIndexes( $model->getClassName() );

  # Delete indexes that are not defined in initModel
  foreach my $dbIndex ($table->getIndexes()) {
    next if $dbIndex->isPrimaryKey();
    
    my $foundIndexInModel = 0;
  MODEL_INDEX:
    foreach my $modelIndex (@modelIndexes) {
      next unless $modelIndex->isSameIndexAs($dbIndex);
      $foundIndexInModel = 1;
    }
    if (!$foundIndexInModel) {
      # Delete index from database
      printf "Deleting index '%s' from table '$tableName'\n", $dbIndex->getName() if $params{printChangesToStdOut};
      $obj->dropIndex( $tableName, $dbIndex->getName() );
    }
  }

  # Add new indexes
 MODEL_INDEX2:
  foreach my $modelIndex (@modelIndexes) {
    foreach my $dbIndex ($table->getIndexes()) {
      next MODEL_INDEX2 if $modelIndex->isSameIndexAs($dbIndex);
    }
    printf "Adding index '%s' for table '$tableName'\n", $modelIndex->getName() if $params{printChangesToStdOut};
    $obj->addIndex( $tableName, $modelIndex->getName(), [ $modelIndex->getColumnNames() ], $modelIndex->isUnique() );
  }
}
#--------------------------------------------------------------------------------
sub _getColumnParams {
  my ($obj, $tableName, $column) = @_;
  return (
    tableName     => $tableName,
    columnName    => $column->getName(),
    type          => $column->getDataType(),
    length        => $column->getSize(),
    nullable      => $column->isNullable(),
    autoIncrement => $column->isAutoIncrement(),
    defaultValue  => $column->getDefaultValue(),
    primaryKey    => $column->isPrimaryKey(),
  );
}
#--------------------------------------------------------------------------------
sub _getColumnFromSql {
  my ($obj, $columnName, $query) = @_;
  foreach my $column ($obj->_getColumnsFromSql($query)) {
    return $column if $column->getName() eq $columnName;
  }
  die "Didn't find column '$columnName' in sql ($query)";
}
#--------------------------------------------------------------------------------
sub _getColumnsFromSql {
  my ($obj, $query) = @_;
  my ($columnStrings) = $query =~ m{ \A \s* create \s+ table (?: \s+ if \s+ not \s+ exists)? \s+ .+?  \(   (.+)   \)  }xmsi;
  my @columnStrings = split /\n/, $columnStrings; # XXX Probably safer to split on comma and look out for things like Identity(1,1)
  my @columns;
  require O2::DB::Util::Introspect::Column;
  foreach my $columnString (@columnStrings) {
    $columnString =~ s{ \A \s+ }{}xmsg;
    $columnString =~ s{ \s+ \z }{}xmsg;
    next unless $columnString;
    
    my ($columnName, $dataType, $size) = $columnString =~ m{ \A \s*  `? ([^\s]+?) `?  \s+  ([^\s\(,]+) \s*  (?:  \( (.+?) \)  )?   }xms;
    next if $size && $size ne int $size;
    next if $dataType !~ m{ \A (?:tiny|small|medium|big)?int | integer | real | double | float | double | decimal | numeric | date(?:time)? | time(?:stamp)? | year | (?:var)?char | (?:var)?binary | (?:tiny|medium|long)? (?:blob|text) | enum | set \z }xmsi;
    
    my $isPrimaryKey = ($columnString =~ m{ primary \s+ key }xmsi)   ||   ($query =~ m{ primary \s+ key \s* \( [^()]*? \b $columnName \b .*? \) }xmsi);
    my $autoIncrement = $columnString =~ m{ auto_increment }xmsi;
    my  $nullable      = !$isPrimaryKey && !$autoIncrement && $columnString !~ m{ not \s+ null }xmsi;
    my ($defaultValue) = $columnString =~ m{ default \s+ '? ([^']+) '? }xmsi;
    push @columns, O2::DB::Util::Introspect::Column->new(
      columnName    => $columnName,
      nullable      => $nullable,
      size          => $size,
      dataType      => $dataType,
      primaryKey    => $isPrimaryKey,
      autoIncrement => $autoIncrement,
      defaultValue  => $defaultValue,
    );
  }
  return @columns;
}
#--------------------------------------------------------------------------------
sub _performSql {
  my ($obj, $sql, @placeHolders) = @_;
  return $db->sql($sql, @placeHolders); # This may die, and then it will be up to the calling code to handle it.
}
#--------------------------------------------------------------------------------
sub _getColumnDefinition {
  my ($obj, %params) = @_;
  if ($params{type} eq 'bit') { # We've had some problems with "bit" columns
    $params{type}   = 'tinyint';
    $params{length} = 1;
  }
  my $sql = "`$params{columnName}` $params{type}";
  $sql   .= "($params{length})" if $params{length} && $params{type} ne 'datetime';
  if (!$params{primaryKey}) {
    $sql .= " not" if defined $params{nullable} && !$params{nullable};
    $sql .= " null";
  }
  $sql .= " auto_increment"                  if $params{autoIncrement};
  $sql .= " default '$params{defaultValue}'" if length $params{defaultValue};
  return $sql;
}
#--------------------------------------------------------------------------------
sub _fixPrimaryKeys {
  my ($obj, $table, @newPrimaryKeys) = @_;
  my $tableName = $table->tableName();
  my @oldPrimaryKeys = $table->getPrimaryKeyColumnNames();
  if (!$obj->_arraysContainTheSameElements(\@newPrimaryKeys, \@oldPrimaryKeys, ignoreCase => 1)) {
    eval {
      $obj->dropPrimaryKeys($tableName);
    };
    if ($@) {
      warn "Couldn't drop primary keys for $tableName. Aborting primary key update. Existing primary key: " . join (', ', @oldPrimaryKeys) . ", new primary key: " . join (', ', @newPrimaryKeys);
      return;
    }
    $obj->addPrimaryKeys($tableName, @newPrimaryKeys);
  }
}
#--------------------------------------------------------------------------------
sub _arraysContainTheSameElements {
  my ($obj, $array1, $array2, %params) = @_;
  return 0 if scalar ( @{$array1} ) != scalar ( @{$array2} );
  
  my (@array1, @array2);
  if ($params{ignoreCase}) {
    @array1 = map  { lc $_ }  @{ $array1 };
    @array2 = map  { lc $_ }  @{ $array2 };
  }
  else {
    @array1 = @{ $array1 };
    @array2 = @{ $array2 };
  }
  @array1 = sort { $a cmp $b } @array1;
  @array2 = sort { $a cmp $b } @array2;
  for my $i (0 .. scalar (@array1)-1) {
    return 0 if $array1[$i] ne $array2[$i];
  }
  return 1;
}
#--------------------------------------------------------------------------------
sub _setColumnToAutoIncrement {
  my ($obj, $tableName, $columnName) = @_;
  my $table  = $obj->_getTable($tableName);
  my $column = $table->getColumn($columnName);
  return if $column->isAutoIncrement();
  
  $obj->alterColumn(
    tableName     => $tableName,
    columnName    => $columnName,
    autoIncrement => 1,
  );
}
#--------------------------------------------------------------------------------
sub _getTable {
  my ($obj, $tableName) = @_;
  return $context->getSingleton('O2::DB::Util::Introspect')->getTable($tableName);
}
#--------------------------------------------------------------------------------
sub alterCharacterSetForDatabase {
  my ($obj, $characterSet, %params) = @_;
  my $dbName = $config->get('o2.database.dataSource');
  $db->do("alter database $dbName character set $characterSet");
}
#--------------------------------------------------------------------------------
sub alterCharacterSetForTable {
  my ($obj, $tableName, $characterSet, %params) = @_;
  $db->do("alter table $tableName character set $characterSet");
}
#--------------------------------------------------------------------------------
sub alterCollationForDatabase {
  my ($obj, $collation, %params) = @_;
  my $dbName = $config->get('o2.database.dataSource');
  $db->do("alter database $dbName collate $collation");
}
#--------------------------------------------------------------------------------
sub alterCollationForTable {
  my ($obj, $tableName, $collation, %params) = @_;
  $db->do("alter table $tableName collate $collation");
}
#--------------------------------------------------------------------------------
1;
