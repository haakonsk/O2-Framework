# ssh db.greteroede.c.bitbit.net "ls -tr /var/backups/mysql | tail -2 | head -1"
use strict;
use warnings;

# Todo:
#  Update o2-fw/o2-cms symlinks
#  Translate hostname in cached files

use O2::Util::Args::Simple;
use O2::Script::Common;

use O2::Context;
my $context = O2::Context->new();

my $configPath = $ARGV{'-configPath'} || $ARGV{configPath} or die "configPath is required";
my $conf = do $configPath;

my $customer          = $conf->{customer};
my $customersRoot     = $context->getConfig()->get('setup.customersRoot');
my $remoteServer      = $conf->{remoteServer};
my $needsConfirmation = exists $ARGV{-confirmCommands} ? $ARGV{-confirmCommands} : $conf->{confirmCommands};

my $dbRootPassword = $conf->{db}->{local}->{rootPassword} || ask("Password for local database's root user (optional, but you might have to provide the password later on):") || '';

my $t0 = scalar localtime;

syncDb();
syncFiles();
makeHostnameSymlinks();
makeConfigSymlinks();

print  "\nStarted:  $t0\n";
printf "Finished: %s\n\n", scalar localtime;

sub syncFiles {
  # Sync files with rsync:
  my @excludeDirs = @{ $conf->{excludeDirs} };
  my $excludeDirs = '';
  foreach my $dir (@excludeDirs) {
    $excludeDirs .= "--exclude=$dir ";
  }
  $excludeDirs = substr $excludeDirs, 0, -1 if $excludeDirs;
  
  my $rsyncCmd = qq{rsync --progress -r -l -v -c -z -p --rsh="ssh" $excludeDirs $remoteServer:$customersRoot/$customer/ $customersRoot/$customer/};
  print $rsyncCmd unless $needsConfirmation;
  system "$rsyncCmd\n" if !$needsConfirmation || lc ask("Please confirm rsync command:\n  $rsyncCmd\n(Y/n)") ne 'n';
  
  while ( my ($remoteDir, $localDir) = each %{ $conf->{extraDirs} } ) {
    $remoteDir = "$customersRoot/$customer/o2/$remoteDir" if $remoteDir !~ m{ \A / }xms;
    $localDir  = "$customersRoot/$customer/o2/$localDir"  if $localDir  !~ m{ \A / }xms;
    $rsyncCmd  = qq{rsync --progress -r -l -v -c -z -p --rsh="ssh" $remoteServer:$remoteDir $localDir};
    print "$rsyncCmd\n" unless $needsConfirmation;
    system $rsyncCmd if !$needsConfirmation || lc ask("Please confirm rsync command:\n  $rsyncCmd\n(Y/n)") ne 'n';
  }
}

