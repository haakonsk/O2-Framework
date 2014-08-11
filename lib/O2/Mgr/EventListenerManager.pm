package O2::Mgr::EventListenerManager;

use strict;

use base 'O2::Mgr::ObjectManager';

use O2 qw($context $db);
use O2::Obj::EventListener;

#-----------------------------------------------------------------------------
sub initModel {
  my ($obj, $model) = @_;
  $obj->SUPER::initModel($model);
  $model->registerFields(
    'O2::Obj::EventListener',
    # Your class definition goes here:
    #-----------------------------------------------------------------------------
    listenForEventName => { type => 'varchar'                  },
    listenForObjectId  => { type => 'O2::Obj::Object'          },
    listenForParentId  => { type => 'O2::Obj::Object'          },
    listenForOwnerId   => { type => 'O2::Obj::Person'          },
    listenForClassName => { type => 'varchar'                  },
    listenForStatus    => { type => 'varchar'                  },
    handlerClassName   => { type => 'varchar'                  },
    handlerMethodName  => { type => 'varchar'                  },
    priority           => { type => 'int', defaultValue => 999 },
    runIntervalMinutes => { type => 'int', notNull => 1        }, # Must be between 1 and 24*60 = 1440, inclusive
    #-----------------------------------------------------------------------------
  );
}
#-----------------------------------------------------------------------------
sub raiseEvent {
  my ($obj, $eventName, $object, %params) = @_;
  my $event = $context->getSingleton('O2::Mgr::EventManager')->newObject();
  $event->setMetaName(        $eventName                  );
  $event->setCallerObjectId(  $object->getId()            );
  $event->setCallerParentId(  $object->getMetaParentId()  );
  $event->setCallerOwnerId(   $object->getMetaOwnerId()   );
  $event->setCallerClassName( $object->getMetaClassName() );
  $event->setCallerStatus(    $object->getMetaStatus()    );
  $event->setCallerEventName( $eventName                  );
  $event->save();
}
#-----------------------------------------------------------------------------
sub newEventExists {
  my ($obj, $eventName, $object) = @_;
  my ($eventId) = $context->getSingleton('O2::Mgr::EventManager')->objectIdSearch(
    status          => 'new',
    callerEventName => $eventName,
    callerObjectId  => $object->getId(),
    -limit          => 1,
  );
  return $eventId ? 1 : 0;
}
#-----------------------------------------------------------------------------
sub getEventListenersByCurrentTimeOfDay {
  my ($obj) = @_;
  my $now = $context->getSingleton('O2::Mgr::DateTimeManager')->newObject();
  my $minutesOfCurrentDay = 60*$now->format('H') + $now->format('m');
  $minutesOfCurrentDay    = 24*60 if $minutesOfCurrentDay == 0;
  return grep  { $minutesOfCurrentDay % $_->getRunIntervalMinutes() == 0 }  $obj->objectSearch();
}
#-----------------------------------------------------------------------------
1;
