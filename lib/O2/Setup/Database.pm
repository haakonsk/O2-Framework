package O2::Setup::Database;

use strict;

use base 'O2::Setup';

use O2 qw($context $config);

#---------------------------------------------------------------------
sub install {
  my ($obj) = @_;
  $obj->createDatabase();
  $obj->createTables();
  return 1;
}
#---------------------------------------------------------------------
sub createDatabase {
  my ($obj, $dbName, $customer, $dbPassword, $dbCollation) = @_;
  my $setupConf = $obj->getSetupConf();
  $customer                ||= $setupConf->{customer};
  $dbName                  ||= $config->get('o2.database.dataSource') || "o2_$customer";
  $setupConf->{dbpassword} ||= $config->get('o2.database.password')   || $context->getSingleton('O2::Util::Password')->generatePassword(8);
  $dbCollation             ||= $config->get('o2.database.collation')  || $setupConf->{dbCollation};
  my $user    = "'$customer'" . '@' . "'localhost'";
  my $charSet = $config->get('o2.database.characterSet');

  # Create main database:
  my $sql = <<END;
create database $dbName
  default character set $charSet
  default collate $dbCollation;
GRANT SELECT, INSERT, UPDATE, DELETE, CREATE, ALTER, DROP, INDEX ON $dbName.* TO $user IDENTIFIED BY '$setupConf->{dbpassword}';
END
  $obj->executeSql($sql, $setupConf || { customer => $customer });
  print "Created database $dbName\n" if $obj->verbose();

  # Create archive database:
  $dbName = "${dbName}_archive";
  $sql = <<END;
create database $dbName
  default character set $charSet
  default collate $dbCollation;
GRANT SELECT, INSERT, UPDATE, DELETE, CREATE, ALTER, DROP, INDEX ON $dbName.* TO $user IDENTIFIED BY '$setupConf->{dbpassword}';
END
  $obj->executeSql($sql, $setupConf || { customer => $customer });
  print "Created database $dbName\n" if $obj->verbose();
}
#---------------------------------------------------------------------
sub createTables {
  my ($obj) = @_;
  my $setupConf = $obj->getSetupConf();
  foreach my $filePath ($context->getSingleton('O2::File')->resolveExistingPaths('o2://src/sql/MySql/o2.mysql')) {
    my $dbName = $obj->getDbName($setupConf);
    my $sql = "use $dbName;\n";
    $sql   .= $context->getSingleton('O2::File')->getFile($filePath);
    $obj->executeSql($sql, $setupConf);
    print "Created database tables from $filePath\n" if $obj->verbose();
  }
}
#---------------------------------------------------------------------
sub remove {
  my ($obj) = @_;
  my $setupConf = $obj->getSetupConf();
  my $dbName = $obj->getDbName($setupConf);
  $obj->executeSql( "drop database $dbName", $setupConf, 'About to drop database' );
  return 1;
}
#---------------------------------------------------------------------
sub executeSql {
  my ($obj, $sql, $setupConf, $confirmMsg) = @_;
  my $rootUser = $setupConf->{mysqlRootUser} || 'root';
  my $rootPass = $setupConf->{mysqlRootPass} || '';
  my $tmpDir   = $setupConf->{tmpDir}        || $config->get('setup.tmpDir') || '/tmp';
  my $tmpSqlFilePath = "$tmpDir/o2sql_$setupConf->{customer}.sql";
  $context->getSingleton('O2::File')->writeFile($tmpSqlFilePath, $sql);  
  my $command = "mysql -u $rootUser -p$rootPass < $tmpSqlFilePath";
  if ($confirmMsg) {
    $obj->confirmExecuteSql($sql, $command, $confirmMsg);
  }
  else {
    system $command;
  }
  unlink $tmpSqlFilePath;
}
#---------------------------------------------------------------------
sub backup {
  my ($obj) = @_;
  my $db = $context->getDbh();
  my $setupConf = $obj->getSetupConf();
  my $dumpFile    = "$setupConf->{tmpDir}/$setupConf->{hostname}.sql.gz";
  my $dumpCommand = "mysqldump --skip-lock-tables --skip-add-locks -u $db->{username} -p$db->{password}";
  $dumpCommand   .= " -h $db->{host}" if $db->{host};
  $dumpCommand   .= " $db->{dataSource} | gzip > $dumpFile";
  print "Backing up database. This may take some minutes:\n";
  print "  $dumpCommand\n";
  system $dumpCommand;
  return 1;
}
#---------------------------------------------------------------------
sub getDbName {
  my ($obj, $setupConf) = @_;
  return $config->get('o2.database.dataSource') || "o2_$setupConf->{customer}";
}
#---------------------------------------------------------------------
1;
