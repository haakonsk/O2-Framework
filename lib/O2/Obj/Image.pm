package O2::Obj::Image;
 
use strict;

use base 'O2::Obj::File';

use constant DEBUG => 0;
use O2 qw($context $config);

#-------------------------------------------------------------------------------
sub getWidth {
  my ($obj) = @_;
  return $obj->getModelValue('width') if defined $obj->getModelValue('width');
  
  # Look for width in image file
  my $image = $obj->getImage();
  return unless $image;
  
  $obj->setWidth( $image->getWidth() );
  return $image->getWidth();
}
#-------------------------------------------------------------------------------
sub getHeight {
  my ($obj) = @_;
  return $obj->getModelValue('height') if defined $obj->getModelValue('height');
  
  # Look for height in image file
  my $image = $obj->getImage();
  return unless $image;
  
  $obj->setHeight( $image->getHeight() );
  return $image->getHeight();
}
#-------------------------------------------------------------------------------
sub getScaledUrl {
  my ($obj, $width, $height, $fileFormat, %cropParams) = @_;
  my $base = $config->get('file.baseUrl');
  my $url = "$base/" . $obj->_getScaledLocation($width, $height, $fileFormat, undef, %cropParams);
  $url =~ s{([^:])//}{$1/}g;
  return $url;
}
#-------------------------------------------------------------------------------
sub getScaledUrlNoAspectRatio {
  my ($obj, $width, $height, $fileFormat) = @_;
  my $base = $config->get('file.baseUrl');
  my $url = "$base/" . $obj->_getScaledLocation($width, $height, $fileFormat, 1);
  $url    =~ s{([^:])//}{$1/}g;
  return $url;
}
#-------------------------------------------------------------------------------
sub getCroppedUrl {
  my ($obj, %params) = @_;
  my %cropParams = (
    onTooBig   => $params{onTooBig},
    onTooSmall => $params{onTooSmall},
  );
  return $obj->getScaledUrl( $params{width}, $params{height}, undef, %cropParams );
}
#-------------------------------------------------------------------------------
sub getScaledPath {
  my ($obj, $width, $height, $fileFormat) = @_;
  my $base = $config->get('file.basePath');
  my $path = "$base/" . $obj->_getScaledLocation($width, $height, $fileFormat);
  $path =~ s{//}{/}g;
  return $path;
}
#-------------------------------------------------------------------------------
sub _getScaledLocation {
  my ($obj, $width, $height, $fileFormat, $noAspectRatio, %cropParams) = @_;
  $fileFormat ||= $obj->getFileFormat();
  $height       = '' unless $height;

  my $img;
  # If this image is a gif animiation, we have to enforce the gif format. Otherwise corrupted images may occur.
  if ( $obj->getFileFormat() eq 'gif' && $fileFormat ne 'gif' ) {
    $img = $obj->getImage();
    return unless $img;
    $fileFormat = 'gif' if $img->isGifAnimation(); # enforcing the file format
  }

  my $filePath   = $obj->getFilePath();
  my ($fileDir)  = $filePath =~ m|^(.*?)[^\/]+$|;
  my $noAP       = $noAspectRatio ? '_noaspectratio' : '';
  my $cropping   = %cropParams ? "_$cropParams{onTooBig}_$cropParams{onTooSmall}" : '';
  my $scaledPath = $fileDir . $obj->getId() . "_${width}x${height}$noAP$cropping.$fileFormat";
  if (!-e $scaledPath) {
    eval {
      $img ||= $obj->getImage();
    };
    if (!$img) {
      warning "Couldn't get image: $@";
      return;
    }
    
    if ($cropping) {
      $img->smartCrop(
        width      => $width,
        height     => $height,
        onTooBig   => $cropParams{onTooBig},
        onTooSmall => $cropParams{onTooSmall},
      );
    }
    elsif ($noAspectRatio) {
      $img->resizeNoAspectRatio($width, $height);
    }
    else {
      $img->resize($width, $height);
    }
    $img->write($scaledPath);
    $img->restoreOriginal();
  }
  # return only the part common for both url and filesystem
  my $base = $config->get('file.basePath');
  $scaledPath =~ s/^\Q$base\E//;
  return $scaledPath;
}
#-------------------------------------------------------------------------------
sub getImage {
  my ($obj) = @_;

  if (!$obj->{image}) {
    my $quality  =  exists $obj->{quality}  ?  $obj->{quality}  :  $config->get('o2.imageQuality');
    require O2::Image::Image;
    my $filePath  =  $obj->getId() && -e $obj->getFilePath()  ?  $obj->getFilePath()  :  $obj->{unsavedContent}->{path};
    if ($filePath && -f $filePath) {
      $obj->{image} = O2::Image::Image->newFromFile(
        $filePath,
        quality => $quality,
      ) or die 'newFromFile failed. Check O2 Console. FilePath is ' . $obj->getFilePath();
    }
    elsif ($obj->{unsavedContent}->{content}) {
      $obj->{image} = O2::Image::Image->newFromImageContent(
        $obj->{unsavedContent}->{content},
        $obj->getFileFormat(),
        quality => $quality,
      );
    }
    elsif ($obj->getFilePath()) {
      die 'Image path (' . $obj->getFilePath() . ') does not exist';
    }
    else {
      die "Didn't find file or file content";
    }
  }
  return $obj->{image};
}
#-------------------------------------------------------------------------------
sub canMove {
  my ($obj, $fromContainer, $toContainer) = @_;
  return 1;
}
#-------------------------------------------------------------------------------
sub deleteScaledVersions {
  my ($obj) = @_;
  my $path = $obj->getFilePath();
  $path    =~ s{^(.+)\/\d+\..+$}{$1}xms; # finding the dir path
  return unless -d $path; # Don't want to die if there's nothing to delete
  
  my @files = $obj->{_file}->scanDir( $path, '^' . $obj->getId() . '_\w+x\w+' ); # scanning for similar files
  foreach my $scaled (@files) {
    unlink "$path/$scaled" if -e "$path/$scaled";
  }
  return 1;
}
#-------------------------------------------------------------------------------
# Overriding parent's save, to see if we need to delete any scaled versions of this picture
# the old scaled versions don't get updated when setting new content to the image object
sub save {
  my ($obj) = @_;
  $obj->deleteScaledVersions() if $obj->hasUnsavedContent() && $obj->getId();
  $obj->SUPER::save();
  eval {
    $obj->getImage()->_saveExifInfo( $obj->getFilePath() ) unless $obj->isDeleted();
  };
  if ($@) {
    warning "Couldn't save exif info for $obj: $@";
  }
}
#-------------------------------------------------------------------------------
sub getIconUrl {
  my ($obj, $size) = @_;
  $size ||= 16;

  my $url;
  eval {
    $url = $obj->getScaledUrlNoAspectRatio($size, $size, 'png');
  };
  return $obj->SUPER::getIconUrl($size) if $@;
  return $url;
}
#-------------------------------------------------------------------------------
sub setExifInfo {
  my ($obj, $key, $value) = @_;
  return $obj->getImage()->setExifInfo($key, $value);
}
#-------------------------------------------------------------------------------
sub getExifInfo {
  my ($obj, $key) = @_;
  my $filePath = $obj->getId() && -e $obj->getFilePath()  ?  $obj->getFilePath()  :  $obj->{unsavedContent}->{path};
  return $obj->getImage()->getExifInfo($key, $filePath);
}
#-------------------------------------------------------------------------------
sub getExifTitle {
  my ($obj) = @_;
  return $obj->getExifInfo('ImageDescription') || $obj->getExifInfo('XmpmetaTitle') || $obj->getExifInfo('XPTitle'); # See http://www.exif.org/Exif2-2.PDF
}
#-------------------------------------------------------------------------------
sub setExifTitle {
  my ($obj, $value) = @_;
  $obj->setExifInfo( 'XPTitle',      $value );
  $obj->setExifInfo( 'XmpmetaTitle', $value );
  return $obj->setExifInfo('ImageDescription', $value);
}
#-------------------------------------------------------------------------------
sub getExifDescription {
  my ($obj) = @_;
  return $obj->getExifInfo('XmpmetaUserComment') || $obj->getExifInfo('XPComment') || $obj->getExifInfo('UserComment');
}
#-------------------------------------------------------------------------------
sub setExifDescription {
  my ($obj, $value) = @_;
  $obj->setExifInfo( 'XmpmetaUserComment', $value );
  $obj->setExifInfo( 'XPComment',          $value );
  return $obj->setExifInfo('UserComment', $value);
}
#-------------------------------------------------------------------------------
sub getExifArtist {
  my ($obj) = @_;
  return $obj->getExifInfo('Artist');
}
#-------------------------------------------------------------------------------
sub setExifArtist {
  my ($obj, $value) = @_;
  return $obj->setExifInfo('Artist', $value);
}
#-------------------------------------------------------------------------------
sub getExifDateAndTime {
  my ($obj) = @_;
  my $dateAndTime = $obj->getExifInfo('DateTime');
  return unless $dateAndTime;
  $dateAndTime    =~ s{ \D \z }{}xms;                           # Remove trailing Z or whatever it is
  $dateAndTime    =~ s{ \A  (\d{4})  :  (\d{2})  :  }{$1$2}xms; # Remove ":" from date part
  return $context->getDateFormatter()->dateTime2Epoch($dateAndTime);
}
#-------------------------------------------------------------------------------
sub setExifDateAndTime {
  my ($obj, $epoch) = @_;
  my $dateAndTime = $context->getDateFormatter()->dateFormat($epoch, "yyyy:MM:dd HH:mm:ss");
  return $obj->setExifInfo('DateTime', $dateAndTime); # XXX use DateTimeOriginal or DateTimeDigitized instead?
}
#-------------------------------------------------------------------------------
1;
