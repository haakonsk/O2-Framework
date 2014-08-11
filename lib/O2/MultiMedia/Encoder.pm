package O2::MultiMedia::Encoder;

use strict;

#------------------------------------------------------------
sub new {
  my ($pkg, %params) = @_;
  my $encoder = O2::MultiMedia::Encoder::_getEncoder(%params);
  return bless { encoder => $encoder }, $pkg;
}
#------------------------------------------------------------
# XXX need to do some selection of the right encoder here
# Selection criteria:
# - OS
# - what to convert video,audio, movie/audio types etc...
# 
sub _getEncoder {
  my (%params)=@_;
  my $encoder=undef;
  $params{encoder}||='FFmpeg'; # is default for backward comp
  if( $params{encoder} ) {
    my $className='O2::MultiMedia::Encoder::'.$params{encoder};
    $encoder = eval "require $className;return $className->new();";
    if($@) {
      die __PACKAGE__.": could load encoder '$className'";
    }
  }
  return $encoder;
}
#------------------------------------------------------------
sub encode {
  my ($obj,%params)=@_;

  my $inMedia          = delete $params{inMedia};
  my $outMedia         = delete $params{outMedia};
  my $overwriteTarget  = delete $params{allowOverwrite};
  


  if(exists($params{encodeProfile})) {
    $obj->{encoder}->loadProfile(delete $params{encodeProfile});
  }

  if(!$outMedia) {
    my $fileExt = $obj->{encoder}->getDefaultFileExtension();
    if($fileExt eq 'unknown' && $inMedia=~m/\.(\w+)$/i) {
      $fileExt=$1;
    }
    $outMedia = $obj->_getTmpFile('.'.$fileExt);
    push @{$obj->{_tmpFiles}},$outMedia;
  }
  
  
  foreach my $option (keys %{$obj->{encoder}->getAvailableOptions()}) {
    if(exists($params{$option})) {
      $obj->{encoder}->setOption($option => $params{$option});
    }
  }
    
    
  if(-e $outMedia && !$overwriteTarget) {
    print "target file exists : $outMedia\n";
    return 0;
  }
  if(substr(lc($inMedia),0,4) ne 'http' && !-e $inMedia) {
    print "source file doesn't exists: '$inMedia'\n";
    return 0;
  }

  if(-e $outMedia && $overwriteTarget) {
    unlink $outMedia;
  }
  return $obj->{encoder}->encode($inMedia,$outMedia);
}
# no out file has been provided
sub _getTmpFile {
  my ($obj,$ext)=@_;
  use File::Temp qw/tempfile/;
  my ($tmpFh, $tmpFile) = tempfile(SUFFIX => $ext );
#  print "GOT". $tmpFile;
  close ($tmpFh);
  return $tmpFile;
}
#------------------------------------------------------------
# option methods
#------------------------------------------------------------
sub AUTOLOAD {
  my ($obj,$params) =@_;
  our $AUTOLOAD;
 # print $obj->{encoder}."\n";
  my ($pkg,$method)=$AUTOLOAD=~m/^(.+)\:\:([a-zA-Z0-9\_\-]+)$/xms;
  my ($methodType,$optionName)=$method=~m/^(set|get)([a-zA-Z0-9\_\-]+)$/xms;


  if($methodType eq 'get' && $obj->{encoder}->hasOption($optionName)) {
    return $obj->{encoder}->getOption($optionName);
  }
  elsif($methodType eq 'set' && $obj->{encoder}->hasOption($optionName)) {
    return $obj->{encoder}->setOption($optionName => $params);
  }
  elsif( $obj->{encoder}->can($method) ) {
    $obj->{encoder}->$method($params);
  }
  elsif( $method ne 'DESTROY' ) {
    print "No so much '$method' exists\n";
    return 0;
  }
  #print "pkg : $pkg\nmethod : $method\n";
#  print "Method called:". $AUTOLOAD."\n";
}
#------------------------------------------------------------
sub DESTROY {
  my $obj=shift;
  print __PACKAGE__.": destroy\n";
  foreach my $tmpFile (@{$obj->{_tmpFiles}}) {
    print "unlink $tmpFile\n";
    unlink $tmpFile if -e $tmpFile;
  }
}
#------------------------------------------------------------
1;
