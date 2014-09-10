package O2::Script::Threads;

use strict;

$| = 1;

use threads;
use threads::shared;
use Thread::Queue;
use Config;
$Config{useithreads} or die 'Recompile Perl with threads to run this program';
use Time::HiRes qw(sleep);
use O2::Script::Common;
use O2::Context;

my $interrupted :shared = 0;
my $counter     :shared = 0;
my $queue;
my $total;

$SIG{INT} = sub {
  lock($interrupted);
  $interrupted = 1;
};

#-----------------------------------------------------------------------------
sub run {
  my (%params) = @_;
  my @ids = @{ $params{ids} };
  $total = @ids;
  
  $interrupted = 0;
  $counter     = 0;
  
  my $numThreads = $ARGV{numThreads} || 2;
  if ($numThreads == 1) {
    my $context = O2::Context->new();
    my $counter = 0;
    foreach my $id (@ids) {
      $params{itemCode}->($context, $id);
      O2::Script::Common::showProgress(++$counter, $total);
      if ($interrupted) {
        print "\n";
        exit;
      }
    }
    return;
  }
  
  $queue = Thread::Queue->new();
  my @threads;
  
#  print "PID: $$\n";
  $queue->enqueue( @{ $params{ids} } );
  
  for my $i (1 .. $params{numThreads}) {
    my $thread = threads->create( \&_execute, $params{itemCode} );
    push @threads, $thread;
    $thread->detach();
  }
  
  # Make sure main thread doesn't exit before all other threads are done
  sleep 1 while ($queue->pending() && !$interrupted);
  print "\nDONE\n";
}
#-----------------------------------------------------------------------------
sub _execute {
  my ($code) = @_;
  my $context = O2::Context->new();
  while ($queue->pending() && (my $id = $queue->dequeue())) {
    warn "Breaking out!" if $interrupted;
    last if $interrupted;
    
    {
      lock($counter);
      $counter++;
    }
    O2::Script::Common::showProgress($counter, $total) if threads->tid() == 1;
    $code->($context, $id);
  }
}
#-----------------------------------------------------------------------------
1;
