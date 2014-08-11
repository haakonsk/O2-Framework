package $model->getManagerClassName();

use strict;

use base '$model->getManagerSuperClassName()';

use $model->getClassName();
<o2 noExec>
#-----------------------------------------------------------------------------
sub initModel {
  my ($obj, $model) = @_;
  $obj->SUPER::initModel($model);
  $model->registerFields(
    </o2:noExec>'$model->getClassName()',
    # Your class definition goes here:
    #-----------------------------------------------------------------------------

    #-----------------------------------------------------------------------------
  );<o2 noExec>
  $model->registerIndexes(
    </o2:noExec>'$model->getClassName()',
  );
}
#-----------------------------------------------------------------------------
1;
