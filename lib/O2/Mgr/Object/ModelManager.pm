package O2::Mgr::Object::ModelManager;

use O2::Obj::Object::Model;

#-----------------------------------------------------------------------------
sub new {
  my ($pkg, %params) = @_;
  return bless {}, $pkg;
}
#-----------------------------------------------------------------------------
sub newObject {
  my ($obj) = @_;
  return O2::Obj::Object::Model->new();
}
#-----------------------------------------------------------------------------
sub newObjectByClassName {
  my ($obj, $className) = @_;
  my $model = $obj->newObject();
  $model->setClassName($className);

  # Creating an object manager to be able to call initModel.
  require O2::Mgr::ObjectManager;
  my $mgr = O2::Mgr::ObjectManager->new();
  $mgr->initModel($model);

  $model->setSuperClassName('O2::Obj::Object');
  return $model;
}
#-----------------------------------------------------------------------------
1;
