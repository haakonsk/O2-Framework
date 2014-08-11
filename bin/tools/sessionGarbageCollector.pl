use strict;

use O2::Context;
my $context = O2::Context->new();

use O2::Util::Args::Simple;
my $verbose = $ARGV{-verbose} || $ARGV{v};

my $customerRoot = $context->getEnv('O2CUSTOMERROOT');
my @sessionRoots = ("$customerRoot/var/sessions", "$customerRoot/var/publicSessions");
my $fileMgr = $context->getSingleton('O2::File');
my $config  = $context->getConfig();

foreach my $sessionRoot (@sessionRoots) {
  debug("Session root: $sessionRoot");
  my @files = $fileMgr->scanDirRecursive($sessionRoot, '*.ses');
  debug( sprintf '  Number of session files:         %4d', scalar @files );
  my $numDeleted = 0;
  foreach my $file (@files) {
    $file = "$sessionRoot/$file";
    if (-M $file > $config->get('frontend.session.garbageCollection.maxAgeDays')) {
      unlink $file;
      $fileMgr->rmEmptyDirs($file);
      $numDeleted++;
    }
  }
  debug( sprintf '  Number of deleted session files: %4d', $numDeleted );
}

sub debug {
  my ($msg) = @_;
  print "$msg\n" if $verbose;
}
