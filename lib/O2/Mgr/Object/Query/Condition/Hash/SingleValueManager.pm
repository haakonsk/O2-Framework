package O2::Mgr::Object::Query::Condition::Hash::SingleValueManager;

use strict;
use base 'O2::Mgr::Object::Query::Condition::HashManager';

use O2::Obj::Object::Query::Condition::Hash::SingleValue;

#-----------------------------------------------------------------------------
sub initModel {
  my ($obj, $model) = @_;
  $obj->SUPER::initModel($model);
  $model->registerFields(
    'O2::Obj::Object::Query::Condition::Hash::SingleValue',
    # Your class definition goes here:
    #-----------------------------------------------------------------------------
    value        => { type => 'varchar'                  },
    forceNumeric => { type => 'bit', defaultValue => '0' }, # If the field we're searching in isn't a numeric field, should or shouldn't we cast to decimal?
    #-----------------------------------------------------------------------------
  );
}
#-----------------------------------------------------------------------------
1;
