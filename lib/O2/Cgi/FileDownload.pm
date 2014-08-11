package O2::Cgi::FileDownload;

use strict;

use O2 qw($context);

#--------------------------------------------------------------------------------------------
sub setupDownload {
  my (%params) = @_;
  $params{cgi}->killBuffer();

  alarm 1000; # Request times out, but this should probably be set somewhere else, bheltne.

  my $filename    = $params{fileName};
  my $content     = $params{content};
  my $disposition = $params{disposition} || 'attachment';

  my $mimeType = O2::Cgi::FileDownload::getMimeType($filename);
  my $length   = ref $content ? length (${ $content }) : length $content;

  print "Content-Type: $mimeType\n";
  print "Expires: Mon, 26 Jul 1997 05:00:00 GMT\n";
  print "Cache-Control: must-revalidate, post-check=0, pre-check=0\n";
  print "Pragma: no-cache\n";
  print "Content-Transfer-Encoding: Binary\n";
  print "Content-Length: $length\n";
  print "Content-Disposition: $disposition; filename=\"$filename\"\n\n";
  print ref $content ? ${$content} : $content;
  return 1;
}
#--------------------------------------------------------------------------------------------
sub getMimeType {
  my ($fileName) = @_;
  return $context->getSingleton('O2::Util::MimeType')->getMimeTypeByFileName($fileName);
}
#--------------------------------------------------------------------------------------------
1;
