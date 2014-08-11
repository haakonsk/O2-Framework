package O2::Setup::Scripts::Standard;

use strict;

use base 'O2::Setup';

use O2 qw($context);

#-----------------------------------------------------------------------------
sub install {
  my ($obj) = @_;
  $obj->upgrade();
  return 1;
}
#-----------------------------------------------------------------------------
sub upgrade {
  my ($obj) = @_;
  my $setupConf = $obj->getSetupConf();
  $obj->_setupEnvironment($setupConf);
  
  my $dir = "$setupConf->{o2FwRoot}/bin/setup/standard";
  my @scripts = $context->getSingleton('O2::File')->scanDirRecursive($dir, '*.pl$');
  @scripts    = sort {
    my ($aNum) = $a =~ m{ (?: / | \A) 0* (\d+) - [^/]+ \z }xms;
    my ($bNum) = $b =~ m{ (?: / | \A) 0* (\d+) - [^/]+ \z }xms;
    return $aNum <=> $bNum;
  } @scripts;
  
  foreach my $fileName (@scripts) {
    print "Executing $dir/$fileName\n" if $ARGV{v};
    system "perl $dir/$fileName";
  }
  return 1;
}
#-----------------------------------------------------------------------------
sub getClassName {
  my ($obj) = @_;
  return $obj->{className};
}
#-----------------------------------------------------------------------------
sub _setupEnvironment {
  my ($obj, $setupConf) = @_;
  system
      "export PERL5LIB=$setupConf->{customersRoot}/$setupConf->{customer}/lib:$setupConf->{o2FwRoot}/lib; "
    . "export O2ROOT=$setupConf->{o2FwRoot}; "
    . "export O2CUSTOMERROOT=$setupConf->{customersRoot}/$setupConf->{customer}/o2; "
    ;
}
#---------------------------------------------------------
1;
