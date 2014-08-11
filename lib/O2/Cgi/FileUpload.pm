package O2::Cgi::FileUpload;

use strict;

use O2::Cgi;
use O2::Cgi::File;
use File::Temp qw(tempfile);

#--------------------------------------------------------------------------------------------
sub handleFileUpload {
  umask oct 2;
  my %q;
  
  # XXX Files should be written directly to disk instead of to memory
  
  my $newLine = qr{\n\r|\r\n|\r|\n}; 
  
  my $boundary     = <STDIN>; # Could be something like              "-----------------------------12345678901234\n"
  my $fileBoundary = $boundary;
  $fileBoundary    =~ s{ ( [^-\n\r] )  ($newLine) \z }{$1--$2}xms; # "-----------------------------12345678901234--\n"
  
  my $body;
  {
    local $/ = undef;
    $body = <STDIN>;
  }
  my @parts = split /\Q$boundary\E/, $body;
  
  foreach my $part (@parts) {
    $part =~ s/(?:$fileBoundary|$boundary)$//;
    $part =~ s/(?:$newLine)$//;
    
    my ($key, $value);
    if ( $part =~ s/^Content-[Dd]isposition:\s+form-data\;\s+name=\"([^\"]+)\";\s+filename=\"(.*?)\"(?:$newLine)//s ) {
      $key         = &O2::Cgi::urlDecode(undef, $1);
      my $fileName = &O2::Cgi::urlDecode(undef, $2);
      next unless $fileName; # No file was chosen
      
      my $contentType = '';
      if ($part =~ s/^Content-Type:\s+([^\r\n]+)(?:$newLine){2}//s) { 
        $contentType = $1;
      }
      
      my ($tmpFh, $tmpFile) = tempfile();
      
      binmode $tmpFh;
      print $tmpFh $part; # XXX Really should fix this to be partial read/write -> See Qsp for hints
      close $tmpFh;
      
      $value = O2::Cgi::File->new(
        filePath    => $fileName,
        tmpFile     => $tmpFile,
        contentType => $contentType,
      );
    }
    elsif ( $part =~ s/^Content-[Dd]isposition:\s+form-data\;\s+name=\"([^\"]+)\"(?:$newLine){2}//s ) { 
      $key   = &O2::Cgi::urlDecode( undef, $1    ); 
      $value = &O2::Cgi::urlDecode( undef, $part );
    }
    
    if (!exists $q{$key}) {
      $q{$key} = $value;
    }
    else {
      $q{$key} = [ $q{$key} ] if ref $q{$key} ne 'ARRAY';
      push @{ $q{$key} }, $value;
    }
  }
  return \%q;
}
#--------------------------------------------------------------------------------------------
1;
