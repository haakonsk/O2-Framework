use strict;
use utf8;

use Test::More qw(no_plan);
use O2 qw($cgi $config);

my $encoding = $config->get('o2.characterSet');

my @encodeDecodeStrings = (
  "This is a simple test-string with no special characters",
  "!#%&/()=?,.-_:+;'*",
  "æøå",
  "2 + 2 = 4",
);
require Encode;
foreach my $string (@encodeDecodeStrings) {
  my $encodedString   = Encode::encode($encoding, $string);
  my $unencodedString = $string;
  my $resultString    = $cgi->urlDecode( $cgi->urlEncode($unencodedString) );
  is( Encode::encode($encoding, $resultString), $encodedString, $encodedString );
}

# XXX Test urlDecode from utf-8 and iso-8859-1.
