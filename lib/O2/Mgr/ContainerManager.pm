package O2::Mgr::ContainerManager;

use strict;

use base 'O2::Mgr::ObjectManager';

use O2::Obj::Container;

#-------------------------------------------------------------------------------
sub initModel {
  my ($obj, $model) = @_;
  $obj->SUPER::initModel($model);
  $model->registerFields(
    'O2::Obj::Container',
    # Your class definition goes here:
    #-----------------------------------------------------------------------------
    #-----------------------------------------------------------------------------
  );
}
#-------------------------------------------------------------------------------
1;
