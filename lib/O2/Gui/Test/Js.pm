package O2::Gui::Test::Js;

use strict;

use base 'O2::Gui';

use O2 qw($context);

#-----------------------------------------------------------------------------
sub init {
  my ($obj) = @_;
  my $file  = $obj->getParam('file')                                                        or die "Need 'file' parameter";
  my $jsUrl = $context->getSingleton('O2::File')->resolvePath("o2://var/www/js/t/$file.js") or die "Didn't find javascript test file: ";
  $obj->display(
    'init.html',
    jsUrl => $jsUrl,
  );
}
#-----------------------------------------------------------------------------
# Run all tests in the test directory, extract the important parts and display them to the user
sub harness {
  my ($obj) = @_;
  $obj->display(
    'harness.html',
    files => [ $obj->_getTestScriptFiles() ],
  );
}
#-----------------------------------------------------------------------------
sub _getTestScriptFiles {
  my ($obj) = @_;
  my @fullPaths = $context->getSingleton('O2::File')->scanDirRecursive('o2:var/www/js/t', '*.t.js$', scanAllO2Dirs => 1);
  my %files = map  { $_ =~ m{ ( /js/.*) }xms; $1 => 1; }  @fullPaths;
  return keys %files;
}
#-----------------------------------------------------------------------------
1;