sub syncDb {
  # Delete all database tables on the server we're syncing to.
  my $schemaMgr    = $context->getSingleton( 'O2::DB::Util::SchemaManager' );
  my $dbIntrospect = $context->getSingleton( 'O2::DB::Util::Introspect'    );
  print "Deleting all database tables\n" unless $needsConfirmation;
  if (!$needsConfirmation || lc ask("Going to delete all database tables. Please confirm (Y/n)") ne 'n') {
    my @tables = $dbIntrospect->getTables();
    foreach my $table (@tables) {
      $schemaMgr->dropTable( $table->getName() );
    }
  }
  
  my $translateHostnameCmd = '';
  if ( $conf->{hostnameTranslations}  &&  %{ $conf->{hostnameTranslations} } ) {
    $translateHostnameCmd = qq[ | perl -e 'while (<STDIN>) { chomp; ];
    while (my ($remoteHostname, $localHostname) = each %{ $conf->{hostnameTranslations} }) {
      $translateHostnameCmd .= qq[ \$_ =~ s|\Q$remoteHostname\E|$localHostname|gi; ];
    }
    $translateHostnameCmd .= qq[ print "\$_\\n"; }' ];
  }
  my $localDb  = $conf->{db}->{local};
  my $remoteDb = $conf->{db}->{remote};
  $localDb->{host} ||= 'localhost';
  
  # Create database if it doesn't exist:
  eval {
    $context->getDbh()->sql("show databases");
  };
  if ($@) {
    # Looks like database doesn't exist, let's try to create it:
    print "The password you will be asked to provide is the root password of the database\n" unless $dbRootPassword;
    system "mysqladmin -u root -p$dbRootPassword create $localDb->{dataSource}";
    system qq{mysql -u root -p$dbRootPassword -e "GRANT SELECT, INSERT, UPDATE, DELETE, CREATE, DROP, ALTER, INDEX, LOCK TABLES ON $localDb->{dataSource}.* TO '$localDb->{username}'\@'$localDb->{host}' IDENTIFIED BY '$localDb->{password}'"};
  }
  
  # Sync O2_OBJ_OBJECT first:
  my $remoteDataSource = $remoteDb->{dataSource} || $localDb->{dataSource};
  my $dbSyncCmd
    = sprintf qq{ssh $remoteServer "mysqldump --skip-lock-tables --skip-add-locks -h %s -u %s --password=%s %s" O2_OBJ_OBJECT $translateHostnameCmd | mysql -h %s -u %s --password=%s %s},
    $remoteDb->{host} || $localDb->{host}, $remoteDb->{username} || $localDb->{username},  $remoteDb->{password} || $localDb->{password},  $remoteDataSource,
    $localDb->{host},                      $localDb->{username},                           $localDb->{password},                           $localDb->{dataSource},
    ;
  print "$dbSyncCmd\n" unless $needsConfirmation;
  system $dbSyncCmd if !$needsConfirmation || lc ask("Please confirm db sync command:\n  $dbSyncCmd\n(Y/n)") ne 'n';
  
  # Sync other tables:
  $dbSyncCmd
    = sprintf qq{ssh $remoteServer "mysqldump --skip-lock-tables --skip-add-locks -h %s -u %s --password=%s %s" --ignore-table=%s.O2_OBJ_OBJECT $translateHostnameCmd | mysql -h %s -u %s --password=%s %s},
    $remoteDb->{host} || $localDb->{host}, $remoteDb->{username} || $localDb->{username},  $remoteDb->{password} || $localDb->{password},  $remoteDataSource, $remoteDataSource,
    $localDb->{host},                      $localDb->{username},                           $localDb->{password},                           $localDb->{dataSource},
    ;
  print "$dbSyncCmd\n" unless $needsConfirmation;
  system $dbSyncCmd if !$needsConfirmation || lc ask("Please confirm db sync command:\n  $dbSyncCmd\n(Y/n)") ne 'n';
  
  # Delete rows where id > max(O2_OBJ_OBJECT.objectId):
  print "Deleting rows where id > max(O2_OBJ_OBJECT.objectId)\n" unless $needsConfirmation;
  return if $needsConfirmation && lc ask("Going to delete rows where objectId > max(O2_OBJ_OBJECT.objectId). Please confirm (Y/n)") eq 'n';
  
  my $dbh = $context->getDbh();
  my $maxId = $dbh->fetch("select max(objectId) from O2_OBJ_OBJECT");
  my @tables = $dbIntrospect->getTables();
  foreach my $table (@tables) {
    my $tableName = $table->getName();
    $dbh->sql("delete from $tableName where objectId > ?", $maxId) if $table->hasColumn('objectId');
  }
  $dbh->sql("delete from O2_OBJ_OBJECT_OBJECT where value > ?", $maxId);
  my %classes = $context->getSingleton('O2::Util::ObjectIntrospect')->getAllObjectClasses();
  my $universalMgr = $context->getUniversalMgr();
  foreach my $className (keys %classes) {
    my $mgr = $universalMgr->getManagerByClassName($className);
    my $model = $mgr->getModel();
    my @fields = $model->getFieldsByClassName($className);
    foreach my $field (@fields) {
      my $tableName = $field->getTableName();
      next if !$field->isObjectType() || $tableName eq 'O2_OBJ_OBJECT' || $tableName eq 'O2_OBJ_OBJECT_OBJECT';
      $dbh->sql( sprintf "delete from $tableName where %s > $maxId", $field->getName() );
    }
  }
}

sub makeHostnameSymlinks {
  return if !$conf->{hostnameTranslations}  ||  !%{ $conf->{hostnameTranslations} };
  
  print "Making symbolic links between hostnames\n" unless $needsConfirmation;
  return if $needsConfirmation && lc ask("Going to make symbolic links between hostnames. Please confirm (Y/n)") eq 'n';
  
  while (my ($remoteHostname, $localHostname) = each %{ $conf->{hostnameTranslations} }) {
    my $dir1 = "$customersRoot/$customer";
    my $dir2 = "$customersRoot/$customer/o2/var/cache/pagecache";
    foreach my $dir ($dir1, $dir2) {
      if (-d "$dir/$remoteHostname") {
        system "rm     $dir/$localHostname" if -e "$dir/$localHostname";
        system "rm -rf $dir/$localHostname" if -e "$dir/$localHostname";
        symlink "$dir/$remoteHostname", "$dir/$localHostname";
      }
    }
  }
}

sub makeConfigSymlinks {
  return unless $conf->{configInfix};
  
  print "Making symbolic links for server specific config files\n" unless $needsConfirmation;
  return if $needsConfirmation && lc ask("Going to make symbolic links for server specific config files. Please confirm (Y/n)") eq 'n';
  
  my $dir = "$customersRoot/$customer/o2/etc/conf";
  my @configFiles = $context->getSingleton('O2::File')->scanDirRecursive($dir, "*$conf->{configInfix}*");
  foreach my $fileName (@configFiles) {
    my $fileNameWithoutInfix = $fileName;
    $fileNameWithoutInfix    =~ s{ \Q$conf->{configInfix}\E }{}xms;
    system "rm $dir/$fileNameWithoutInfix" if -f "$dir/$fileNameWithoutInfix";
    symlink "$dir/$fileName", "$dir/$fileNameWithoutInfix";
  }
}

__END__

# Example config:
{
  customer        => 'example',
  remoteServer    => 'www.example.com',
  confirmCommands => 0,
  hostnameTranslations => {
    'www.example.com'    => 'dev.example.com',
  },
  extraDirs => {
    '/www/dav/*'        => '/www/dav',
    '/etc/httpd/conf.d' => '/www/apacheconf',
    '/etc/httpd/ssl/*'  => '/etc/apache2/ssl',
  },
  excludeDirs => [
    'var/cache',
    'var/logs',
    'var/publicSessions',
    'var/search',
    'var/sessions',
  ],
  db => {
    local => {
      dataSource   => 'o2_example',
      host         => 'localhost',
      username     => 'example',
      password     => '*********',
      rootPassword => '*******',
    },
    remote => {
      host => 'db.example.com',
    },
  },
  configInfix => '.dev',
};
