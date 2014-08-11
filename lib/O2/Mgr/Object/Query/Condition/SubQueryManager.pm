package O2::Mgr::Object::Query::Condition::SubQueryManager;

use strict;
use base 'O2::Mgr::Object::Query::ConditionManager';

use O2::Obj::Object::Query::Condition::SubQuery;

#-----------------------------------------------------------------------------
sub initModel {
  my ($obj, $model) = @_;
  $obj->SUPER::initModel($model);
  $model->registerFields(
    'O2::Obj::Object::Query::Condition::SubQuery',
    # Your class definition goes here:
    #-----------------------------------------------------------------------------
    query => { type => 'O2::Obj::Object::Query' },
    #-----------------------------------------------------------------------------
  );
}
#-----------------------------------------------------------------------------
1;
