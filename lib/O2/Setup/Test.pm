package O2::Setup::Test;

use strict;

use base 'O2::Setup';

use O2 qw($context);
use Term::ANSIColor;

#---------------------------------------------------------
sub install {
  my ($obj) = @_;
  my $setupConf = $obj->getSetupConf();
  my $logPath = join '/', $setupConf->{customersRoot}, $setupConf->{customer}, 'tests.log';
  $obj->runTests($logPath);
  
  my $fileMgr = $context->getSingleton('O2::File');
  my @logLines = $fileMgr->getFile($logPath);
  if ($logLines[-1] =~ m{ PASS }xms) {
    print '    ' . (colored ['green on_black'], "All tests passed :)") . "\n" if $obj->verbose();
    $fileMgr->rmFile($logPath);
  }
  else {
    print '    ' . (colored ['red on_white'], "One or more errors in tests, please check out $logPath for a summary of the errors.") . "\n";
  }
  return 1;  
}
#---------------------------------------------------------
sub runTests {
  my ($obj, $logPath) = @_;
  
  print "  Running tests\n" if $obj->verbose();
  
  my $command = $obj->_getCommand($logPath);
  print "  $command\n" if $obj->debug();
  system $command;
}
#---------------------------------------------------------
sub _getCommand {
  my ($obj, $logPath) = @_;
  my $setupConf = $obj->getSetupConf();
  return
      "export PERL5LIB=$setupConf->{customersRoot}/$setupConf->{customer}/o2/lib:$setupConf->{o2FwRoot}/lib; "
    . "export O2ROOT=$setupConf->{o2FwRoot}; "
    . "export O2CUSTOMERROOT=$setupConf->{customersRoot}/$setupConf->{customer}/o2; "
    . "cd $setupConf->{o2FwRoot}/t; "
    . "perl runTests.pl --harness > $logPath 2>&1; "
    ;
}
#---------------------------------------------------------
1;
