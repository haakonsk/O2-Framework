use strict;
use warnings;

use Test::More qw(no_plan);
use_ok 'O2::Javascript::Data';

my $jsData = O2::Javascript::Data->new();
ok( eq_array( $jsData->undumpXml( '<array></array>'                           ), []      ), 'Empty array'     );
ok( eq_array( $jsData->undumpXml( '<array><item><null/></item></array>'       ), [undef] ), 'Array with null' );
ok( eq_hash(  $jsData->undumpXml( '<hash></hash>'                             ), {}      ), 'Empty hash'      );
ok( eq_hash(  $jsData->undumpXml( '<hash><item>a</item><item>1</item></hash>' ), {a=>1}  ), 'Hash item'       );
ok( !defined  $jsData->undumpXml( '<null/>'                                   ), 'Null'                       );
