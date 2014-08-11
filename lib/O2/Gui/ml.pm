package O2::Gui::ml;

# A package for allowing standalone O2ML-applications

use strict;

use base 'O2::Gui';

use O2 qw($context $cgi $config);

#------------------------------------------------------------------------------------------------------------
# Init and default method. Handles the request, finds the file to be processed
# and tries to wrap this in a page-template
sub init {
  my ($obj) = @_;
  
  my $documentRoot = $config->get('o2.documentRoot') or die "No site root specified\n";
  
  my $o2PageTemplate = $obj->getParam('o2PageTemplate') || '';
  
  my $file      = $cgi->deleteParam('o2mlFileName');
  my @fileParts = split /\//, $file;
  my $fileName  = pop @fileParts;
  my $filePath;
  my $isFrontendGuiUrl = @fileParts && shift @fileParts eq 'o2';
  if ($isFrontendGuiUrl) { # Like /o2/Test-MyGuiModule/test.o2ml
    die "Couldn't parse url: /$file" if @fileParts != 1;
    
    my $guiClass = $fileParts[0];
    $guiClass    =~ s{-}{::}g;
    $filePath = $obj->resolveTemplatePath($fileName, $guiClass);
  }
  else { # Like /dir1/dir2/test.o2ml
    $filePath = "$documentRoot/$file";
  }
  $filePath =~ s{//}{/}g;
  
  return $obj->error( "Illegal filename: $fileName" )     if $fileName !~ m{^[-_.\w]+\.o2ml$}; # XXX Something more advisory perhaps? Maybe a HTTP STATUS CODE 400 Bad Request?
  return $obj->error( "File not found: $filePath"   ) unless -f $filePath;                     # XXX Something more advisory perhaps? Maybe a HTTP STATUS CODE 404 Not Found?
  
  return $obj->display($filePath) if $o2PageTemplate eq 'none' || (!$o2PageTemplate && $isFrontendGuiUrl) || !$context->cmsIsEnabled();
  
  if (!$o2PageTemplate) {
    my $url       = $context->getEnv('SCRIPT_URI');
    my $urlMapper = $context->getSingleton('O2CMS::Publisher::UrlMapper');
    my $resolvedUrl = eval {
      $urlMapper->resolveUrl($url);
    };
    $cgi->error("Unable to resolve url \"$url\": $@") if $@;
    my $propertyMgr    = $context->getSingleton('O2::Mgr::PropertyManager');
    my $pageTemplateId = $propertyMgr->getPropertyValue( $resolvedUrl->getLastCategoryId(), 'pageTemplateId.O2::Obj::Frontpage' );
    my $pageTemplate   = $context->getObjectById($pageTemplateId);
    $o2PageTemplate = $pageTemplate->getPath();
    $o2PageTemplate =~ s{ \A /var/templates/frontend/pages/ }{}xms;
  }
  $obj->displayPage(
    $filePath,
    pageTemplatePath => "/Templates/pages/$o2PageTemplate",
  );
}
#------------------------------------------------------------------------------------------------------------
1;
