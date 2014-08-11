package O2::Model::Target::Sql;

use strict;

use base 'O2::Model::Target';

use O2 qw($context $config);

#-------------------------------------------------------------------------------
sub generate {
  my ($obj, $model) = @_;
  $obj->say("Generate sql");

  my $sql = $obj->generateSql($model);
  print $sql if $obj->getArg('print');
  if ($obj->ask("Do you want to create/update tables in the database (y/N) ?") eq 'y') {
    $obj->createTable($sql);
  }

  my $testMaker = $context->getSingleton('O2::Model::Target::Test');
  $testMaker->setArgs( %{ $obj->{args} } );
  my $testPath  = $testMaker->getTestScriptPath($model);
  $testMaker->generate($model) if !-e $testPath && lc ($obj->ask("There are no tests for this class. Do you want to create one (y/N)? ")) eq 'y';
}
#-------------------------------------------------------------------------------
sub createTable {
  my ($obj, $sql) = @_;

  my $schemaMgr = $context->getSingleton('O2::DB::Util::SchemaManager');
  $schemaMgr->updateTableFromSql($sql);

  print "Tables created/updated in database\n";
}
#-------------------------------------------------------------------------------
sub generateSql {
  my ($obj, $model) = @_;

  my $className = $model->getClassName();
  my $tableName = uc $obj->pathifyClassName($className, '_');
  my $sql = "create table $tableName (\n";
  $sql   .= "  objectId int not null primary key,\n";

  foreach my $field ($model->getTableFieldsByClassName($className)) {
    next if $field->isMetaField();
    $sql .= sprintf "  `%s` %s", $field->getName(), $obj->sqlDataType($field);
    $sql .= '(' . $field->getLength() . ')'                if $field->getLength() && $sql !~ m{ \( \d+ \) \z }xms && $sql !~ m{ \( \d+,\s*\d+ \) \z }xms; # XXX Do we need this line at all
    $sql .= ' not null'                                    if $field->getNotNull();
    $sql .= " default '" . $field->getDefaultValue() . "'" if length $field->getDefaultValue();
    $sql .= ",\n";
  }
  $sql .= sprintf ") ENGINE=InnoDB DEFAULT CHARSET=%s DEFAULT COLLATE=%s;\n", $config->get('o2.database.characterSet'), $config->get('o2.database.collation');
  $sql  =~ s{  , \s+ \)  }{\)}xms;
  return $sql;
}
#-------------------------------------------------------------------------------
sub sqlDataType {
  my ($obj, $field) = @_;
  my $dataType = $field->getType();
  if ($field->getType() eq 'varchar') {
    my $length = $field->getLength() || 255;
    $dataType = "varchar($length)";
  }
  elsif ($field->getType() eq 'epoch'  ||  $field->isObjectType()) {
    $dataType = 'int';
    $dataType .= '(' . $field->getLength() . ')' if $field->getLength();
  }
  elsif ($field->getType() eq 'date') {
    $dataType = 'datetime';
  }
  elsif ($field->getType() eq 'bit') {
    $dataType = 'tinyint(1)';
  }
  else {
    $dataType .= '(' . $field->getLength() . ')' if $field->getLength();
  }
  return $dataType;
}
#-------------------------------------------------------------------------------
sub changeField {
  my ($obj, $field) = @_;
}
#-------------------------------------------------------------------------------

1;
