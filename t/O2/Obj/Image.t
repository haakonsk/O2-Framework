use strict;
use warnings;

use Test::More qw(no_plan);
use O2 qw($context);

use_ok 'O2::Mgr::ImageManager';
use O2::Script::Test::Common;

my @tests = (
  {
    imageUrl => 'http://gfx.dagbladet.no/labrador/478/478699/4786994/jpg/active/188x.jpg',
  },
  {
    imageUrl => 'http://linpro.no/sites/all/themes/redpill/logo.png',
  },
);

my $timeStamp = time;
my $imageMgr = $context->getSingleton('O2::Mgr::ImageManager');
my @images;

foreach my $test (@tests) {
  my $url = $test->{imageUrl};
  diag "$url:";
  my $image = $imageMgr->newObject();
  push @images, $image;

  my ($fileFormat) = $url =~ m{ [.] (\w+) \z }xms;

  $image->setMetaName(       'My filename'    );
  $image->setFileFormat(     $fileFormat      );
  $image->setWidth(          12               );
  $image->setHeight(         12               );
  $image->setTitle(          'My title'       );
  $image->setDescription(    'My description' );
  $image->setArtistName(     'Name of artist' );
  $image->setCopyright(      'yes'            );
  $image->setContentFromUrl(  $url            );
  $image->setExifTitle(       'My title'      );
  $image->setExifArtist(      'Me'            );
  $image->setExifDateAndTime( $timeStamp      );
  $image->setExifDescription('asd askdfbsf sdkgfbsdg fsdgkjdfkgdf gkjbdgkjdf gkjfbksdbfks dfksdvfhksdvbf sdhfvsdfsd fjhvsfjsvdf sdfhvbsdhvfsdbgd fkgjbdkjgkjvdfk');
  $image->save();
  ok($image->getId() > 0, 'Object saved ok');

  my $dbObj = $context->getObjectById( $image->getId() );
  is( $dbObj->getMetaName(),    $image->getMetaName(),    'metaName ok'    );
  is( $dbObj->getFileFormat(),  $image->getFileFormat(),  'fileFormat ok'  );
  is( $dbObj->getWidth(),       $image->getWidth(),       'width ok'       );
  is( $dbObj->getHeight(),      $image->getHeight(),      'height ok'      );
  is( $dbObj->getTitle(),       $image->getTitle(),       'title ok'       );
  is( $dbObj->getDescription(), $image->getDescription(), 'description ok' );
  is( $dbObj->getArtistName(),  $image->getArtistName(),  'artistName ok'  );
  is( $dbObj->getCopyright(),   $image->getCopyright(),   'copyright ok'   );
  if ($fileFormat ne 'gif' && $fileFormat ne 'png') {
    is( $dbObj->getExifTitle(),       'My title',                   'exifTitle ok'       );
    is( $dbObj->getExifDescription(), $image->getExifDescription(), 'exifDescription ok' );
    is( $dbObj->getExifArtist(),      'Me',                         'exifArtist ok'      );
    is( $dbObj->getExifDateAndTime(), $timeStamp,                   'DateTime ok'        );
  }
}

sub END {
  foreach my $image (@images) {
    $image->deletePermanently() if $image->getId();
  }
}
