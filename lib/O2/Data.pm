package O2::Data;

use strict;

our $_METADATA;

use O2 qw($context $cgi);

require Data::Dumper;
$Data::Dumper::Purity  = 1;
$Data::Dumper::Varname = 'O2STRIP';

#--------------------------------------------------------------------------------------------
sub new {
  my ($package, %params) = @_;
  return bless {}, $package;
}
#--------------------------------------------------------------------------------------------
sub save {
  my $obj;
  $obj = shift if ref $_[0] eq __PACKAGE__;
  my ($file, $structure, $metaData) = @_;
  
  $structure = &_parse($structure);
  die "Could not save datastructure. Possible illegal content ?" unless $structure;
  
  if ($obj || $metaData->{fileEncoding} ) {
    my $encoding = $metaData->{fileEncoding} || ($cgi ? $cgi->getCharacterSet() : 'utf-8');
    $metaData->{fileEncoding} = $encoding;
    require Encode;
    $structure = Encode::encode($encoding, $structure);
  }
  my $fileMgr = $context->getSingleton('O2::File');
  
  $structure = &_setupMetaDataHeader($metaData) . $structure if scalar keys %{$metaData};
  
  $fileMgr->writeFile($file, $structure);
  return $structure;
}
#--------------------------------------------------------------------------------------------
sub dump {
  my $obj;
  $obj = shift if ref $_[0] eq __PACKAGE__;
  my ($structure, $indenter) = @_;
  
  $structure = &_parse($structure);
  
  return $structure if $structure;
  die "Could not print datastructure. Possible illegal content?";
}
#--------------------------------------------------------------------------------------------
sub load {
  my $obj;
  $obj = shift if ref $_[0] eq __PACKAGE__;
  my (@files) = @_;
  my @structures;
  $_METADATA = {};
  my $fileMgr = $context->getSingleton('O2::File');
  
  foreach my $file (@files) {
    my $fileContent;
    eval {
      $fileContent = $fileMgr->getFile($file);
    };
    die "load: Could not read file '$file': $@" if $@;
    
    $_METADATA = &_parseMetaDataHeader($fileContent);
    my $fileEncoding = $_METADATA->{fileEncoding}; 
    my $structure    = $fileEncoding  ?  _evalFileWithKnownEncoding($fileEncoding, $fileContent)  :  eval $fileContent;
    die "Could not load datastructure '$file': $@" if $@;
    
    push @structures, $structure;
  }
  
  return  @structures == 1  ?  $structures[0]  :  @structures;
}
#--------------------------------------------------------------------------------------------
sub _evalFileWithKnownEncoding {
  my ($encoding, $content) = @_;
  require Encode;
  $content = Encode::decode($encoding, $content);
  return eval $content;
}
#--------------------------------------------------------------------------------------------
sub undump {
  my $obj;
  $obj = shift if ref $_[0] eq __PACKAGE__;
  my (@strings) = @_;
  my @structures;
  foreach my $string (@strings) {
    my $structure = eval $string;
    die "Could not evaluate datastructure '$_': $@" if $@;
    push @structures, $structure;
  }
  return  @structures == 1  ?  $structures[0]  :  @structures;
}
#--------------------------------------------------------------------------------------------
sub _parse {
  my ($structure) = @_;
  my $data = Data::Dumper::Dumper($structure);
  $data    =~ s{ \\x\{ ([a-z0-9]{2}) \} }{chr (hex $1)}xmsge; # We want æøå - not \x{e6}\x{f8}\x{e5}
  $data    =~ s/^\$O2STRIP1\s*=\s*\s+//m;
  $data    =~ s/^\s{12}//mg;
  return $data;
}
#--------------------------------------------------------------------------------------------
sub _setupMetaDataHeader {
  my ($metaData) = @_;
  my $metaDataHeader = '';
  foreach my $md (keys %{$metaData}) {
    $metaDataHeader .= "# $md=$metaData->{$md}\n";
  }
  return $metaDataHeader;
}
#--------------------------------------------------------------------------------------------
sub _parseMetaDataHeader {
  my ($fileContent) = @_;
  my $e = index $fileContent, '{';
  my $metaData = {};
  return $metaData if $e == 0;
  
  my $metaDataHeader = substr $fileContent, 0, $e;
  my @lines = split /\n/, $metaDataHeader;
  foreach my $line (@lines) {
    next unless $line =~ m{ = }xms;
    my ($key, $value) = split /=/, $line, 2;
    $key = substr $key, 2;
    $metaData->{$key} = $value;
  }
  return $metaData;
}
#--------------------------------------------------------------------------------------------
sub haveMetaData {
  return scalar keys %{$_METADATA};
}
#--------------------------------------------------------------------------------------------
sub getMetaData {
  return wantarray ? %{$_METADATA} : $_METADATA;
}
#--------------------------------------------------------------------------------------------
sub getMetaDataKey {
  my $obj;
  $obj = shift if ref $_[0] eq __PACKAGE__;
  my $key = shift;
  return $_METADATA->{$key};
}
#--------------------------------------------------------------------------------------------
1;
