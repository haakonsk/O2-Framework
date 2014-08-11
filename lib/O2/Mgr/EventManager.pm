package O2::Mgr::EventManager;

use strict;

use base 'O2::Mgr::ObjectManager';

use O2::Obj::Event;

#-----------------------------------------------------------------------------
sub initModel {
  my ($obj, $model) = @_;
  $obj->SUPER::initModel($model);
  $model->registerFields(
    'O2::Obj::Event',
    # Your class definition goes here:
    #-----------------------------------------------------------------------------
    callerObjectId  => { type => 'O2::Obj::Object'                                                                                    },
    callerParentId  => { type => 'O2::Obj::Object'                                                                                    },
    callerOwnerId   => { type => 'O2::Obj::Person'                                                                                    },
    callerClassName => { type => 'varchar'                                                                                            },
    callerStatus    => { type => 'varchar'                                                                                            },
    callerEventName => { type => 'varchar'                                                                                            },
    status          => { type => 'varchar', defaultValue => 'new', validValues => ['new', 'handledOk', 'partialError', 'handleError'] },
    params          => { type => 'varchar', listType => 'hash'                                                                        },
    #-----------------------------------------------------------------------------
  );
}
#-----------------------------------------------------------------------------
1;
