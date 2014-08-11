package O2::Mgr::ImageManager;
 
use strict;
use base 'O2::Mgr::FileManager';

use O2 qw($context $db);
use O2::Obj::Image;
 
#-------------------------------------------------------------------------------
sub initModel {
  my ($obj, $model) = @_;
  $obj->SUPER::initModel($model);
  $model->registerFields(
    'O2::Obj::Image',
    # Your class definition goes here:
    #-----------------------------------------------------------------------------
    width         => { type => 'int'                                          },
    height        => { type => 'int'                                          },
    artistName    => { type => 'varchar'                                      },
    copyright     => { type => 'varchar'                                      },
    alternateText => { type => 'varchar', length => '4000', multilingual => 1 }, # This text will be included in the "alt" attribute of image tags created with <o2 img>
    #-----------------------------------------------------------------------------
  );
}
#-------------------------------------------------------------------------------
# remove object from database + remove file
sub deleteObjectPermanentlyById {
  my ($obj, $objectId) = @_;
  my $image = $context->getObjectById($objectId); # Instantiate the object before everything is deleted
  $obj->SUPER::deleteObjectPermanentlyById($objectId);
  eval {
    my ($dir) = $image->getFilePath() =~ m{ \A (.*) / }xms;
    if ($dir =~ m{ imageRepository }xms) {
      my $fileMgr = $context->getSingleton('O2::File');
      $fileMgr->rmFile($dir, '-rf');
      $fileMgr->rmEmptyDirs("$dir");
    }
    else {
      die "Trying to delete a directory ($dir), but it did not contain the string 'imageRepository'.";
    }
  };
  $db->sql('delete from O2_OBJ_IMAGE where objectId=?', $objectId);
}
#---------------------------------------------------------------------------------------
# find all images tags and replaces them with ready scaled url + also finds allready existing O2 imgs
sub convertRichTextImages {
  my ($obj, $html) = @_;

  my $imgId = 0;
  my @imgStack;
  my %imgIds;
  while ($html =~ s|(<img[^>]+>)|#imgId_$imgId#|xms && $imgId++ <1000) { # Max 1000 images in one article should be enough...
    my ($imgTag, $imageId) = $obj->_evalImgTag($1);
    push @imgStack, $imgTag;
    $imgIds{$imageId} = 1;
  }
  for (my $i = 0; $i < @imgStack; $i++) {
    $html =~ s/\#imgId_$i\#/$imgStack[$i]/xms;
  }
  return $html; 
}
#-------------------------------------------------------------------------------
sub newFromFile {
  my ($obj, $path) = @_;
  die "No such file '$path'" unless -f $path;
 
  my ($file) =~ m/[^\/\\]+$/;

  my $image = $obj->newObject();
  $image->setContentFromPath( $path );
  $image->setMetaName (       $file );
  return $image;
}
#---------------------------------------------------------------------------------------
sub _evalImgTag {
  my ($obj, $imgTag) = @_;

  return $imgTag unless $imgTag =~ m{(/Image-Editor/previewCommands|imageRepository)}xms;
  my $tmp = $imgTag;
  $tmp    =~ s/</[/;
  $tmp    =~ s/>/]/;

  $imgTag =~ s/src\=\"([^\"]+)\"/#url#/xmis;
  my $imgUrl = $1;

  my ($oldHeight, $oldWidth);
  my ($objectId) = ($imgUrl =~ m/id\=(\d+)/xms); # probably Image-Editor url
  ($objectId, $oldHeight, $oldWidth) = ($imgUrl =~ m|^.+/(\d+)_(\d*)?x?(\d*)?\.\w+$|) unless $objectId; # catch scaled imageRepository url
  if (!$objectId) {
    $imgTag =~ s/\#url\#/src=\"$imgUrl\"/xms;
    return $imgTag;
  }

  # is there style defined?
  my ($height) = $imgTag =~ m/height\:\s?(\d+)px/ixms;
  my ($width)  = $imgTag =~ m/width\:\s?(\d+)px/ixms;
  $height ||= $oldHeight;
  $width  ||= $oldWidth;

  my $useReasonableSize = 0;
  if (!$height) { # nope , no CSS style. user was happy with the default size
   ($width, $height) = ($imgUrl =~ m/resize\,(\d+)\,(\d+)/xms);
   $useReasonableSize = 1;
  }

  # putting the url back
  if (!$height && !$width) {
    $imgTag =~ s/\#url\#/src=\"$imgUrl\"/xms;
    return $imgTag;
  }

  my $imageObj;
  $imageObj = $context->getObjectById($objectId) if $objectId;
  my $scaledUrl = $imageObj->getScaledUrl($width, $height); # use same fileformat when resizing vonheim@20061114
  if ($useReasonableSize) {
    $scaledUrl = $imageObj->getFileUrl() if $imageObj->getWidth() < 800 && $imageObj->getHeight() < 800;
  }
      
  $imgTag =~ s/\#url\#/src=\"$scaledUrl\"/xms;
  return ($imgTag, $objectId);
}
#---------------------------------------------------------------------------------------
1;
