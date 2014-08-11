package O2::Model::Target::Controller;

use strict;

use base 'O2::Model::Target';

#-------------------------------------------------------------------------
sub generate {
  my ($obj, $model) = @_;
  $obj->say('Generate controller');
  
  $obj->generateController(
    model        => $model, 
    templatePath => 'controller.pm',
    writePath    => 'lib/O2/Backend/Gui/' . $obj->pathifyClassName( $model->getClassName(), '/' ) . '.pm',
  );
}
#-------------------------------------------------------------------------
sub generateController {
  my ($obj, %params) = @_;
  require O2::Template;
  my $template   = O2::Template->newFromFile( $params{templatePath} );
  my $controller = $template->parse( model => $params{model} );
  
  my $path = $obj->getArg('currentRoot') . '/' . $params{writePath};
  
  if ( $obj->ask("Write $path? (y/N)?", 'n') eq 'y' ) {
    $obj->makePath($path);
    $obj->writeFile($path, $controller);
    $obj->say("Wrote $path");
  }
}
#-------------------------------------------------------------------------
1;
