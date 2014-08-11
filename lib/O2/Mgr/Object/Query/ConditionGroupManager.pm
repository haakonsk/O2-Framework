package O2::Mgr::Object::Query::ConditionGroupManager;

use strict;
use base 'O2::Mgr::ObjectManager';

use O2::Obj::Object::Query::ConditionGroup;

#-----------------------------------------------------------------------------
sub initModel {
  my ($obj, $model) = @_;
  $obj->SUPER::initModel($model);
  $model->registerFields(
    'O2::Obj::Object::Query::ConditionGroup',
    # Your class definition goes here:
    #-----------------------------------------------------------------------------
    conditions => { type => 'O2::Obj::Object::Query::Condition', listType => 'array' },
    joinWith   => { type => 'varchar', length => '3', defaultValue => 'and'          },
    #-----------------------------------------------------------------------------
  );
}
#-----------------------------------------------------------------------------
sub save {
  my ($obj, $object) = @_;
  $object->setMetaName('Condition group') unless $object->getMetaName();
  $obj->SUPER::save($object);
}
#-----------------------------------------------------------------------------
1;
