package O2::Mgr::Object::Query::Condition::HashManager;

use strict;
use base 'O2::Mgr::Object::Query::ConditionManager';

use O2::Obj::Object::Query::Condition::Hash;

#-----------------------------------------------------------------------------
sub initModel {
  my ($obj, $model) = @_;
  $obj->SUPER::initModel($model);
  $model->registerFields(
    'O2::Obj::Object::Query::Condition::Hash',
    # Your class definition goes here:
    #-----------------------------------------------------------------------------
    hashKey => { type => 'varchar' },
    #-----------------------------------------------------------------------------
  );
}
#-----------------------------------------------------------------------------
1;
