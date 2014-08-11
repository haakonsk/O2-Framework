use strict;

use Test::More qw(no_plan);

use_ok 'O2::Util::Password';
my $passwordUtil = new O2::Util::Password();
ok(ref $passwordUtil, 'Password object created');

foreach my $length (1, 8) {
  my $password = $passwordUtil->generatePassword($length);
  ok( $password =~ m/^\w+$/,         "Password '$password' contains only wordcharacters" );
  ok( length ($password) == $length, "Password '$password' is $length characters long"   );
}

foreach my $length (1, 8) {
  my $password = $passwordUtil->generateRandomNumber($length);
  ok( $password =~ m/^\d+$/,         "Random number '$password' contains only digit characters" );
  ok( length ($password) == $length, "Random number '$password' is $length characters long"     );
}
