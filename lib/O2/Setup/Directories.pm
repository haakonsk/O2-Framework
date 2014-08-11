package O2::Setup::Directories;

use strict;

use base 'O2::Setup';

use O2 qw($context $config);

#---------------------------------------------------------------------
sub install {
  my ($obj, %params) = @_;
  my $setupConf = $params{setupConf};
  my $serverId = $obj->{serverId} = $setupConf->{serverId};
  $context->setHostname( $setupConf->{hostname} );
  foreach my $directory ($obj->getDirectories($setupConf)) {
    $obj->makeDirectory($directory);
  }
  
  if ($serverId ne 'test' && $serverId ne 'stage' && $serverId ne 'www' && $serverId ne 'prod') {
    my $customerPath = "$setupConf->{customersRoot}/$setupConf->{customer}";
    
    print "  Symlinking $setupConf->{o2FwRoot} => $customerPath/o2-fw" if $obj->debug();
    if (!-l "$customerPath/o2-fw") {
      symlink $setupConf->{o2FwRoot}, "$customerPath/o2-fw" or die "Couldn't make symlink from $setupConf->{o2FwRoot} to $customerPath/o2-fw: $!";
    }
  }
  
  $config->shiftConfigDirectory( $context->getEnv('O2CUSTOMERROOT') . '/etc/conf');
  
  return 1;
}
#---------------------------------------------------------------------
sub makeDirectory {
  my ($obj, $directory) = @_;
  print "  Making directory $directory\n" if $obj->verbose();
  if (!-d $directory) {
    mkdir $directory or die "Could not make directory $directory: $!";
  }
}
#---------------------------------------------------------------------
sub getDirectories {
  my ($obj, $setupConf) = @_;
  my $Customer = ucfirst $setupConf->{customer};
  my @directories = (
    "$setupConf->{hostname}",
    "$setupConf->{hostname}/imageRepository",
  );
  my $serverId = $setupConf->{serverId};
  if ($serverId ne 'test' && $serverId ne 'stage' && $serverId ne 'www' && $serverId ne 'prod') {
    push @directories, (
      'o2/bin',
      'o2/bin/cron',
      'o2/etc/conf/o2-configs',
      'o2/lib',
      'o2/lib/O2',
      "o2/lib/$Customer",
      "o2/lib/$Customer/Gui",
      "o2/lib/$Customer/Mgr",
      "o2/lib/$Customer/Obj",
      'o2/src',
      'o2/src/autodocumentation',
      'o2/src/classDefinitions',
      'o2/src/sql',
      'o2/src/sql/MySql',
      'o2/t',
      'o2/var',
      'o2/var/cache',
      'o2/var/cache/simpleCache',
      'o2/var/log',
      'o2/var/publicSessions',
      'o2/var/repository',
      'o2/var/resources',
    );
    foreach my $locale (split /\s*,\s*/, $setupConf->{locales}) {
      push @directories, "o2/var/resources/$locale";
    }
    push @directories, (
      'o2/var/search',
      'o2/var/search/documents',
      'o2/var/search/indexConfigs',
      'o2/var/search/indexes',
      'o2/var/sessions',
      'o2/var/templates',
      "o2/var/templates/$Customer",
      "o2/var/templates/$Customer/Gui",
      'o2/var/www',
      'o2/var/www/css',
      'o2/var/www/images',
      'o2/var/www/js',
      'o2/var/www/js/util',
    );
  }
  my $customerPath = "$setupConf->{customersRoot}/$setupConf->{customer}";
  @directories = map { "$customerPath/$_" } @directories;
  return @directories;
}
#---------------------------------------------------------------------
sub remove {
  my ($obj, %params) = @_;
  my $setupConf = $params{setupConf};
  my $dir = "$setupConf->{customersRoot}/$setupConf->{customer}";
  $obj->confirmExecute( "sudo rm -rf $dir", "About to delete directory $dir" ) if -d $dir;
  return 1;
}
#---------------------------------------------------------------------
sub backup {
  my ($obj, %params) = @_;
  my $setupConf = $params{setupConf};
  my $dir = "$setupConf->{customersRoot}/$setupConf->{customer}";
  $context->getSingleton('O2::File')->mkPath( $setupConf->{tmpDir} ) unless -d $setupConf->{tmpDir};
  my $backupFile = "$setupConf->{tmpDir}/$setupConf->{hostname}.tar.gz";
  print "Backing up files under $dir to $backupFile\n" if $obj->verbose();
  system "tar -czf $backupFile $dir";
  return 1;
}
#---------------------------------------------------------------------
1;
