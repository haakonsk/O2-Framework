package O2::Obj::EventListener;

use strict;

use base 'O2::Obj::Object';

use O2 qw($context);

#-----------------------------------------------------------------------------
sub isListeningFor {
  my ($obj, $event) = @_;
  return 0 if                                  $obj->getListenForEventName() ne $event->getCallerEventName();
  return 0 if $obj->getListenForObjectId()  && $obj->getListenForObjectId()  != $event->getCallerObjectId();
  return 0 if $obj->getListenForParentId()  && $obj->getListenForParentId()  != $event->getCallerParentId();
  return 0 if $obj->getListenForOwnerId()   && $obj->getListenForOwnerId()   != $event->getCallerOwnerId();
  
  my $objectIntrospect = $context->getSingleton('O2::Util::ObjectIntrospect');
  $objectIntrospect->setClass( $event->getCallerClassName() );
  return 0 if $obj->getListenForClassName() && !$objectIntrospect->inheritsFrom( $obj->getListenForClassName() );
  return 0 if $obj->getListenForStatus()    && $obj->getListenForStatus()    ne $event->getCallerStatus();
  return 1;
}
#-----------------------------------------------------------------------------
sub handleEvent {
  my ($obj, $event) = @_;
  return unless $obj->isListeningFor($event);
  
  my $method = $obj->getHandlerMethodName();
  $context->getSingleton( $obj->getHandlerClassName() )->$method($event);
}
#-----------------------------------------------------------------------------
1;
