use strict;
use warnings;

use Test::More qw(no_plan);
use O2 qw($context);

my $dateTimeMgr = $context->getSingleton('O2::Mgr::DateTimeManager');
my $dateTime = $dateTimeMgr->newObject('2013-03-11');
$dateTime->save();

use_ok 'O2::Util::Serializer';
foreach my $format (qw(PLDS XML)) {
  my $serializer = O2::Util::Serializer->new( format => $format );
  isa_ok($serializer, "O2::Util::Serializer::$format");

  my $serializedObject   = $serializer->serialize(   $dateTime         );
  my $unserializedObject = $serializer->unserialize( $serializedObject );
  isa_ok($unserializedObject, 'O2::Obj::DateTime');

  my $checkSerializedObject = $serializer->serialize(   $unserializedObject    );
  my $checkObject           = $serializer->unserialize( $checkSerializedObject );

  isa_ok($checkObject, 'O2::Obj::DateTime');

  is( $dateTime->getMetaName(),  $checkObject->getMetaName(), 'metaName ok'       );
  is( $dateTime->getYear(),      $checkObject->getYear(),     'year ok'           );
  is( $dateTime->format(),       $checkObject->format(),      'default format ok' );
}

END {
  $dateTime->deletePermanently() if $dateTime;
}
