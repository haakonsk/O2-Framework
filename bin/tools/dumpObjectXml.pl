#!/local/bin/perl

use strict;

use O2::Context;
my $context = new O2::Context();
use O2::Mgr::UniversalManager;


die "usage: $0 objectId objectId...\n" unless @ARGV;
my $universalM = new O2::Mgr::UniversalManager(context=>$context);
foreach my $objectId (@ARGV) {
    my $object = $universalM->getObjectById($objectId);
    print $object->getMetaClassName(),' - ',$object->getMetaName(),"\n";
}
