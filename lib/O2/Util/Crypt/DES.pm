package O2::Util::Crypt::DES;

# Encrypt a string with DES alg and a key

use strict;

use base 'O2::Util::Crypt::Base';

#----------------------------------------------------
sub encrypt {
  my ($obj,%params)=@_;
  require Crypt::DES;
  my $key = pack("H16", $params{key});
  my $cipher = new Crypt::DES $key;
  
  my $cipherText='';
  my $index=0;
  my $blockSize = 8;
  while( my $subStr = substr($params{string},$index,$blockSize) ) {
    {
        use bytes;
        my $l=bytes::length($subStr);
        if(bytes::length($subStr) < 8) {
          $subStr.=' ' x (8-$l);
        }
    } 
    $index+=$blockSize;
    my $cText = $cipher->encrypt($subStr);
    $cipherText.=unpack("H16", $cText);
    last unless $subStr;
  } 
  return $cipherText;
}
#----------------------------------------------------
sub decrypt {
  my ($obj,%params)=@_;
  require Crypt::DES;
  my $key = pack("H16", $params{key});
  my $cipher = new Crypt::DES $key;

  my $decrypted='';
  my $blockSize = 16;
  my $index=0;
  while( my $subStr = substr($params{string},$index,$blockSize) ) {
    my $encrypted = pack("H16", $subStr);
    my $tmpDecrypted=$cipher->decrypt($encrypted);
    $tmpDecrypted=~s/\s+$//; #XXX this is not elegant or very good
    $decrypted.=$tmpDecrypted;
    $index+=$blockSize;
    last unless $subStr;
  }
  return $decrypted;
}
#----------------------------------------------------
1;
