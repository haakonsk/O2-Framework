use strict;
use warnings;

use Test::More qw(no_plan);
use_ok 'O2::Image::Image';

my $readFile  = "$ENV{O2ROOT}/t/data/O2-Obj-File-16.png";
my $writeFile = "$ENV{O2ROOT}/t/data/test.jpg";

my $img = O2::Image::Image->newFromFile($readFile);
ok($img, "$readFile read");
ok($img->getWidth() == 16  &&  $img->getHeight() == 16, "$readFile is 16x16");
$img->resize(200, 200);
$img->grayscale();
$img->rotate(90);
$img->setExifInfo('Artist', '123');
$img->write($writeFile);
ok(-e $writeFile,"$writeFile written");

my $resultImg = O2::Image::Image->newFromFile($writeFile);
ok( $resultImg->getWidth() == 200  &&  $resultImg->getHeight() == 200, "$writeFile is 200x200" );
is( $resultImg->getExifInfo( 'ImageHeight'), 200, "getExifInfo(ImageHeight)"                   );
is( $resultImg->getExifInfo( 'Artist'),    '123', "wrote and read getExifInfo(Artist)"         );

sub END {
  unlink $writeFile if $writeFile && -f $writeFile;
}
