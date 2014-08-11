use strict;
use warnings;

use Test::More (tests => 10);
use O2 qw($context);

use O2::Script::Common;
 
my $fileMgr = $context->getSingleton('O2::Mgr::FileManager');
ok(ref $fileMgr, 'Create O2::Mgr::FileManager');

my $file = $fileMgr->newObject();
ok(ref $file, 'newObject()');

$file->setContentFromUrl( 'http://gfx.dagbladet.no/pub/artikkel/4/48/482/482103/olje663h_1162885496.jpg' );
$file->setFileFormat(     'jpg'                                                                          );
$file->setMetaName(       'An image'                                                                     );

# set multilingual fields
my @locales = ($file->getCurrentLocale());
foreach my $locale (@locales) {
  $file->setCurrentLocale($locale);
  $file->setTitle(       "Title for locale $locale" );
  $file->setDescription( "Beskrivelse ($locale)"    );
}

# will it save?
$file->save();
ok( $file->getId() > 0, 'File saved' );

# will it load?
my $dbFile = $fileMgr->getObjectById( $file->getId() );
ok( $dbFile && $dbFile->getId() == $file->getId(), 'File retrieval' );

# check multilingual fields were loaded ok
foreach my $locale (@locales) {
  $dbFile->setCurrentLocale($locale);
  ok( $dbFile->getTitle()       eq "Title for locale $locale", "getTitle() $locale"       );
  ok( $dbFile->getDescription() eq "Beskrivelse ($locale)",    "getDescription() $locale" );
}

# path should move when deleted
my $path = $file->getFilePath();
ok(-e $path, 'Path found before delete');
$file->delete();
ok(!-e $path, 'Path gone after delete');
$file->setMetaStatus('new');
$file->save();
ok(-e $path, 'Path found again when revived');

END {
  $file->deletePermanently()                         if $file;
  ok(!-e $path, 'Path gone after deletePermanently') if $path;
}
