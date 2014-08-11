package O2::MultiMedia::Encoder::FFmpeg;

use strict;

use base 'O2::MultiMedia::Encoder::Encoder';

#------------------------------------------------------------
sub new {
  my ($pkg, %init) = @_;
  my $obj = $pkg->SUPER::new(%init);
  $obj->{ffmpeg} = '/usr/local/ffmpeg/bin/ffmpeg';
  return $obj;
}
#------------------------------------------------------------
sub encode {
  my ($obj, $inMedia, $outMedia) = @_;
  
  my $totalPass = 1;
  if ($obj->getOption('videoEncodePass') == 2) {
    $totalPass = 2;
    if (!$obj->getOption('videoEncodePassLogfile')) {
      $obj->setOption('videoEncodePassLogfile','twoPassLogFile.' . time . '.ffmpeg.log');
    }
    $obj->setOption('videoEncodePass', 1); # starting on the first one
  }
  else {
    delete $obj->{videoEncodePass};
    delete $obj->{videoEncodePassLogfile};
  }
  my $currentPass = 1;
  while ($currentPass <= $totalPass) {
    my @cmdArgs;
    push @cmdArgs, "-i $inMedia";
    push @cmdArgs, $obj->getCmdOptions();
    push @cmdArgs, '-y' if $currentPass > 1;
    push @cmdArgs, $outMedia;
    
    my $cmd = "$obj->{ffmpeg} " . join ' ', @cmdArgs;
    $obj->_execCMD($cmd);
    $currentPass++;
    $obj->setOption('videoEncodePass', $currentPass);
  }
  
  if (-e $obj->getOption('videoEncodePassLogfile')) {
#    unlink $obj->getOption('videoEncodePassLogfile');
  }
  return $outMedia;
}
#------------------------------------------------------------
sub getEncoderName {
  my ($obj) = @_;
  return 'FFmpeg';
}
#------------------------------------------------------------
sub getAvailableOptions {
  my ($obj) = @_;
  # ref url: http://ffmpeg.mplayerhq.hu/ffmpeg-doc.html
  return {
    title => {
      cmd  => 'title',
      rule => '^.+$',
    },
    author =>  {
      cmd  => 'author',
      rule => '^.+$',
    },
    copyright =>  {
      cmd  => 'copyright',
      rule => '^.+$',
    },
    comment =>  {
      cmd  => 'comment',
      rule => '^.+$',
    },
    year =>  {
      cmd  => 'year',
      rule => '^\d\d\d\d$',
    },
    duration => {
      cmd  => 't',
      rule => '^\d\d\:\d\d:\d\d$',
    },
    seek => {
      cmd  => 'ss',
      rule => '^\d\d\:\d\d:\d\d$',
    },
    videoBitrate => {
      cmd  => 'b',
      rule => '^\d+$',
    },
    videoFrameRate => {
      cmd  => 'r',
      rule => '^\d+$',
    },
    videoSize => {
      cmd  => 's',
      rule => '^\d+x\d+$',
    },
    videoAspectRatio => {
      cmd  => 'aspect',
      rule => '^[\d+\:\.]+$',
    },
    videoBitrateTolerance => {
      cmd  => 'bt',
      rule => '^\d+$',
    },
    videoMaxBitrate => {
      cmd  => 'maxrate',
      rule => '^\d+$',
    },
    videoMinBitrate => {
      cmd  => 'minrate',
      rule => '^\d+$',
    },
    videoBufferSize => {
      cmd  => 'bufsize',
      rule => '^\d+$',
    },
    videoCodec => {
      cmd  => 'vcodec',
      rule => '^.+$',
    },
    videoSameQualityAsSource => {
      cmd  => 'sameq',
      rule => 'boolean',
    },
    videoEncodePass =>  {
      cmd  => 'pass',
      rule => '^(1|2)$',
    },
    videoEncodePassLogfile => {
      cmd  => 'passlogfile',
      rule => '^.+$',
    },
    videoVBR => {
      cmd  => 'qscale',
      rule => '^\d+$',
    },
    videoMinVBR => {
      cmd  => 'qmin',
      rule => '^\d+$',
    },
    videoMaxVBR => {
      cmd  => 'qmax',
      rule => '^\d+$',
    },
    videoDiffVBR => {
      cmd  => 'qdiff',
      rule => '^\d+$',
    },
    videoBlurVBR => {
      cmd  => 'qblur',
      rule => '^\d+$',
    },
    videoCompressionVBR => {
      cmd  => 'qcomp',
      rule => '^\d+$',
    },
    videoRCinitComplexity => {
      cmd  => 'rc_init_cplx',
      rule => '^\d+$',
    },
    videoBQFactor => {
      cmd  => 'b_qfactor',
      rule => '^\d+$',
    },
    videoIQFactor => {
      cmd  => 'i_qfactor',
      rule => '^\d+$',
    },
    videoBQOffset => {
      cmd  => 'b_qoffset',
      rule => '^\d+$',
    },
    videoIQOffset => {
      cmd  => 'i_qoffset',
      rule => '^\d+$',
    },
    videoRCequation => {
      cmd  => 'rc_eq',
      rule => '^\d+$',
    },
    videoRCOveride => {
      cmd  => 'rc_override',
      rule => '^\d+$',
    },
    videoMotionEstimate => {
      cmd    => 'me',
      values => ['zero','phods','log','x1','epzs','full'],
    },
    videoDCTAlgoritm => {
      cmd    => 'dct_algo',
      values => {
        '0' => 'FF_DCT_AUTO (default)',
        '1' => 'FF_DCT_FASTINT',
        '2' => 'FF_DCT_INT',
        '3' => 'FF_DCT_MMX',
        '4' => 'FF_DCT_MLIB',
        '5' => 'FF_DCT_ALTIVEC',
      },
    },
    videoIDCTAlgoritm => {
      cmd    => 'Idct_algo',
      values => {
        '0'  => 'FF_IDCT_AUTO (default)',
        '1'  => 'FF_IDCT_INT', 
        '2'  => 'FF_IDCT_SIMPLE', 
        '3'  => 'FF_IDCT_SIMPLEMMX', 
        '4'  => 'FF_IDCT_LIBMPEG2MMX', 
        '5'  => 'FF_IDCT_PS2', 
        '6'  => 'FF_IDCT_MLIB', 
        '7'  => 'FF_IDCT_ARM', 
        '8'  => 'FF_IDCT_ALTIVEC', 
        '9'  => 'FF_IDCT_SH4', 
        '10' =>'FF_IDCT_SIMPLEARM',
      },
    },
    videoErrorResilience => {
      cmd    => 'er',
      values => {
        '1' => 'FF_ER_CAREFUL (default)',
        '2' => 'FF_ER_COMPLIANT',
        '3' => 'FF_ER_AGGRESSIVE',
        '4' => 'FF_ER_VERY_AGGRESSIVE',                                              
      }
    },
    videoErrorConcealment => {
      cmd    => 'ec',
      values => {
        '1' => 'FF_EC_GUESS_MVS (default = enabled)', 
        '2' => 'FF_EC_DEBLOCK (default = enabled)'
      }
    },
    videoUseBFrames => {
      cmd  => 'bf',
      rule => '^\d+$',
    },
    videoMacroBlock => {
      cmd    => 'mbd',
      values => {
        '0' => 'FF_MB_DECISION_SIMPLE: Use mb_cmp (cannot change it yet in FFmpeg)',
        '1' => 'FF_MB_DECISION_BITS: Choose the one which needs the fewest bits.',
        '2' => 'FF_MB_DECISION_RD: rate distortion',
      },
    },
    videoUse4MotionVector => {
      cmd => '4mv',
    },
    videoUseDataPartioning => {
      cmd => 'part',
    },
    videoStrictness => {
      cmd  => 'strict',
      rule =>  '^\d+$',
    },
    videoAIC => {
      cmd => 'aic',
    },
    videoUMV => {
      cmd => 'umv',
    },
    videoDeInterlace => {
      cmd => 'deinterlace',
    },
    videoForceILME => {
      cmd => 'ilme',
    },
    audioSamplingFrequency => {
      cmd  => 'ar',
      rule => '^\d+$',
    },
    audioBitrate => {
      cmd  => 'ab',
      rule => '^\d+$',
    },
    audioChannels => {
      cmd  => 'ac',
      rule => '^\d+$',
    },
    audioDisable => {
      cmd => 'an',
    },
    audioCodec => {
      cmd  => 'acodec',
      rule => '^.+$',
    },
  };
}
#------------------------------------------------------------
1;
