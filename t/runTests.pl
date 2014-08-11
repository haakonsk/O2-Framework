use strict;
use warnings;

use O2 qw($context);

use O2::Script::Common;
use O2::Util::Args::Simple;

require O2::File;
my $fileMgr = O2::File->new();

my $currentDir = qx{pwd -L}; # -L: Don't resolve symlinks
chomp $currentDir;
my @baseDirs
  = $context->isFwPath("$currentDir/..") && $currentDir =~ m{ /t /? \z }xms
  ? map { "$_/t" } $context->getRootPaths()
  : ($currentDir)
  ;
@baseDirs = grep { -d $_ } @baseDirs;

my @files;
foreach my $dir (@baseDirs) {
  my @newFiles = $fileMgr->scanDirRecursive($dir, '*.t');
  @newFiles = grep { $_ !~ m{ \A _ }xms  &&  $_ =~ m{ [.] t \z }xms } @newFiles;
  @newFiles = map { "$dir/$_" } @newFiles;
  push @files, @newFiles;
}

my ($i, $numTests) = (0, scalar @files);
if ($ARGV{-harness}) {
  require TAP::Harness;
  my $harness = TAP::Harness->new();
  $harness->runtests(@files);
  exit;
}

say("There are $numTests tests to run");
my $ask = ask("Pause between tests? (y/N)") || 'n';
$ask    = lc $ask eq 'y';
foreach my $file (@files) {
  $i++;
  ask("\nHit return to run test '$file' ($i/$numTests)") if $ask;
  system "perl $file";
}
