package O2::Setup::FW;

use strict;

use base 'O2::Setup';

use O2::Script::Common;

#---------------------------------------------------------------------
sub getDependencies {
  my ($obj, $action) = @_;
  return if ref $obj ne 'O2::Setup::FW'; # XXX Need to figure out a way to prevent subclasses from installing on their own

  my %dependencies = (
    1  => 'O2::Setup::Directories',
    2  => 'O2::Setup::Configs',
    3  => 'O2::Setup::Database',
    4  => 'O2::Setup::Apache',
    5  => 'O2::Setup::IndexHtml',
    6  => 'O2::Setup::Classes',
    7  => 'O2::Setup::Scripts::Standard',
    8  => 'O2::Setup::ClassesAndDefaults',
    9  => 'O2::Setup::Cron',
    10 => 'O2::Setup::Test',
    11 => 'O2::Setup::Cleanup',
  );
  $dependencies{'0'} = delete $dependencies{'4'} if $action eq 'remove'; # Must remove apache conf before /www/cust/<customer> is deleted
  return @dependencies{sort { $a <=> $b } keys %dependencies}; # Sorting numerically so '10' doesn't come before '2'
}
#---------------------------------------------------------------------
1;
