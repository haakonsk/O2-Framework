package O2::Template::Taglibs::Js::Lang;

use strict;

use base 'O2::Template::Taglibs::Html';

use O2 qw($context);

#-----------------------------------------------------------------------------
sub register { # Method called by the tag-parser to see what and how methods should be called
  my ($package, %params) = @_;
  my %methods = (
    addJsLangFile => '',
  );

  my $obj = bless { parser => $params{parser} }, $package;
  $obj->addJsFile( file => 'O2Lang' );
  return $obj, %methods;
}
#-----------------------------------------------------------------------------
sub addJsLangFile {
  my ($obj, %params) = @_;
  $obj->addJsFile( file => ($context->isBackend() ? '/o2cms/' : '/o2/') . "Js-Lang?file=$params{file}" );
}
#-----------------------------------------------------------------------------
1;
