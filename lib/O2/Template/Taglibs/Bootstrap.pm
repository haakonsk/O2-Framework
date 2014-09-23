package O2::Template::Taglibs::Bootstrap;

use strict;

use base 'O2::Template::Taglibs::Html';

use O2 qw($context);

#-----------------------------------------------------------------------------------
sub register {
  my ($package, %params) = @_;
  my $obj = bless { parser => $params{parser} }, $package;
  $obj->addJsFile(  file => 'bootstrap.min' );
  $obj->addCssFile( file => 'bootstrap.min' );
  return ($obj, ());
}
#-----------------------------------------------------------------------------------
1;
