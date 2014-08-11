package O2::Util::String;

use strict;

use base 'Exporter';

our @EXPORT_OK = qw(trim);

#-------------------------------------------------------------------------------------
sub new {
  my ($pkg) = @_;
  bless { }, $pkg;
}
#-------------------------------------------------------------------------------------
sub trim {
  my ($str) = @_;
  $str =~ s{ \A \s+    }{}xms;
  $str =~ s{    \s+ \z }{}xms;
  return $str;
}
#-------------------------------------------------------------------------------------
sub stripTags {
  my ($obj, $html) = @_;
  $html =~ s{ < [\w/] [^>]* > }{}xmsg;
  return $html;
}
#-------------------------------------------------------------------------------------
sub textToHtml {
  my ($obj, $str, %params) = @_;
  my $target = $params{linkTarget} ? "target='$params{linkTarget}'" : '';
  
  $str =~ s{ \s+ $  }{\n}xg; # Remove spaces at the end of each line
  $str =~ s{ \r \n  }{\n}xmsg;
  $str =~ s{ \r     }{\n}xmsg;
  $str =~ s{ \n \n+ }{<br><br>}xmsg;
  $str =~ s{ \n     }{<br>}xmsg;
  $str =~ s{ <br>   }{<br>\n}xmsg;
  $str =~ s{ (https?:// .+? \w) (\W?) ( < | \s | \z ) }{<a href="$1">$1</a>$2$3}xmsg;
  
  return $str;
}
#-------------------------------------------------------------------------------------
# Return how many times each character in chars is found in the given string
# The results are returned in an array. In a scalar context the total count is returned instead.
sub countChars {
  my ($self, $str, $chars, $ignoreCase) = @_;
  if ($ignoreCase){
    $str   = lc $str;
    $chars = lc $chars;
  }
  
  my %charCount;
  my $totalCount = 0;
  for my $i (0 .. length ($chars)-1){
    my $char = substr $chars, $i, 1;
    for my $j (0 .. length ($str)-1){
      if ($char eq substr $str, $j, 1) {
        $charCount{$char}++;
        $totalCount++;
      }
    }
  }
  
  return wantarray ? %charCount : $totalCount; # Return the total count in scalar context:
}
#-------------------------------------------------------------------------------------
# Prints the given string and a newline character.
sub printLn {
  my ($self, $str) = @_;
  print "$str\n";
}
#-------------------------------------------------------------------------------------
# Substitutes all %%key%% occurrences in $template with value in @subst.
# example: subst('Hello, %%name%%!', name=>'Mr. President' ) will return "Hello, Mr. President!".
# (called substitute(), so someone may implement the old subst())
sub substitute {
  my ($obj, $template, @subst) = @_;
  $template = ref $template ? $$template : $template;
  for(my $i=0 ; $i < @subst ; $i+=2) {
      $template =~ s|\%\%$subst[$i]\%\%|$subst[$i+1]|g;
  };
  return $template;
}
#-------------------------------------------------------------------------------------
1;
