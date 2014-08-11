package O2::Template::Util;

use strict;

#-----------------------------------------------------------------------------
sub new {
  my ($package) = @_;
  my $obj = bless {}, $package;
  return $obj;
}
#-----------------------------------------------------------------------------
sub countCharacterInString {
  my ($obj, $char, $str) = @_;
  eval {
    $str =~ s{ [^$char] }{}xmsg;
  };
  return length $str;
}
#-----------------------------------------------------------------------------
sub countCharactersAfter {
  my ($obj, $char, $str) = @_;
  if (($str) = $str =~ m{ $char ([^$char]*) \z }xms) {
    return length $str;
  }
  return 0;
}
#-----------------------------------------------------------------------------

1;
