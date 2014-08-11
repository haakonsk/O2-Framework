package O2::Setup::Apache;

use strict;

use base 'O2::Setup';

use O2 qw($context $config);
use Term::ANSIColor;

#-------------------------------------------------------------------------
sub install {
  my ($obj) = @_;
  $obj->createApacheConfig();
  $obj->createApachePasswords();
  return 1;
}
#-------------------------------------------------------------------------
sub remove {
  my ($obj, %params) = @_;
  my $setupConf = $obj->getSetupConf();
  
  require Cwd;
  my $confPath         = "$setupConf->{apacheConfDir}/$setupConf->{hostname}.conf";
  my $absoluteConfPath = -l $confPath ? Cwd::abs_path($confPath) : $confPath;
  
  require Apache::Admin::Config;
  my $apacheConf = Apache::Admin::Config->new($absoluteConfPath || $confPath);
  if (!$apacheConf) {
    print "  Didn't find Apache config file ($absoluteConfPath)\n";
    return 1;
  }
  my $section   = $apacheConf->section('VirtualHost');
  my $customLog = $section->directive('CustomLog')->value();
  my $errorLog  = $section->directive('ErrorLog')->value();
  $obj->confirmExecute("rm -f $errorLog", 'About to try to delete Apache error log') if -f $errorLog;
  if (my ($dir) = $customLog =~ m{ \A [\"\']? ( [^ ]* / \Q$setupConf->{customer}\E ) / [^/]+ \z }xms) {
    $obj->confirmExecute("rm -rf $dir", 'About to try to delete Apache log files') if -d $dir;
  }
  else {
    print "  Didn't understand CustomLog directive. Please delete logs manually. CustomLog=$customLog\n";
  }
  $obj->confirmExecute("rm -f $confPath", 'About to try to delete Apache config file') if -f $confPath;
  return 1;
}
#-------------------------------------------------------------------------
sub backup {
  my ($obj) = @_;
  my $setupConf = $obj->getSetupConf();
  my $fromFile = "$setupConf->{apacheConfDir}/$setupConf->{hostname}.conf";
  my $toFile   = "$setupConf->{tmpDir}/$setupConf->{hostname}.conf";
  print "Backing up apacheconf: Copying $fromFile to $toFile\n" if $obj->verbose();
  $context->getSingleton('O2::File')->cpFile($fromFile, $toFile);
  return 1;
}
#-------------------------------------------------------------------------
sub createApacheConfig {
  my ($obj, %params) = @_;
  
  print "  Creating Apache-config\n" if $obj->verbose();
  my $setupConf = {
    %{ $obj->getSetupConf() || {} },
    %params,
  };
  
  my $hostname      = $setupConf->{hostname};
  my $customersRoot = $setupConf->{customersRoot} || '/www/cust';
  my $customerRoot  = $context->getEnv('O2CUSTOMERROOT');
  my ($customer)    = $customerRoot =~ m{ \A $customersRoot/ (.+?) /o2 }xms;
  my $o2FwRoot      = $setupConf->{o2FwRoot}  || $context->getEnv('O2ROOT');
  my $o2CmsRoot     = $setupConf->{o2CmsRoot} || $context->getEnv('O2CMSROOT');
  
  my $apacheLogDir  = $setupConf->{apacheLogDir} || '/www/httplogs';
  my $apacheLogPath = "$apacheLogDir/transfer/$customer";
  $obj->makeDirectory($apacheLogPath) unless -d $apacheLogPath;

  my $apacheConfDir = $setupConf->{apacheConfDir} || '/www/apacheconf/o2Sites';
  $obj->makeDirectory($apacheConfDir) unless -d $apacheConfDir;
  $ENV{O2APACHECONFDIR} = $apacheConfDir;

  my $apacheErrorPath = "$apacheLogDir/error/$customer";
  $obj->makeDirectory($apacheErrorPath) unless -d $apacheErrorPath;
  
  require O2::Template;
  my $apacheConfigRoot = $context->cmsIsEnabled() ? $o2CmsRoot : $o2FwRoot;
  my $tmpl = O2::Template->newFromFile("$apacheConfigRoot/src/apache/httpd-template.conf");
  my $apacheConfig = ${
    $tmpl->parse(
      hostname             => $hostname,
      port                 => $setupConf->{port} || 80,
      customersRoot        => $customersRoot,
      customer             => $customer,
      apacheTransferLogDir => $apacheLogPath,
      apacheErrorLogDir    => $apacheErrorPath,
      apacheConfDir        => $apacheConfDir,
      isModPerl            => $setupConf->{useModPerl},
      isMultilingualSite   => $setupConf->{locales} =~ m{,}xms, # At least one comma means at least two locales
    )
  };
  
  my $confDir = "$customerRoot/etc/conf/apache";
  $obj->makeDirectory($confDir) unless -d $confDir;
  my $apacheConfPath = "$confDir/$hostname.modcgi.conf";
  $context->getSingleton('O2::File')->writeFile($apacheConfPath, $apacheConfig);
  
  my $symlinkPath = "$apacheConfDir/$hostname.conf";
  if (-f $symlinkPath && !-l $symlinkPath) {
    rename $symlinkPath, "$apacheConfDir/$hostname.conf.bak" or die "Couldn't rename $symlinkPath: $!";
  }
  elsif (-l $symlinkPath) {
    unlink $symlinkPath or die "Couldn't unlink $symlinkPath: $!";
  }
  symlink $apacheConfPath, $symlinkPath or die "Couldn't create symlink $symlinkPath: $!";
  
  my $apachectl;
  foreach my $_apachectl (@{ $config->get('o2.apache.binaryPaths') }) {
    if (-e $_apachectl) {
      $apachectl = $_apachectl;
      last;
    }
  }
  die "Didn't find apachectl or apache2ctl" unless $apachectl;
  
  my @args = ('sudo', $apachectl, 'configtest');
  my $status = system @args;
  if ($status == 0) {
    # print "Configtest went ok, we would like to continue\n";
    $args[2] = 'graceful';
    $status = system @args;
    # print "apache restarted gracefully, all ok!\n" if $status == 0;
  }
  else {
    my $newFileName = "$apacheConfPath.broken-" . time;
    print (colored ['red on_white'], "Configtest did not go well, renaming $apacheConfPath to $newFileName");
    print "\n";
    rename $apacheConfPath, $newFileName;
  }
}
#-----------------------------------------------------------------------------
sub createApachePasswords {
  my ($obj) = @_;
  my $setupConf    = $obj->getSetupConf();
  my $customerRoot = $context->getEnv('O2CUSTOMERROOT');
  my $password     = $setupConf->{systemModelPassword} || $setupConf->{o2cmsPassword} || $context->{__adminPassword} || $context->getSingleton('O2::Util::Password')->generatePassword();
  $context->{__adminPassword} = $password;
  qx{htpasswd -bc $customerRoot/.passwords admin $password};
  print 'Created admin password for /o2/System-Model/: admin / ' . (colored ['red on_white'], $password) . "\n";
}
#-----------------------------------------------------------------------------
sub makeDirectory {
  my ($obj, $path) = @_;
  
  my ($baseDir, $lastDir) = $path =~ m{ (.*) / ([^/]+) /? \z }xms;
  $obj->makeDirectory($baseDir) unless -d $baseDir;
  
  my $setupConf = $obj->getSetupConf();
  print "  Making directory $path\n" if $obj->debug();
  if (!mkdir $path) {
    die "Could not make directory $path: $!" if $! !~ m/file exists/i;
    warn "  Directory $path already exists\n";
  }
  else {
    system "sudo chgrp $setupConf->{groupOwner} $path";
  }
}
#-----------------------------------------------------------------------------
1;
