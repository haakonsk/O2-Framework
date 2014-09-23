package O2::Gui::System::Test;

use strict;

use base 'O2::Gui';

use O2 qw($context $cgi $config);

#---------------------------------------------------------------------------
sub o2mlForm {
  my ($obj) = @_;
  $obj->display(
    'o2mlForm.html',
    pageTemplates => [ $context->getSingleton('O2CMS::Mgr::Template::PageManager')->getPageTemplates() ],
  );
}
#---------------------------------------------------------------------------
sub parseO2ml {
  my ($obj) = @_;
  my $code           = $obj->getParam('code');
  my $pageTemplateId = $obj->getParam('pageTemplateId');

  $cgi->setContentType('text/html');

  require O2::Template;
  my $template = O2::Template->newFromString($code);
  my $html = '';
  $html = ${ $template->parse( $context->getDisplayParams() ) } if $code;
  return print $html unless $pageTemplateId;

  my $tmpPath = $config->get('setup.tmpDir') . '/' . $context->getSingleton('O2::Util::Password')->generatePassword() . '.html';
  $context->getSingleton('O2::File')->writeFile($tmpPath, $html);
  my $pageTemplate = $context->getObjectById($pageTemplateId);

  if ($context->cmsIsEnabled()) {
    my $pageTemplatePath = $pageTemplate->getFullPath();
    $pageTemplatePath    =~ s{ \A .* /frontend/pages }{/Templates/pages}xms;
    $obj->displayPage(
      $tmpPath,
      pageTemplatePath => $pageTemplatePath,
      $context->getDisplayParams(),
    );
  }
  else {
    $obj->displayPage(
      $tmpPath,
      pageTemplate => $pageTemplate->getFullPath(),
      $context->getDisplayParams(),
    );
  }

}
#---------------------------------------------------------------------------
1;
