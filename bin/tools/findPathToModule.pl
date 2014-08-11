use strict;
use warnings;

if (@ARGV && $ARGV[0] eq '--help') {
  print "\nUsage:\n";
  print "  perl $0\n";
  print "  perl $0 <module>\n";
  print "Example:\n";
  print "  perl $0 SWISH::API\n\n";
  exit;
}

my $module = $ARGV[0] || ask('Module:');
my $pathifiedModule = $module;
$pathifiedModule    =~ s{ :: }{/}xmsg;
$pathifiedModule   .= '.pm';

foreach my $path (@INC) {
  if (-e "$path/$pathifiedModule") {
    print "$path/$pathifiedModule\n";
    exit;
  }
}

print "Didn't find path to $module\n";

#-----------------------------------------------------------------------------
sub ask {
  my ($question, $mustAnswer) = @_;
  my $answer;
  do {
    print $question . ' ';
    $answer = <STDIN>;
    chomp $answer;
  } while ($mustAnswer && !$answer);
  return $answer;
}
#-----------------------------------------------------------------------------
