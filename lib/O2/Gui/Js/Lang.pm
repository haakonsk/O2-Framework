package O2::Gui::Js::Lang;

use strict;

use base 'O2::Gui';

use O2 qw($context $cgi);

#-----------------------------------------------------------------------------
sub init {
  my ($obj) = @_;
  my $file   = $obj->getParam('file');
  my $prefix = $file;
  $prefix    =~ s{ / }{.}xmsg;
  my $localeCode = $obj->getLang()->getLocale();
  my %hash = $context->getSingleton('O2::Lang::I18NManager')->getResourceHash($prefix);
  
  my $js = "var prefix = \"$prefix\";
o2.lang = o2.lang || new O2Lang('$localeCode');
var languageVariables = {\n";
  $js .= $obj->_getJsVars(\%hash, '');
  $js  = substr $js, 0, -2 if %hash;
  $js .= "\n};\n";
  $js .= "for (var key in languageVariables) {
  o2.lang.setString(prefix + '.' + key, languageVariables[key]);
}";
  
  $cgi->setContentType('text/javascript; charset=' . $cgi->getCharacterSet() );
  $cgi->addHeader('Cache-Control', 'no-cache');
  print $js;
}
#-----------------------------------------------------------------------------
sub _getJsVars {
  my ($obj, $hashRef, $prefix) = @_;
  $prefix = "$prefix." if $prefix;
  my $js = '';
  foreach my $key (keys %{$hashRef}) {
    if (ref $hashRef->{$key}) {
      $js .= $obj->_getJsVars($hashRef->{$key}, "$prefix$key");
    }
    else {
      my $value = $hashRef->{$key};
      $value    =~ s{ \' }{\\\'}xmsg;
      $value    =~ s{ \n }{\\n}xmsg;
      $js .= "  '$prefix$key' : '$value',\n";
    }
  }
  return $js;
}
#-----------------------------------------------------------------------------
1;
