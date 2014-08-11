package O2::Util::SimpleCache::Memcached;

use strict;

use base 'O2::Util::SimpleCache';

use constant DEBUG => 0;
use O2 qw($context);

#------------------------------------------------------------
sub set {
  my ($obj, $cacheId, $content, %params) = @_;
  debug $cacheId;
  my ($metaData, $data) = $obj->_generateCacheData($content, %params);
  $context->getMemcached()->set( "SimpleCache:$cacheId", { metaData => $metaData, data => $data } );
  return 1;
}
#------------------------------------------------------------
sub _fetchCacheData {
  my ($obj, $cacheId) = @_;
  debug $cacheId;
  my $plds = $context->getMemcached()->get("SimpleCache:$cacheId");
  return ( $plds->{metaData}, $plds->{data} );
}
#------------------------------------------------------------
sub isCached {
  my ($obj, $cacheId) = @_;
  debug $cacheId;
  my $plds = $context->getMemcached()->get("SimpleCache:$cacheId");
  return 0 unless $plds;
  
  my $meta = $plds->{metaData};
  return 1 if $meta->{ttl} eq 'forever';
  return $meta->{timeCached} + $meta->{ttl} >= time;
}
#------------------------------------------------------------
sub delCached {
  my ($obj, $cacheId) = @_;
  debug $cacheId;
  $context->getMemcached()->delete("SimpleCache:$cacheId");
  return 1;
}
#------------------------------------------------------------
1;
