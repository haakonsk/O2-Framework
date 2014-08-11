package O2::Model::Target::Skeleton;

use strict;

use base 'O2::Model::Target';

use O2 qw($context);

#-----------------------------------------------------------------------------
sub generate {
  my ($obj, $model, %params) = @_;

  if (!$params{beQuiet}) {
    $obj->say("Generate skeleton");
    $obj->say("lib root: ".$obj->getArg('currentRoot'));
  }

  my $o2Root = $context->getEnv('O2ROOT');
  $obj->generateClass( $model, "$o2Root/lib/includes/managerClass.pm", $model->getManagerClassName(), $params{beQuiet} ) unless $params{dontCreateManager};
  $obj->generateClass( $model, "$o2Root/lib/includes/class.pm",        $model->getClassName(),        $params{beQuiet} ) unless $params{dontCreateObject};
}
#-----------------------------------------------------------------------------
sub generateClass {
  my ($obj, $model, $templatePath, $className, $beQuiet) = @_;

  print "templatePath: $templatePath\nClassName: $className\n" unless $beQuiet;

  require O2::Template;
  my $template = O2::Template->newFromFile($templatePath);

  my $path = $obj->getArg('currentRoot') . '/lib/' . $obj->pathifyClassName($className, '/') . '.pm';

  my $perl
    = -e $path && $className eq $obj->getArg('className')
    ? $context->getSingleton('O2::File')->getFileRef($path)
    : $template->parse(model => $model)
    ;

  if ( $beQuiet  ||  $obj->ask("Write $path? (y/N)?", 'n') eq 'y' ) {
    $obj->makePath($path);
    $obj->writeFile($path, $perl);
    $obj->say("Wrote $path");
  }

  if (-e $path && $className eq $obj->getArg('className')) {
    my $object;
    my $universalMgr = $context->getSingleton('O2::Mgr::UniversalManager');
    $object = $universalMgr->newObjectByClassName($className);
    $obj->say("Your object is/can the following:");
    $obj->say(' canMove:         ' . $object->canMove()         );
    $obj->say(' isDeletable:     ' . $object->isDeletable()     );
    $obj->say(' isSerializable:  ' . $object->isSerializable()  );
    $obj->say(' isContainer:     ' . $object->isContainer()     );
    $obj->say(' canAddObject:    ' . $object->canAddObject()    );
    $obj->say(' canRemoveObject: ' . $object->canRemoveObject() );
    $obj->say(' isSearchable:    ' . $object->isSearchable()    );
    $obj->say(' isPublishable:   ' . $object->isPublishable()   );
    if (!$beQuiet && $obj->ask('Edit any of these values? (y/N)', 'n') eq 'y') {
      $perl = $obj->editMethod('canMove',         $object, $perl);
      $perl = $obj->editMethod('isDeletable',     $object, $perl);
      $perl = $obj->editMethod('isSerializable',  $object, $perl);
      $perl = $obj->editMethod('isContainer',     $object, $perl);
      $perl = $obj->editMethod('canAddObject',    $object, $perl);
      $perl = $obj->editMethod('canRemoveObject', $object, $perl);
      $perl = $obj->editMethod('isSearchable',    $object, $perl);
      $perl = $obj->editMethod('isPublishable',   $object, $perl);
      if ( $obj->ask("Write $path? (y/N)?", 'n') eq 'y' ) {
        $obj->writeFile($path, $perl);
        $obj->say("Wrote $path");
      }
    }
  }
  print ${$perl} if $obj->getArg('print') && $className eq $obj->getArg('className') && !$beQuiet;
}
#-----------------------------------------------------------------------------
sub editMethod {
  my ($obj, $method, $object, $perlRef) = @_;
  my $y          = $object->$method() ? 'Y' : 'y';
  my $n          = $object->$method() ? 'n' : 'N';
  my $oldValue   = $object->$method() ?  1  :  0;
  my $default    = $object->$method() ? 'y' : 'n';
  my $notDefault = $object->$method() ? 'n' : 'y';
  if ($obj->ask("$method? ($y/$n)", $default) eq $notDefault) {
    my $newValue = $oldValue ? "0" : "1";
    my $perl = ${$perlRef};
    if ($perl =~ m{  sub \s+ $method \s* \{ .*? return \s+  $oldValue  .*? \}  }xms) {
      $perl   =~ s{ (sub \s+ $method \s* \{ .*? return \s+) $oldValue (.*? \}) }{$1$newValue$2}xms;
    }
    else {
      my $methodCode = "sub $method {\n  return $newValue;\n}\n#-----------------------------------------------------------------------------";
      $perl =~ s{ 1;\s* \z }{$methodCode\n1;\n}xms;
    }
    $perlRef = \$perl;
  }
  return $perlRef;
}
#-----------------------------------------------------------------------------
1;
