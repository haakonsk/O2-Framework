package O2::Util::Password;

use strict;

# Methods for handling passwords
#---------------------------------------------------------------------------------------------------------------------------------------------------
sub new {
  my ($pkg, %init) = @_;
  return bless \%init, $pkg;
}
#---------------------------------------------------------------------------------------------------------------------------------------------------
# returns random passord of $length characters. avoids characterss that loook the same (like 0O, Il1, 5S or B8)
sub generatePassword {
  my ($obj, $length, $chars) = @_;
  $length ||= 6;
  my $password = '';
  $chars ||= "abcdefghjkmnpqrstuvwxyz679";
  foreach my $i (1..$length) {
    $password .= substr $chars, int(rand length $chars), 1;
  }
  return $password;
}
#---------------------------------------------------------------------------------------------------------------------------------------------------
sub generateRandomNumber {
  my ($obj, $length) = @_;
  return $obj->generatePassword($length, '0123456789');
}
#---------------------------------------------------------------------------------------------------------------------------------------------------

1;
