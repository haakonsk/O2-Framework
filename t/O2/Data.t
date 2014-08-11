use strict;

use Test::More qw(no_plan);
use O2;

use_ok 'O2::Data';
my $dataMgr = O2::Data->new();

my $fileName1 = 'o2DataTest1.txt';
my $fileName2 = 'o2DataTest2.txt';
my $struct   = {
  a => 1,
  b => 2,
  c => {
    d => 4,
    e => 'å',
  }
};

$dataMgr->save($fileName1, $struct);
$dataMgr->save($fileName2, $struct);
my $loadedStruct = $dataMgr->load($fileName1);
is_deeply($struct, $loadedStruct, 'Single save and load');

my @loadedStructs = $dataMgr->load($fileName1, $fileName2);
foreach $loadedStruct (@loadedStructs) {
  is_deeply($struct, $loadedStruct, 'Multiple load');
}

my $frozen = $dataMgr->dump($struct);

my $thawed = $dataMgr->undump($frozen);
is_deeply($struct, $thawed, 'Single dump and undump');

# Two at the same time:
my ($thawed1, $thawed2) = $dataMgr->undump($frozen, $frozen);
is_deeply($struct, $thawed1, 'Multiple undump');
is_deeply($struct, $thawed2, 'Multiple undump');


my $changeTime = time;
$dataMgr->save( $fileName1, $struct, {changeTime => $changeTime} );
$dataMgr->load( $fileName1 );
my $changeTime2 = $dataMgr->getMetaDataKey('changeTime');
is($changeTime, $changeTime2, 'metaData test');

sub END {
  unlink $fileName1;
  unlink $fileName2;
}
