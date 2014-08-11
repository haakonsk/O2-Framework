use strict;
use warnings;

use O2 qw($context);
use O2::Util::Args::Simple;
my $verbosity = $ARGV{v} || 0;

my $fileMgr          = $context->getSingleton('O2::File');
my $eventListenerMgr = $context->getSingleton('O2::Mgr::EventListenerManager');

my %seenEventListenerIds;

foreach my $path ($fileMgr->resolveExistingPaths('o2:etc/conf/eventHandlers.conf')) {
  print "Reading $path\n" if $verbosity >= 3;
  foreach my $handler (@{ do $path }) {
    my %searchParams = (
      listenForEventName => $handler->{match}->{eventName},
      handlerClassName   => $handler->{handler}->{className},
      handlerMethodName  => $handler->{handler}->{methodName},
      runIntervalMinutes => $handler->{runIntervalMinutes},
    );
    $searchParams{listenForObjectId}  = $handler->{match}->{objectId}  if defined $handler->{match}->{objectId};
    $searchParams{listenForParentId}  = $handler->{match}->{parentId}  if defined $handler->{match}->{parentId};
    $searchParams{listenForOwnerId}   = $handler->{match}->{ownerId}   if defined $handler->{match}->{ownerId};
    $searchParams{listenForClassName} = $handler->{match}->{className} if defined $handler->{match}->{className};
    $searchParams{listenForStatus}    = $handler->{match}->{status}    if defined $handler->{match}->{status};
    $searchParams{priority}           = $handler->{priority}           if defined $handler->{priority};
    $searchParams{-debug}             = 1                              if $verbosity >= 3;
    
    my ($eventListenerId) = $eventListenerMgr->objectIdSearch(%searchParams);
    if ($eventListenerId) { # Already exists
      print "Event listener '$handler->{match}->{eventName}' ($eventListenerId) already exists\n" if $verbosity >= 2;
      $seenEventListenerIds{$eventListenerId} = 1;
      next;
    }
    
    my $eventListener = $eventListenerMgr->newObject();
    $eventListener->setMetaName(           $handler->{match}->{eventName}    );
    $eventListener->setListenForEventName( $handler->{match}->{eventName}    );
    $eventListener->setListenForObjectId(  $handler->{match}->{objectId}     );
    $eventListener->setListenForParentId(  $handler->{match}->{parentId}     );
    $eventListener->setListenForOwnerId(   $handler->{match}->{ownerId}      );
    $eventListener->setListenForClassName( $handler->{match}->{className}    );
    $eventListener->setListenForStatus(    $handler->{match}->{status}       );
    $eventListener->setHandlerClassName(   $handler->{handler}->{className}  );
    $eventListener->setHandlerMethodName(  $handler->{handler}->{methodName} );
    $eventListener->setPriority(           $handler->{priority}              ) if defined $handler->{priority};
    $eventListener->setRunIntervalMinutes( $handler->{runIntervalMinutes}    );
    $eventListener->save();
    $seenEventListenerIds{ $eventListener->getId() } = 1;
    print "Created event listener '$handler->{match}->{eventName}', ID: " . $eventListener->getId() . "\n" if $verbosity >= 1;
  }
}

# Delete event listeners not present in any of the eventHandlers.conf files:
foreach my $eventListenerId ($eventListenerMgr->objectIdSearch()) {
  next if $seenEventListenerIds{$eventListenerId};
  
  my $eventListener = $context->getObjectById($eventListenerId);
  if ($eventListener) {
    printf "Deleting event listener '%s' ($eventListenerId)\n", $eventListener->getListenForEventName() if $verbosity >= 1;
    $eventListener->deletePermanently();
  }
}
