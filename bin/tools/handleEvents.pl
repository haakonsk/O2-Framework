use strict;
use warnings;

use O2 qw($context);
use O2::Util::Args::Simple;
my $verbosity = $ARGV{v} || 0;

if ($verbosity >= 1) {
  my $now = $context->getSingleton('O2::Mgr::DateTimeManager')->newObject();
  my $minutesOfCurrentDay = 60*$now->format('H') + $now->format('m');
  print 'Time now: ' . $now->format('HH:mm') . " ($minutesOfCurrentDay minutes since midnight)\n";
}

# Find event listeners ready to run at this time of the day:
my @eventListeners = $context->getSingleton('O2::Mgr::EventListenerManager')->getEventListenersByCurrentTimeOfDay();
printf "Num event listeners: %d\n", scalar @eventListeners if $verbosity >= 1;
exit unless @eventListeners;

# Find all new events:
my @eventIds = $context->getSingleton('O2::Mgr::EventManager')->objectIdSearch(status => 'new');
printf "Num new events: %d\n", scalar @eventIds if $verbosity >= 1;

# Handle all new events. Each event may be handled by several event listeners:
foreach my $id (@eventIds) {
  my $event = $context->getObjectById($id);
  printf "Event: %d (%s)\n", $event->getId(), $event->getMetaName() if $verbosity >= 2;
  
  my ($numOk, $numFailed) = (0, 0);
  foreach my $listener (@eventListeners) {
    my $isListening = $listener->isListeningFor($event);
    printf "  Listener %d, is listening: %s\n", $listener->getId(), ($isListening ? 'Yes' : 'No') if $verbosity >= 3;
    eval {
      $listener->handleEvent($event) if $isListening;
    };
    if ($@) {
      $numFailed++;
      my $errorMsg = sprintf "Execution of event %d with event listener %d failed: $@", $event->getId(), $listener->getId();
      warning $errorMsg;
      warn    $errorMsg;
    }
    else {
      $numOk++;
    }
  }
  
  my $status
    = $numFailed == 0 ? 'handledOk'
    : $numOk      > 0 ? 'partialError'
    :                   'handleError'
    ;
  $event->setStatus($status);
  $event->save();
}
