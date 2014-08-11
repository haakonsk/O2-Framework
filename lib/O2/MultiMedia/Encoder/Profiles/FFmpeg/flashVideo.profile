{
  audioCodec               => 'libmp3lame',
  audioSamplingFrequency   => '22050',
  audioBitrate             => '96000',
  audioChannels            => '2',
  videoBitrate             => (600*1000), # its in bits and not k/bits any more
  videoSize                => '408x306',
  videoFrameRate           => '20',
  videoMotionEstimate      => 'full',
  videoEncodePass          => 2,
  defaultFileExtension     => 'flv',
#  videoSameQualityAsSource => 1,
  videoIQFactor            => 1,
  videoCompressionVBR      => 0.6,
}
