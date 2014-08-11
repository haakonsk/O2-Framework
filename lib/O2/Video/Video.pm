package O2::Video::Video;

use strict;

use O2 qw($config);
use File::Temp qw(tempdir);

#------------------------------------------------------------
sub new {
  my ($pkg, %params) = @_;

  my $mplayerPath = $params{mplayerPath} || $config->get('o2.mplayer');
  die __PACKAGE__.": Could not find videofile '$params{filePath}'" if $params{filePath} && !-e $params{filePath};
  
  return bless {
    mplayer   => $mplayerPath,
    videoFile => $params{filePath},
  }, $pkg;
  
}
#------------------------------------------------------------
sub newFromFile {
  my($pkg, %params) = @_;
  my $obj = $pkg->new(%params);
  return $obj;
}
#------------------------------------------------------------
sub _getInformation {
  my ($obj) = @_;
  
  my $cmd    = $obj->{mplayer} . ' -vo null -ao null -frames 0 -identify ' . $obj->{videoFile};
  my $output = $obj->_runProcess($cmd);
  my %information;
  foreach my $line (@{$output}) {
    if ($line =~ m/^VIDEO\:.+\s(\d+)bpp.+/) {
      $information{video_bpp} = $1;
    }
    elsif ($line =~ m/^ID_([^=]+)\=(.+)\n?$/ixms) {
      $information{ lc $1 } = $2;
    }
  }
  return \%information;
}
#------------------------------------------------------------
sub getClipName {
  my ($obj) = @_;
  $obj->{videoInformation} ||= $obj->_getInformation();
  return $obj->{videoInformation}->{name};
}
#------------------------------------------------------------
sub getClipAuthor {
  my ($obj) = @_;
  $obj->{videoInformation} ||= $obj->_getInformation();
  return $obj->{videoInformation}->{author};
}
#------------------------------------------------------------
sub getClipCopyright {
  my ($obj) = @_;
  $obj->{videoInformation} ||= $obj->_getInformation();
  return $obj->{videoInformation}->{copyright};
}
#------------------------------------------------------------
sub getClipComments {
  my ($obj) = @_;
  $obj->{videoInformation} ||= $obj->_getInformation();
  return $obj->{videoInformation}->{comments};
}
#------------------------------------------------------------
sub getCodec {
  my ($obj) = @_;
  $obj->{videoInformation} ||= $obj->_getInformation();
  return $obj->{videoInformation}->{video_codec};
}
#------------------------------------------------------------
sub getDemuxer {
  my ($obj) = @_;
 $obj->{videoInformation} ||= $obj->_getInformation();
  return $obj->{videoInformation}->{demuxer};
}
#------------------------------------------------------------
sub getLength {
  my ($obj) = @_;
  $obj->{videoInformation} ||= $obj->_getInformation();
  return $obj->{videoInformation}->{length};
}
#------------------------------------------------------------
sub getFormat {
  my ($obj) = @_;
  $obj->{videoInformation} ||= $obj->_getInformation();
  return $obj->{videoInformation}->{video_format};
}
#------------------------------------------------------------
sub getBitrate {
  my ($obj) = @_;
  $obj->{videoInformation} ||= $obj->_getInformation();
  return $obj->{videoInformation}->{video_bitrate};
}
#------------------------------------------------------------
sub getWidth {
  my ($obj) = @_;
  $obj->{videoInformation} ||= $obj->_getInformation();
  return $obj->{videoInformation}->{video_width};
}
#------------------------------------------------------------
sub getHeight {
  my ($obj) = @_;
  $obj->{videoInformation} ||= $obj->_getInformation();
  return $obj->{videoInformation}->{video_height};
}
#------------------------------------------------------------
sub getColorDepth {
  my ($obj) = @_;
  $obj->{videoInformation} ||= $obj->_getInformation();
  return $obj->{videoInformation}->{video_bpp};
}
#------------------------------------------------------------
sub getFPS {
  my ($obj) = @_;
  $obj->{videoInformation} ||= $obj->_getInformation();
  return $obj->{videoInformation}->{video_fps};
}
#------------------------------------------------------------
sub getAspect {
  my ($obj) = @_;
  $obj->{videoInformation} ||= $obj->_getInformation();
  return $obj->{videoInformation}->{video_aspect};
}
#------------------------------------------------------------
sub getAudioCodec {
  my ($obj) = @_;
  $obj->{videoInformation} ||= $obj->_getInformation();
  return $obj->{videoInformation}->{audio_codec};
}
#------------------------------------------------------------
sub getAudioFormat {
  my ($obj) = @_;
  $obj->{videoInformation} ||= $obj->_getInformation();
  return $obj->{videoInformation}->{audio_format};
}
#------------------------------------------------------------
sub getAudioBitrate {
  my ($obj) = @_;
  $obj->{videoInformation} ||= $obj->_getInformation();
  return $obj->{videoInformation}->{audio_bitrate};
}
#------------------------------------------------------------
sub getAudioRate {
  my ($obj) = @_;
  $obj->{videoInformation} ||= $obj->_getInformation();
  return $obj->{videoInformation}->{audio_rate};
}
#------------------------------------------------------------
sub getAudioNumChannels {
  my ($obj) = @_;
  $obj->{videoInformation} ||= $obj->_getInformation();
  return $obj->{videoInformation}->{audio_nch};
}
#------------------------------------------------------------
sub captureImage {
  my ($obj, %params) = @_;
  umask 0002;
  $params{numImages} ||= 1;
  $params{startFrom} ||= 0;
  $params{format}    ||= 'jpeg';
  $params{format}      = 'jpeg' if $params{format} eq 'jpg';
  my $tempDir = tempdir();
  mkdir $tempDir, oct 775 or die "could not create tempdir $tempDir";
  # outdir is a bit buggy on windows, mplayer can't handle path's with c:\ cause : its used as delimiter as well
  # using CD instead
  #my $cmd=$obj->{mplayer}." -vo $format:outdir=$tempDir -ao null -ss $movieTime -frames $totalToCapture $filePath";
  my $cmd = "cd $tempDir && $obj->{mplayer} -really-quiet -vo $params{format} -ao null -ss $params{startFrom} -frames $params{numImages} $obj->{videoFile}";
  my $output = $obj->_runProcess($cmd);

  opendir DIR, $tempDir or die "Could not opendir '$tempDir'";
  my @imageFiles;
  foreach my $file (grep { /\d+\.\w{3,4}/ } readdir DIR) {
    if (-e "$tempDir/$file") {
      push @imageFiles,"$tempDir/$file";
    }
  }
  closedir DIR;
  return @imageFiles;
}
#------------------------------------------------------------
sub _runProcess {
  my ($obj, $cmd) = @_;

  my @output;
  eval {
    my $pid = open IN, '-|', $cmd or die "Error $@";
    while (<IN>) { 
      chomp;
      push @output,$_; 
    }
    close IN;
  };
  die __PACKAGE__.": could not run cmd '$cmd' -> $@ $!" if $@;
  return \@output; 
}
#------------------------------------------------------------
1;

__END__

mplayer -vo null -ao null -frames 0 -identify 210.wmv
mplayer -vo jpeg or png -ss 90

mplayer -vo png -ao null -ss 6 -frames 1 -z 8 210.wmv
