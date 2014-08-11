package O2::Cgi::File; # Package for handling uploaded files

use strict;

use O2 qw($context $cgi);

#--------------------------------------------------------------------------------------------
sub new {
  my ($package, %params) = @_;
  return bless \%params, $package;
}
#--------------------------------------------------------------------------------------------
sub getTmpFile {
  my ($obj) = @_;
  return $obj->{tmpFile};
}
#--------------------------------------------------------------------------------------------
sub getFileName {
  my ($obj) = @_;
  my $fileName
    = $obj->{filePath} =~ m{ /  ([^/]+)  \z }xms ? $1
    : $obj->{filePath} =~ m{ \\ ([^\\]+) \z }xms ? $1
    :                                              $obj->{filePath}
    ;
  return $fileName;
}
#--------------------------------------------------------------------------------------------
sub getFilePath {
  my ($obj) = @_;
  return $obj->{filePath};
}
#--------------------------------------------------------------------------------------------
sub getFileContent {
  my ($obj) = @_;
  local *FH;
  local $/ = undef unless wantarray;
  open FH, $obj->getTmpFile() or die "Could not open file - '" . $obj->getTmpFile() . "': $!";
  binmode FH;
  my @content = <FH>;
  close FH;
  return $content[1] ? @content : $content[0];
}
#--------------------------------------------------------------------------------------------
sub getFileSize {
  my ($obj) = @_;
  return -s $obj->{tmpFile} || 0;
}
#--------------------------------------------------------------------------------------------
sub getContentType {
  my ($obj) = @_;
  return $obj->{contentType};
}
#--------------------------------------------------------------------------------------------
sub storeFile {
  my ($obj, $destination) = @_;
  open my $fhDest, '>', $destination or die "Could not open file for writing - '$destination': $!";
  open my $fhSource, $obj->{tmpFile} or die "Could not open file - '$obj->{tmpFile}': $!";
  binmode $fhDest;
  binmode $fhSource;
  while (<$fhSource>) {
    print $fhDest $_;
  }
  close $fhSource;
  close $fhDest;
}
#--------------------------------------------------------------------------------------------
sub storeFileAndGetO2Object {
  my ($obj) = @_;
  my $filePath = $obj->getFilePath();
  my ($fileName, $ext) = $filePath =~ m{ ([^\\/]+) [.] (\w+) \z }xms;
  my $object = $obj->getObjectByFileExtension($ext);
  my $parentId = $cgi->getParam('parentId');
  $object->setMetaName(        "$fileName.$ext"      );
  $object->setMetaParentId(    $parentId             ) if $parentId;
  $object->setMetaOwnerId(     $context->getUserId() );
  $object->setContentFromPath( $obj->getTmpFile()    );
  $object->setFileFormat($ext);
  $obj->setImageProperties($object) if $object->isa('O2::Obj::Image');
  return $object;
}
#--------------------------------------------------------------------------------------------
sub getObjectByFileExtension {
  my ($obj, $fileExtension) = @_;
  require O2::Util::MimeType;
  my $className = O2::Util::MimeType->new()->getClassNameByFileExtension($fileExtension);
  return $context->getUniversalManager()->getManagerByClassName($className)->newObject();
}
#--------------------------------------------------------------------------------------------
sub setImageProperties {
  my ($obj, $image) = @_;
  my $exifTitle       = $image->getExifTitle();
  my $exifDescription = $image->getExifDescription();
  foreach my $locale ($image->getAvailableLocales()) {
    $image->setCurrentLocale($locale);
    $image->setTitle(       $exifTitle       ) if $exifTitle;
    $image->setDescription( $exifDescription ) if $exifDescription;
  }
}
#--------------------------------------------------------------------------------------------
sub DESTROY {
  my ($obj) = @_;
  unlink $obj->{tmpFile};
}
#--------------------------------------------------------------------------------------------
1;
