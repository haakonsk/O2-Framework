package O2::Gui::File::Download;

use strict;

use base 'O2::Gui';

use O2 qw($context $cgi);

#----------------------------------------------------------------------
# download file content
sub download {
  my ($obj) = @_;
  my $objectId = $cgi->getParam('objectId');
  
  my $file = $context->getObjectById($objectId);
  
  if (!$file) {
    $obj->displayErrorPage(
      header => $obj->getLang()->getString('File.Download.errorHeader'),
      msg    => $obj->getLang()->getString('File.Download.errorMsg'),
    );
    return;
  }
  
  my $name = $file->getMetaName();
  $name =~ s/\s/_/g;
  
  $cgi->addHeader('Content-Disposition', "inline; filename=$name");
  $cgi->setContentType('application/octet-stream');
  my $path = $file->getFilePath();
  if (!open F, $path) {
    warning "Could not download file: $path";
  }
  binmode F;
  print join '', <F>;
  close F;
}
#----------------------------------------------------------------------
# redirect to file directly (make common file types appear in browserwindow)
sub view {
  my ($obj) = @_;
  my $objectId = $cgi->getParam('objectId');
  
  my $file = $context->getObjectById($objectId);
  die "This file has probably been deleted" if !$file;
  my $url = $file->getFileUrl();
  $cgi->redirect($url);
}
#----------------------------------------------------------------------
1;
