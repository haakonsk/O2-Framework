use strict;
use warnings;

use utf8;

use Test::More qw(no_plan);

use_ok 'O2::Util::NumberFormat';

my $nf = O2::Util::NumberFormat->new('en_US');

is( $nf->numberFormat(123456.7890), '123,456.789', 'number format(123456.7890) ok' );
is( $nf->numberFormat(123456.7898),  '123,456.79', 'number format(123456.7898) ok' );
is( $nf->numberFormat(123456.78),    '123,456.78', 'number format(123456.78) ok'   );
is( $nf->numberFormat(123456.7800),  '123,456.78', 'number format(123456.7800) ok' );

is( $nf->percentFormat(0.123),  '12%', 'percent ok (12%)'  );
is( $nf->percentFormat(0.199),  '20%', 'percent ok (20%)'  );
is( $nf->percentFormat(1.01),  '101%', 'percent ok (101%)' );
is( $nf->percentFormat(1.014), '101%', 'percent ok (101%)' );
is( $nf->percentFormat(0.998), '100%', 'percent ok (100%)' );
is( $nf->percentFormat(0.994),  '99%', 'percent ok (99%)'  );

is( $nf->doFormat( '#,##0.###', 1200000), '1,200,000', 'number ok'                   );
is( $nf->doFormat( '0,000.00', 549.99972),   '550.00', 'number format(549.99972) ok' );

$nf = O2::Util::NumberFormat->new('nb_NO');
is( $nf->doFormat('¤#,##0.00;(¤#,##0.00)', 349), 'kr349,00',  'money format(349) ok'              );
is( $nf->moneyFormat(600),                       'kr 600,00', 'money format(600) ok'              );
is( $nf->moneyFormat(600.000000000001),          'kr 600,00', 'money format(600.000000000001) ok' );
is( $nf->moneyFormat(599.999999999999),          'kr 600,00', 'money format(599.999999999999) ok' );

is( $nf->doFormat('0.0', 2.96),   '3,0', 'doFormat("0.0", 2.96)  ==  3,0' );
is( $nf->doFormat('0.0', 7.156),  '7,2', 'doFormat("0.0", 7.156) ==  8,2' );
is( $nf->doFormat('0.0', -3.99), '−4,0', 'doFormat("0.0", -3.99) == -4,0' );
