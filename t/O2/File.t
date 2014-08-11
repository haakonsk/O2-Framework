use strict;

use Test::More qw(no_plan);
use O2 qw($context);

my $fileName = 'o2FileTest.txt';
my $fileContent1 = join '', (  1 .. 10 );
my $fileContent2 = join '', ('a' .. 'z');

# writeFile
my $numTimes = 100;
for my $i (1 .. $numTimes) {
  my $output = `perl $ENV{O2ROOT}/t/O2/File-writeSimultaneously.pl --fileName $fileName --fileContent1 $fileContent1 --fileContent2 $fileContent2`;
  my ($newFileContent1, $newFileContent2) = $output =~ m{ < (.*) > \n < (.*) > }xms;
  if ($newFileContent1 ne $fileContent1  &&  $newFileContent1 ne $fileContent2) {
    ok(0, "Both processes wrote to the same file at the same time ($i) - $newFileContent1");
    exit;
  }
  if ($newFileContent2 ne $fileContent1  &&  $newFileContent2 ne $fileContent2) {
    ok(0, "Both processes wrote to the same file at the same time ($i) - $newFileContent2");
    exit;
  }
}
ok(1, "Simultaneous  writes to the same file seems to work.. Worked $numTimes times in a row.");


my $fileMgr = $context->getSingleton('O2::File');


# appendFile
my $numChars = 200;
for my $i (1 .. $numTimes) {
  $fileMgr->writeFile($fileName, '');
  my $output = `perl $ENV{O2ROOT}/t/O2/File-appendSimultaneously.pl --fileName $fileName --numChars $numChars`;
  my ($newFileContent1, $newFileContent2) = $output =~ m{ < (.*) > \n < (.*) > }xms;
  if ( length $newFileContent1  !=  2*$numChars   &&   length $newFileContent2  !=  2*$numChars ) {
    ok(0, "Some problem with appendFile ($i) File lengths: " . length($newFileContent1) . ', ' . length($newFileContent2));
    exit;
  }
}
ok(1, "Simultaneous appends to the same file seems to work.. Worked $numTimes times in a row.");

# Make sure we can't create a file with the same name as an existing file, but different casing:
my $fileNameUc = uc $fileName;
eval {
  $context->getSingleton('O2::File')->writeFile($fileNameUc, 'abcabc');
};
ok($@, "Test died as it should: $@");

sub END {
  unlink $fileName;
  unlink $fileNameUc if -f $fileNameUc;
}
