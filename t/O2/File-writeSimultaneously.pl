# Helper file for O2-File.t
# This script starts an extra process with fork, and writes to the same file more or less simultaneously in both processes.

use O2 qw($context);
use O2::Util::Args::Simple;

my $fileMgr = $context->getSingleton('O2::File');

my $pid = fork; # Running two processes from this point

my $fileContent = $pid ? $ARGV{-fileContent1} : $ARGV{-fileContent2};
my $fileName    = 'o2FileTest.txt';

$fileMgr->writeFile($fileName, $fileContent);

print '<' . $fileMgr->getFile($fileName) . ">\n";
