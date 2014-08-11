package O2::Mgr::Object::Query::Condition::Hash::MultiValueManager;

use strict;
use base 'O2::Mgr::Object::Query::Condition::HashManager';

use O2::Obj::Object::Query::Condition::Hash::MultiValue;

#-----------------------------------------------------------------------------
sub initModel {
  my ($obj, $model) = @_;
  $obj->SUPER::initModel($model);
  $model->registerFields(
    'O2::Obj::Object::Query::Condition::Hash::MultiValue',
    # Your class definition goes here:
    #-----------------------------------------------------------------------------
    values => { type => 'varchar', listType => 'array' },
    #-----------------------------------------------------------------------------
  );
}
#-----------------------------------------------------------------------------
1;
