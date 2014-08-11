package O2::Model::Target::RegisterClass;

use strict;
use base 'O2::Model::Target';

use O2 qw($context);

#-----------------------------------------------------------------------------
sub getUnregisteredSuperClassName {
  my ($obj, $model) = @_;
  my $classMgr = $context->getSingleton('O2::Mgr::ClassManager');
  my (@superClasses) = $classMgr->getSuperClassNamesByClassName( $model->getClassName() );
  foreach my $superClassName (@superClasses) {
    next if $superClassName !~ m{ ::Obj:: }xms;
    my $superClass = $classMgr->getObjectByClassName($superClassName);
    return $superClassName if !$superClass;
  }
  return '';
}
#-----------------------------------------------------------------------------
sub generate {
  my ($obj, $model, %params) = @_; # If params isn't given, then assume we're running a script and ask for settings, otherwise take settings from params

  my $classMgr = $context->getSingleton('O2::Mgr::ClassManager');

  if (my $superClassName = $obj->getUnregisteredSuperClassName($model)) {
    my $msg = "Superclass $superClassName must be registered before " . $model->getClassName();
    die $msg if %params;
    print "$msg\n";
    exit;
  }

  my $class = $classMgr->getObjectByClassName( $model->getClassName() );
  if (!$class) {
    $class = $classMgr->newObject();
    $class->setClassName( $model->getClassName() );
  }
  $obj->say( "\n" . ($class ? "Update class " : "Create class ") . $model->getClassName() . "\n" );

  my ($editUrl, $editTemplate, $newUrl);
  if (%params) {
    $class->setEditUrl(                        $params{editUrl}                       );
    $class->setEditTemplate(                   $params{editTemplate}                  );
    $class->setNewUrl(                         $params{newUrl}                        );
    $class->setIsCreatableInO2cms(             $params{isCreatableInO2cms}            );
    $class->setCanBeCreatedUnderCategories( @{ $params{canBeCreatedUnderCategories} } );
  }
  else {
    # Ask for editUrl
    my $question = 'editUrl?      ';
    $question   .= '(default: ' . $class->getEditUrl() . ') ' if $class->getEditUrl();
    $editUrl = $obj->ask($question);
    if ($editUrl) {
      $editUrl = undef if $editUrl eq 'null';
      $class->setEditUrl($editUrl);
    }

    # Ask for editTemplate
    $question = 'editTemplate? ';
    $question   .= '(default: ' . $class->getEditTemplate() . ') ' if $class->getEditTemplate();
    $editTemplate = $obj->ask($question);
    if ($editTemplate) {
      $editTemplate = undef if $editTemplate eq 'null';
      $class->setEditTemplate($editTemplate);
    }

    # Ask for newUrl
    $question  = 'newUrl?       ';
    $question .= '(default: ' . $class->getNewUrl() . ') ' if $class->getNewUrl();
    $newUrl = $obj->ask($question);
    if ($newUrl) {
      $newUrl = undef if $newUrl eq 'null';
      $class->setNewUrl($newUrl);
    }
  }

  $class->setClassName( $model->getClassName() );
  $class->save();
  $obj->say("Saved\n", %params);
}
#-----------------------------------------------------------------------------
1;
