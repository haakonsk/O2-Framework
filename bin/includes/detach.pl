use strict;

use O2 qw($context);

die "Could not fork()\n" unless defined (my $pid = fork);

my $command   = $ARGV[0];
my $randomId  = $ARGV[1];
my $max       = $ARGV[2];
my $exclusive = $ARGV[3];

if ($pid) {
  $context->getDbh()->sql( 'insert into O2_BACKGROUND_PROCESS (randomId, pid, command, counter, max, exclusive, startTime) values (?, ?, ?, ?, ?, ?, ?)', $randomId, $pid, $command, 0, $max, $exclusive, time );
  exit;
}

open STDOUT, '>/dev/null' or die "Can't open /dev/null: $!";
open STDIN,  '</dev/null' or die "Can't open /dev/null: $!";

sleep 1; # Make sure the insert has been done before executing the command
system $command;
