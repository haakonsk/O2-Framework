package O2::Util::Crypt;

use strict;

#------------------------------------------------------------
sub crypt {
  my ($pkg, $string, $salt) = @_; 
  require Encode;
  my $bytes = Encode::encode('utf-8', $string);
  return crypt($bytes, $salt);
}
#------------------------------------------------------------
sub salt {
  return join '', ('.', '/', 0..9, 'A'..'Z', 'a'..'z')[rand 64, rand 64];
}
#------------------------------------------------------------
1;
