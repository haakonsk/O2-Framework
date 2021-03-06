{
  audioCodec                => 'libamr_nb',
  audioSamplingFrequency    => '8000',
  audioBitrate              => '12.2k',
  audioChannels             => '1',
  videoSize                 => '176x144',
  videoBitrate              => (64*1000),
  videoCodec                => 'h263',
  videoFrameRate            => '14',
  videoMotionEstimate       => 'full',
  videoEncodePass           => 2,
  defaultFileExtension      => '3gp',
#  videoSameQualityAsSource => 1,
  videoIQFactor             => 1,
}
