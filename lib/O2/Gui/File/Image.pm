package O2::Gui::File::Image;

use strict;

use base 'O2::Gui';

use O2 qw($context $cgi);

#-----------------------------------------------------------------------------
sub showImage {
  my ($obj, $imageId) = @_;
  $imageId ||= $obj->getParam('imageId');
  die "Missing imageId parameter"    unless $imageId;
  die "Missing categoryId parameter" unless $obj->getParam('categoryId');
  $cgi->setParam( 'albumUrl', $context->getEnv('HTTP_REFERER') ) unless $obj->getParam('albumUrl');
  my @imageIds = $obj->_getImageIds();
  my $image = $context->getObjectById( $imageId );
  $obj->displayPage(
    'showImage.html',
    image        => $image,
    isFirstImage => $imageIds[0]  == $imageId,
    isLastImage  => $imageIds[-1] == $imageId,
    albumUrl     => $obj->getParam('albumUrl'),
    categoryId   => $obj->getParam('categoryId'),
  );
}
#-----------------------------------------------------------------------------
sub showPreviousImage {
  my ($obj) = @_;
  my @imageIds = $obj->_getImageIds();
  my $previousId;
  foreach my $id (@imageIds) {
    last if $id == $obj->getParam('imageId');
    $previousId = $id;
  }
  $obj->showImage($previousId);
}
#-----------------------------------------------------------------------------
sub showNextImage {
  my ($obj) = @_;
  my @imageIds = $obj->_getImageIds();
  my ($nextId, $found);
  foreach my $id (@imageIds) {
    if ($found) {
      $nextId = $id;
      last;
    }
    $found = 1 if $id == $obj->getParam('imageId');
  }
  $obj->showImage($nextId);
}
#-----------------------------------------------------------------------------
sub _getImageIds {
  my ($obj) = @_;
  my $category = $context->getObjectById( $obj->getParam('categoryId') );
  my @imageIds = map { $_->getId() } grep { $_->isa('O2::Obj::Image') } $category->getChildren();
}
#-----------------------------------------------------------------------------

1;
