package O2::Util::ExternalModule;

use strict;

BEGIN {
  my @paths;
  foreach my $dir (@INC) {
    if ($dir =~ m{ o2 [^\\/]* [\\/] lib }xmsi) {
      push @paths, $dir . ($dir =~ m{ [\\/] \z } ? '' : '/') . 'O2/Util/ExternalModule/lib';
    }
  }
  unshift @INC, @paths;
}
#--------------------------------------------------------------------------------------------
sub require {
  my ($pkg, $module) = @_;
  eval "require $module";
  die $@ if $@;
}
#--------------------------------------------------------------------------------------------
sub use {
  my ($pkg, $module) = @_;
  eval "use $module";
  die $@ if $@;
}
#--------------------------------------------------------------------------------------------
1;
