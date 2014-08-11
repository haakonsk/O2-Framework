# Helper file for O2-File.t
# This script starts an extra process with fork, and appends to the same file more or less simultaneously in both processes.

use O2 qw($context);
use O2::Util::Args::Simple;

my $fileMgr = $context->getSingleton('O2::File');

my $pid = fork; # Running two processes from this point

for my $i (1 .. $ARGV{-numChars}) {
  $fileMgr->appendFile(  $ARGV{-fileName},  $i % 10  );
}

print '<' . $fileMgr->getFile( $ARGV{-fileName} ) . ">\n";
