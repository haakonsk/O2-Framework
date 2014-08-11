package O2::Image::Image;

use strict;

use O2 qw($context $config);
use Image::Magick;

#-------------------------------------------------------------------------------
sub new {
  my ($pkg, %init) = @_;
  my $img = bless {
    image    => Image::Magick->new(),
    filePath => $init{filePath},
  }, $pkg;
  $img->{image}->Set( quality => !exists ($init{quality}) ? 90 : $init{quality} );
  return $img;
}
#-------------------------------------------------------------------------------
sub newFromFile {
  my($pkg, $filePath, %params) = @_;
  die "File does not exist: '$filePath'" unless -e $filePath;
  
  my $obj = $pkg->new(
    %params,
    filePath => $filePath,
  );
  
  eval {
    my $error = $obj->{image}->Read($filePath);
    return warning $error if $error;
  };
  die "Error in newFromFile: $@" if $@;
  
  $obj->{originalImage} = $obj->{image}->Clone();
  return $obj;
}
#-------------------------------------------------------------------------------
sub newFromImageContent {
  my ($pkg, $content, $fileFormat, %params) = @_;
  die "No content" unless $content;
  
  # Create a temporary file. It will be deleted in the DESTROY method.
  require O2::Util::Password;
  my $passwordGenerator = O2::Util::Password->new();
  my $fileMgr = $context->getSingleton('O2::File');
  my $tmpDir  = $config->get('file.tmpPath');
  $fileMgr->startIgnoreTransactions(); # Important that mkPath and writeFile are done immediately
  my $tmpFilePath;
  eval {
    $fileMgr->mkPath($tmpDir) unless -e $tmpDir;
    $tmpFilePath = "$tmpDir/" . $passwordGenerator->generatePassword(16) . ".$fileFormat";
    $fileMgr->writeFile($tmpFilePath, $content);
  };
  my $errorMsg = $@;
  $fileMgr->endIgnoreTransactions();
  die $errorMsg if $@;
  
  my $obj = $pkg->newFromFile($tmpFilePath, %params);
  $obj->{tmpFilePath} = $tmpFilePath;
  return $obj;
}
#-------------------------------------------------------------------------------
sub crop {
  my ($obj, $x, $y, $width, $height) = @_;
  $obj->{image}->Crop(x=>$x, y=>$y, width=>$width, height=>$height);
  $obj->{image}->Set( page => $x."x".$y); # A bug with GIF-croping in Image Magick makes us manually set the page size.
}
#-------------------------------------------------------------------------------
sub smartCrop {
  my ($obj, %params) = @_; # width, height, onTooBig, onTooSmall  XXX: verticalCropPosition, horizontalCropPosition
  # Find x and y and make a call to crop.
  my $width  = $params{width};
  my $height = $params{height};
  if ($obj->getWidth() >= $width  &&  $obj->getHeight() >= $height) {
    if ( 1.0 * $obj->getWidth() / $obj->getHeight()   <   1.0 * $width / $height ) { # Width to height ratio is smaller for image than available space.
      $height = 10000;
    }
    elsif ( 1.0 * $obj->getWidth() / $obj->getHeight()   >   1.0 * $width / $height) { # Width to height ratio is larger for image than available space.
      $width = 10000;
    }
    $obj->resize($width, $height);
  }
  elsif ($obj->getWidth() <= $width  &&  $obj->getHeight() <= $height) {
    return $obj;
  }
  elsif ($params{onTooSmall} eq 'resize') {
    if ($obj->getWidth() >= $width  &&  $obj->getHeight() <= $height) {
      $width = 10000;
    }
    elsif ($obj->getWidth() <= $width  &&  $obj->getHeight() >= $height) {
      $height = 10000;
    }
    $obj->resize($width, $height);
  }
  elsif ($params{onTooSmall} eq 'ignore') {
    # Nothing to do
  }
  else {
    die "This should never happen";
  }
  my $x = $obj->_getCropX( $params{width}  );
  my $y = $obj->_getCropY( $params{height} );
  $obj->crop($x, $y, $params{width}, $params{height});
  return $obj;
}
#-------------------------------------------------------------------------------
sub _getCropX {
  my ($obj, $width) = @_;
  return 0 if $width >= $obj->getWidth();
  return 0.5 * ($obj->getWidth() - $width);
}
#-------------------------------------------------------------------------------
sub _getCropY {
  my ($obj, $height) = @_;
  return 0 if $height >= $obj->getHeight();
  return 0.5 * ($obj->getHeight() - $height);
}
#-------------------------------------------------------------------------------
sub grayscale {
  my ($obj) = @_;
  $obj->{image}->Quantize(colorspace=>'gray');
}
#-------------------------------------------------------------------------------
sub resize {
  my ($obj, $width, $height, $noAspectRatio) = @_;
  my $error;
  
  # added by nilschd 20070705 to allow correct resizing of GIF animations
  # we need to Coalesce the image first. (which takes away the gif optmization and "blocks" out all the images frames to same size)
  my $img = $obj->{image};
  $img = $obj->{image}->Coalesce() if $obj->isGifAnimation();
  
  if ($width || $height) {
    eval {
      my $geometry = "${width}x${height}" . ($noAspectRatio ? '!' : '');
      $error = $img->Resize( geometry => $geometry );
    };
    return warning "Error when resizing image: $error. $@" if $error || $@;
  }
  
  $obj->{image} = $img; # Make the original be our temporary picture again
}
#-------------------------------------------------------------------------------
sub resizeNoAspectRatio {
  my ($obj, $width, $height) = @_;
  # nilschd 20070705 changed this to reuse the GIF animation fix here as well
  # note the "1" for $noAspectRatio
  $obj->resize($width, $height, 1);
  # $obj->{image}->Resize(geometry=>"${width}x${height}!");
}
#-------------------------------------------------------------------------------
sub rotate {
  my ($obj, $degrees) = @_;
  $obj->{image}->Rotate(degrees => $degrees);
}
#-------------------------------------------------------------------------------
sub write {
  my ($obj, $filePath) = @_;
  my $error;
  eval {
    $error = $obj->{image}->Write($filePath);
  };
  return warning "Error when saving image: $error. $@" if $error || $@;
  return $obj->_saveExifInfo($filePath);
}
#-------------------------------------------------------------------------------
sub restoreOriginal {
  my ($obj) = @_;
  $obj->{image} = $obj->{originalImage};
}
#-------------------------------------------------------------------------------
sub _saveExifInfo {
  my ($obj, $filePath) = @_;
  return if !$obj->{exifInfo}  ||  !%{ $obj->{exifInfo} };
  if (!$obj->{exifTool}) {
    require Image::ExifTool;
    $obj->{exifTool} = Image::ExifTool->new();
  }
  foreach my $key (keys %{ $obj->{exifInfo} }) {
    $obj->{exifTool}->SetNewValue( $key, $obj->{exifInfo}->{$key} );
  }
  my $retVal = $obj->{exifTool}->WriteInfo($filePath);
  warning "Couldn't save exif info for image ($filePath): " . $obj->{exifTool}->GetValue('Error') unless $retVal;
  warning "No exif changes were made" if $retVal == 2;
  return $retVal;
}
#-------------------------------------------------------------------------------
sub print {
  my ($obj, $format) = @_;
  return $obj->{image}->Write("$format:-");
}
#-------------------------------------------------------------------------------
sub getWidth {
  my ($obj) = @_;
  return $obj->{image}->Get('width');
}
#-------------------------------------------------------------------------------
sub getHeight {
  my ($obj) = @_;
  return $obj->{image}->Get('height');
}
#-------------------------------------------------------------------------------
sub filterCommands {
  my ($obj, $commands) = @_;
  my @cmds = split /;/, $commands;
  foreach my $cmd (@cmds) {
    my ($cmd, @args) = split /,/, $cmd;
    $obj->crop(@args)   if $cmd eq 'crop';
    $obj->resize(@args) if $cmd eq 'resize';
    $obj->grayscale()   if $cmd eq 'grayscale';
    $obj->rotate(@args) if $cmd eq 'rotate';
  }
}
#-------------------------------------------------------------------------------
sub asBlob {
  my ($obj) = @_;
  return $obj->{image}->ImageToBlob();
}
#-------------------------------------------------------------------------------
# added by nilschd 20070705 to allow correct detecting and resizing of GIF animations
sub isGifAnimation {
  my ($obj) = @_;
  return $obj->getImageFormat() eq 'gif'   &&   @{ $obj->{image} }  >  1;
}
#-------------------------------------------------------------------------------
sub getExifInfo {
  my ($obj, $key, $filePath) = @_;
  return $obj->{exifInfo}->{$key} if $obj->{exifInfo} && $obj->{exifInfo}->{$key};
  if (!$obj->{exifTool}) {
    require Image::ExifTool;
    $obj->{exifTool} = Image::ExifTool->new();
    $filePath ||= $obj->{filePath} or die "Don't know file path";
    $obj->{exifTool}->ExtractInfo($filePath) or die "Error occurred while extracting exif info from file '$filePath': " . $obj->{exifTool}->GetInfo('Error')->{Error};
  }
  return $obj->{exifTool}->GetInfo($key)->{$key} || '';
}
#-------------------------------------------------------------------------------
sub setExifInfo {
  my ($obj, $key, $value) = @_;
  my $format = $obj->getImageFormat();
  return 1 if $obj->{filePath} && $obj->getExifInfo($key) eq $value; # Setting it to its old value, so no need to save
  $obj->{exifInfo} = {} unless $obj->{exifInfo};
  $obj->{exifInfo}->{$key} = $value;
  return 1;
}
#-------------------------------------------------------------------------------
sub getImageFormat {
  my ($obj) = @_;
  return lc $obj->{image}->Get('magick');
}
#-------------------------------------------------------------------------------
sub DESTROY {
  my ($obj) = @_;
  unlink $obj->{tmpFilePath} if $obj->{tmpFilePath};
}
#-------------------------------------------------------------------------------
1;
