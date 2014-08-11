package O2::ImageResize;

use strict;

use O2 qw($context $cgi $config);

my $imageTypeRegex = qr/^(jpe?g|gif|bmp|tif|png|iff)$/;
my $validLetter    = qr/[a-zA-Z0-9\_\-]/;
my $validSize      = qr/^(?:_|\d+)$/;

# Format; /imageRepository/00/00/00/29/28/2928_400x400.jpg

#------------------------------------------------------------------------------------------------------------
sub dispatch {
  my ($package, %params) = @_;
  
  my $maxWidth      = $config->get('file.imageResize.maxWidth')  || 500;
  my $maxHeight     = $config->get('file.imageResize.maxHeight') || 500;
  my $imageBasePath = $config->get('file.basePath') or $cgi->error("No file.basePath supplied");
  
  my $requestFromServer = $context->getEnv('QUERY_STRING') || $context->getEnv('REQUEST_URI');
  
  my @ids = split /\//, $requestFromServer;
  my $imageFileWithSizes = pop @ids;
  
  my ( $fileName, $sizeWithExtension ) = split /_/,  $imageFileWithSizes;
  my ( $size,     $extension         ) = split /\./, $sizeWithExtension;
  my ( $width,    $height            ) = split /x/,  $size;
  
  if ($fileName && $width && $height) {
    my $image = $context->getObjectById($fileName);
    $cgi->error("File does not exist") unless $image;
    my $path = $image->getScaledPath($width, $height, $extension);
    $cgi->setContentType("image/$extension");
    open IMAGE, "<$path" or $cgi->error("Could not open $path:$!");
    binmode IMAGE;
    while (<IMAGE>) {
      print $_;
    }
    close IMAGE;
  }
  else {
    $cgi->error("Not a valid URL");
  }
  return;
}
#------------------------------------------------------------------------------------------------------------
1;
