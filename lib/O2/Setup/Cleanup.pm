package O2::Setup::Cleanup;

use strict;

use base 'O2::Setup';

#---------------------------------------------------------------------
sub install {
  my ($obj) = @_;
  print "  Cleaning up\n" if $obj->verbose();
  
  my $setupConf = $obj->getSetupConf();
  
  my $customerPath = "$setupConf->{customersRoot}/$setupConf->{customer}";
  my $changeGroup  = "sudo chgrp $setupConf->{groupOwner} -R $customerPath";
  my $changeMode   = "sudo chmod g+w -R $customerPath";
  
  if ($obj->debug()) {
    print "  Executing $changeGroup\n"; 
    print "  Executing $changeMode\n"; 
  }
  
  system $changeGroup;
  system $changeMode;
  return 1;  
}
#---------------------------------------------------------------------
1;
