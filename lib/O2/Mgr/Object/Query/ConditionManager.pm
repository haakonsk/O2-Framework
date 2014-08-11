package O2::Mgr::Object::Query::ConditionManager;

use strict;
use base 'O2::Mgr::ObjectManager';

use O2::Obj::Object::Query::Condition;

#-----------------------------------------------------------------------------
sub initModel {
  my ($obj, $model) = @_;
  $obj->SUPER::initModel($model);
  $model->registerFields(
    'O2::Obj::Object::Query::Condition',
    # Your class definition goes here:
    #-----------------------------------------------------------------------------
    fieldName => { type => 'varchar'                                                                                  },
    operator  => { type => 'varchar'                                                                                  },
    tableName => { type => 'varchar'                                                                                  },
    listType  => { type => 'varchar', length => '5', defaultValue => 'none', validValues => ['none', 'array', 'hash'] },
    #-----------------------------------------------------------------------------
  );
}
#-----------------------------------------------------------------------------
sub save {
  my ($obj, $object) = @_;
  $object->setMetaName('Condition') unless $object->getMetaName();
  $obj->SUPER::save($object);
}
#-----------------------------------------------------------------------------
1;
