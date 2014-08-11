package O2::Util::SimpleCache::Files;

use strict;

use base 'O2::Util::SimpleCache';

use O2 qw($context);

#------------------------------------------------------------
sub createObject {
  my ($pkg, %params) = @_;
  my $obj = $pkg->SUPER::createObject(%params);
  
  my $cachePath;
  $cachePath   = $params{cachePath} if $params{cachePath} && -d $params{cachePath};
  $cachePath ||= $context->getSitePath() . '/var/cache/simpleCache';
  $context->getSingleton('O2::File')->mkPath($cachePath) unless -d $cachePath;
  $obj->{cachePath} = $cachePath;
  
  return $obj;
}
#------------------------------------------------------------
sub set {
  my ($obj, $cacheId, $content, %params) = @_;
  
  my ($metaData, $data) = $obj->_generateCacheData($content, %params);
  
  my $cacheFile = $obj->getCachePath($cacheId, 1);
  return 0 unless $cacheFile;
  
  $context->getSingleton('O2::Data')->save("${cacheFile}Meta", $metaData);
  $context->getSingleton('O2::File')->writeFileWithFileEncoding($cacheFile, 'utf-8', $data);
  return 1;
}
#------------------------------------------------------------
sub _fetchCacheData {
  my ($obj, $cacheId) = @_;
  my $cacheFile = $obj->getCachePath($cacheId);
  return (
           $context->getSingleton('O2::Data')->load("${cacheFile}Meta"),
    scalar $context->getSingleton('O2::File')->getFile($cacheFile),
  );
}
#------------------------------------------------------------
sub isCached {
  my ($obj, $cacheId) = @_;
  
  my $cacheFile     = $obj->getCachePath($cacheId);
  my $metaCacheFile = $cacheFile . 'Meta';
  return 0 if !-e $cacheFile || !-e $metaCacheFile;
  
  my $meta = eval $context->getSingleton('O2::File')->getFile($metaCacheFile);
  return 1 if $meta->{ttl} eq 'forever';
  return $meta->{timeCached} + $meta->{ttl} >= time;
}
#------------------------------------------------------------
sub getCachePath {
  my ($obj, $cacheId, $mkDirs) = @_;
  return $context->getSingleton('O2::File')->distributePath(
    id       => $cacheId,
    rootDir  => $obj->{cachePath},
    fileName => "$cacheId.o2Cached",
    mkDirs   => $mkDirs,
  );
}
#------------------------------------------------------------
sub delCached {
  my ($obj, $cacheId) = @_;
  my $cachePath = $obj->getCachePath($cacheId);
  my $cacheMetaFile = $cachePath . 'Meta';
  unlink $cachePath     if -e $cachePath;
  unlink $cacheMetaFile if -e $cacheMetaFile;
  return 1;
}
#------------------------------------------------------------
1;
