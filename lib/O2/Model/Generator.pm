package O2::Model::Generator;

use strict;

use O2::Obj::Object::Model;

#-----------------------------------------------------------------------------
sub new {
  my ($pkg, %init) = @_;
  return bless \%init, $pkg;
}
#-----------------------------------------------------------------------------
sub generate {
  my ($obj, $type, %args) = @_;
  $type = ucfirst $type;
  my $target = $obj->instantiateClass("O2::Model::Target::$type");
  die "Could not create target handler class: $@" if $@;

  my $model;
  if ($type eq 'Skeleton') {
    # no manager class to ask for model yet
    $model = O2::Obj::Object::Model->new();
    $model->setClassName( $args{className} );
  }
  else {
    $model = $obj->getModel( $args{className} );
  }

  $model->setSuperClassName( $args{superClassName} ) if $args{superClassName};
  $target->setArgs(%args);
  return $target->generate($model);
}
#-----------------------------------------------------------------------------
sub getModel {
  my ($obj, $className) = @_;
  $className  =~ s{::Obj::}{::Mgr::}xms;
  $className .= 'Manager';
  my $manager = $obj->instantiateClass($className);
  return $manager->getModel();
}
#-----------------------------------------------------------------------------
sub instantiateClass {
  my ($obj, $class, %args) = @_;

  eval "require $class;";
  die "Could not load class '$class': $@" if $@;
  
  my $object = eval { $class->new(%args); };
  die "Could not instantiate class '$class': $@" if $@;
  
  return $object;
}
#-----------------------------------------------------------------------------
1;
