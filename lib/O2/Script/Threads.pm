package O2::Script::Threads;

use strict;
use warnings;

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

#-----------------------------------------------------------------------------
sub run {
  my (%params) = @_;

  $SIG{INT} = sub {
    lock($interrupted);
    $interrupted = 1;
  };

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
      O2::Script::Common::showProgress(++$counter, $total) if !exists $params{showProgress} || $params{showProgress};
      if ($interrupted) {
        print "\n";
        exit;
      }
    }
    return 1;
  }
  
  $queue = Thread::Queue->new();
  my @threads;
  
#  print "PID: $$\n";
  $queue->enqueue( @{ $params{ids} } );
  
  for my $i (1 .. $params{numThreads}) {
    my $thread = threads->create( \&_execute, $params{itemCode}, showProgress => $params{showProgress} );
    push @threads, $thread;
    $thread->detach();
  }
  
  # Make sure main thread doesn't exit before all other threads are done
  sleep 1 while ($queue->pending() && !$interrupted);
  return $interrupted ? 0 : 1;
}
#-----------------------------------------------------------------------------
sub _execute {
  my ($code, %params) = @_;
  my $context = O2::Context->new();
  while ($queue->pending() && (my $id = $queue->dequeue())) {
    warn "Breaking out!" if $interrupted;
    last if $interrupted;
    
    {
      lock($counter);
      $counter++;
    }
    O2::Script::Common::showProgress($counter, $total)  if (!exists $params{showProgress} || $params{showProgress})  &&  threads->tid() == 1;
    $code->($context, $id);
  }
}
#-----------------------------------------------------------------------------
1;
