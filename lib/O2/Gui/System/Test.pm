package O2::Gui::System::Test;

use strict;

use base 'O2::Gui';

use O2 qw($context $cgi);

#---------------------------------------------------------------------------
sub o2mlForm {
  my ($obj) = @_;
  my $pageMgr = $context->getSingleton('O2CMS::Mgr::Template::PageManager');
  warn $pageMgr->getPageTemplates();
  $obj->display('o2mlForm.html');
}
#---------------------------------------------------------------------------
sub parseO2ml {
  my ($obj) = @_;
  my $code = $obj->getParam('code');

  $cgi->setContentType('text/html');

  require O2::Template;
  my $template = O2::Template->newFromString($code);
  my $html = '';
  $html = ${ $template->parse( $context->getDisplayParams() ) } if $code;
  print $html;
}
#---------------------------------------------------------------------------
1;
