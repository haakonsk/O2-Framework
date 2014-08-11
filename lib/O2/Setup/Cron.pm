package O2::Setup::Cron;

use strict;

use base 'O2::Setup';

use O2 qw($context $config);
use Term::ANSIColor;

my $customerPath;
#---------------------------------------------------------------------
sub install {
  my ($obj) = @_;
  my $serverId = $config->getServerId();
  return 1 if $serverId eq 'test' || $serverId eq 'stage' || $serverId eq 'www' || $serverId eq 'prod';
  
  my $setupConf = $obj->getSetupConf();
  $customerPath = "$setupConf->{customersRoot}/$setupConf->{customer}";
  
  $obj->createFiles();
  
  print colored ['red on_white'], '-------------------------------------------';
  print "\nYou might want to add the following lines to $setupConf->{groupOwner}'s crontab:\n";
  print "*    * * * * $customerPath/o2/bin/cron/onemin\n";
  print "*/12 * * * * $customerPath/o2/bin/cron/fivemin\n";
  print "*/4  * * * * $customerPath/o2/bin/cron/quarter-hourly\n";
  print "0    * * * * $customerPath/o2/bin/cron/hourly\n";
  print "0    0 * * * $customerPath/o2/bin/cron/daily\n";
  print colored ['red on_white'], '-------------------------------------------';
  print "\n";
  
  return 1;
}
#---------------------------------------------------------------------
sub createFiles {
  my ($obj) = @_;
  $obj->createFile( 'daily',          ["perl $customerPath/o2-fw/bin/tools/sessionGarbageCollector.pl"]                                        );
  $obj->createFile( 'hourly',         [$context->cmsIsEnabled() ? "perl $customerPath/o2-cms/bin/tools/reAddAndIndexArticlesAndFiles.pl" : ()] );
  $obj->createFile( 'quarter-hourly', []                                                                                                       );
  $obj->createFile( 'fivemin',        []                                                                                                       );
  $obj->createFile( 'onemin',         ["perl $customerPath/o2-fw/bin/tools/handleEvents.pl"]                                                   );
}
#---------------------------------------------------------------------
sub createFile {
  my ($obj, $fileName, $lines) = @_;
  
  my $hostname = $context->getHostname();
  
  my $perl5Lib =  "$customerPath/o2/lib";
  $perl5Lib   .= ":$customerPath/o2-cms/lib" if $context->cmsIsEnabled();
  $perl5Lib   .= ":$customerPath/o2-fw/lib";
  
  my $header = <<"END";
#!/bin/bash
export O2ROOT=$customerPath/o2-fw
END
  $header .= "export O2CMSROOT=$customerPath/o2-cms\n" if $context->cmsIsEnabled();
  $header .= <<"END";
export O2CUSTOMERROOT=$customerPath/o2
export DOCUMENT_ROOT=$customerPath/$hostname
export PERL5LIB=$perl5Lib
END
  
  my $content = "$header\n";
  foreach my $line (@{$lines}) {
    $content .= "$line\n";
  }
  
  $context->getSingleton('O2::Util::Commandline')->writeFileWithConfirm("$customerPath/o2/bin/cron/$fileName", $content);
  print "  $customerPath/o2/bin/cron/$fileName created\n" if $obj->verbose();
}
#---------------------------------------------------------------------
1;
