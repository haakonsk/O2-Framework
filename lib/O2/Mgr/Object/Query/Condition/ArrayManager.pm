package O2::Mgr::Object::Query::Condition::ArrayManager;

use strict;
use base 'O2::Mgr::Object::Query::ConditionManager';

use O2::Obj::Object::Query::Condition::Array;

#-----------------------------------------------------------------------------
sub initModel {
  my ($obj, $model) = @_;
  $obj->SUPER::initModel($model);
  $model->registerFields(
    'O2::Obj::Object::Query::Condition::Array',
    # Your class definition goes here:
    #-----------------------------------------------------------------------------
    values => { type => 'varchar', listType => 'array' },
    #-----------------------------------------------------------------------------
  );
}
#-----------------------------------------------------------------------------
1;
