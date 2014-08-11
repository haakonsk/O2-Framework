package O2::Util::WebProfiler;

use strict;

use O2 qw($context);
use Time::HiRes qw(time);

our $O2PROFILESQLDATA;

umask 0002;
my $isO2Request;
my $requestLogFileName;
my $dbLogFileName;
#----------------------------------------------------------------------
sub import {
  my $customerPath = $context->getCustomerPath();
  if ($customerPath && -d $customerPath) {
    $isO2Request = 1;
    my $varPath = "$customerPath/var";
    if (-d $varPath && -w $varPath) {
      $varPath .= '/o2WebProfiler';
      mkdir $varPath;
    }
    $requestLogFileName = "$varPath/o2webprofiler.$$." . time . '.out.nytprof';
    $dbLogFileName = $requestLogFileName;
    $dbLogFileName =~ s/nytprof$/sqlfile/;
    $ENV{NYTPROF} = "file=$requestLogFileName";
  }
  require Devel::NYTProf;
}
#----------------------------------------------------------------------
END {
  if ($isO2Request) {
    require O2::Data; 
    O2::Data->new()->save($dbLogFileName, $O2PROFILESQLDATA);
    $context->getConsole()->_log('profiling', $context->getHostname() . "/o2/System-WebProfiler/viewReport?file=$requestLogFileName", callerLevel => 0);
  }
}
#----------------------------------------------------------------------
1;
