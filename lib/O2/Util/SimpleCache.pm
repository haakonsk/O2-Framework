package O2::Util::SimpleCache;

# A very simple cache manager for O2 objects (via getPLDS) and other custom data. 

use strict;

use constant DEBUG => 0;
use O2 qw($context $config);

#------------------------------------------------------------
sub new {
  my ($pkg, %params) = @_;
  my $obj;
  if (($params{dataStore} && $params{dataStore} eq 'memcached')  ||  (!$params{dataStore} && $config->get('cache.simpleCache.dataStore') eq 'memcached' && $context->getMemcached()->isa('O2::Cache::MemcachedFast'))) {
    require O2::Util::SimpleCache::Memcached;
    $obj = O2::Util::SimpleCache::Memcached->createObject();
  }
  else {
    require O2::Util::SimpleCache::Files;
    $obj = O2::Util::SimpleCache::Files->createObject();
  }
  $obj->{ttl} = $params{ttl} || 0;
  debug "New SimpleCache object (ttl=$obj->{ttl}) is of class " . ref $obj;
  return $obj;
}
#------------------------------------------------------------
sub createObject {
  my ($pkg) = @_;
  return bless {}, $pkg;
}
#------------------------------------------------------------
sub _generateCacheData {
  my ($obj, $content, %params) = @_;
  
  # metaData: describes a little what this object/file/string/plds is cached as
  my $metaData = {
    cacheBy    => scalar caller,
    timeCached => time,
    time       => scalar localtime,
    ttl        => $params{ttl} || $obj->{ttl},
  };
  
  my $data;
  if (ref $content eq 'HASH' || ref $content eq 'ARRAY') {
    $metaData->{type} = 'plds';
    $data = $context->getSingleton('O2::Data')->dump($content);
  }
  elsif ( ref $content  &&  $content->can('isa')  &&  $content->isa('O2::Obj::Object')  &&  $content->isCachable() ) {
    $metaData->{type} = 'O2 object';
    $data = $context->getSingleton('O2::Util::Serializer', format => 'PLDS')->serialize($content);
  }
  else {
    $metaData->{type} = 'raw';
    $data = $content;
  }
  
  return ($metaData, $data);
}
#------------------------------------------------------------
sub get {
  my ($obj, $cacheId) = @_;
  return undef unless $obj->isCached($cacheId);
  
  my ($metaData, $dataStr) = $obj->_fetchCacheData($cacheId);
  my $cacheType = $metaData->{type};
  
  return eval $dataStr                                                                           if $cacheType eq 'plds';
  return      $dataStr                                                                           if $cacheType eq 'raw';
  return $context->getSingleton('O2::Util::Serializer', format => 'PLDS')->unserialize($dataStr) if $cacheType =~ m{\AO2(?: Meta)? object\z}ms;
  
  warning "Unknown cacheType $cacheType";
  return undef;
}
#------------------------------------------------------------
sub flushCache {
  my ($obj) = @_;
  die 'Not implemented';
}
#------------------------------------------------------------
1;
