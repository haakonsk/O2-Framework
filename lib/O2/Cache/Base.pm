package O2::Cache::Base;

# Base module for the O2 API to the various Cache implementations that might be use on an O2 installation

use strict;

use O2 qw($context);
use Digest::MD5;
use O2::Util::Serializer;

#--------------------------------------------------------------------------------------------
sub new {
  my ($pkg,%init) = @_;
  return bless \%init, $pkg;
}
#--------------------------------------------------------------------------------------------
# API that must be implemeneted
#--------------------------------------------------------------------------------------------
sub get                   { die '"get" must be overiden';                   }
sub set                   { die '"set" must be overiden';                   }
sub delete                { die '"delete " must be overiden';               }
sub flushCache            { die '"flushCache" must be overiden';            }
sub getSQL                { die '"getSQL" must be overiden';                }
sub setSQL                { die '"setSQL" must be overiden';                }
sub deleteSQL             { die '"removeSQL" must be overiden';             }
sub flushCacheSQL         { die '"flushCacheSQL" must be overiden';         }
sub flushCacheSQLForTable { die '"flushCacheSQLForTable" must be overiden'; }
sub getCachedSQLs         { die '"getCachedSQLs" must be overiden';         }
#--------------------------------------------------------------------------------------------
# MISC Api to allow clients to test for misc caches logic
#--------------------------------------------------------------------------------------------
sub canCache {
  my ($obj) = @_;
  return $obj->{config}->{memcached}->{cacheOn};
}
#--------------------------------------------------------------------------------------------
sub canCacheObject {
  my ($obj) = @_;
  return $obj->{config}->{memcached}->{cacheOn} && $obj->{config}->{memcached}->{cacheObject};
}
#--------------------------------------------------------------------------------------------
sub canCacheSQL {
  my ($obj) = @_;
  return $obj->{config}->{memcached}->{cacheOn} && $obj->{config}->{memcached}->{cacheSQL};
}
#--------------------------------------------------------------------------------------------
sub disableCache {
  my ($obj) = @_;
  $obj->{config}->{memcached}->{cacheOn}     = 0;
  $obj->{config}->{memcached}->{cacheObject} = 0;
  $obj->{config}->{memcached}->{cacheSQL}    = 0;
}
#--------------------------------------------------------------------------------------------
sub disableObjectCache {
  my ($obj) = @_;
  $obj->{config}->{memcached}->{cacheObject} = 0;
}
#--------------------------------------------------------------------------------------------
sub disableSQLCache {
  my ($obj) = @_;
  $obj->{config}->{memcached}->{cacheSQL} = 0;
}
#--------------------------------------------------------------------------------------------
sub enableCache {
  my ($obj) = @_;
  $obj->{config}->{memcached}->{cacheOn}     = 1;
  $obj->{config}->{memcached}->{cacheObject} = 1;
  $obj->{config}->{memcached}->{cacheSQL}    = 1;
}
#--------------------------------------------------------------------------------------------
sub enableObjectCache {
  my ($obj) = @_;
  $obj->{config}->{memcached}->{cacheOn}     = 1;
  $obj->{config}->{memcached}->{cacheObject} = 1;
}
#--------------------------------------------------------------------------------------------
sub enableSQLCache {
  my ($obj) = @_;
  $obj->{config}->{memcached}->{cacheOn}  = 1;
  $obj->{config}->{memcached}->{cacheSQL} = 1;
}
#--------------------------------------------------------------------------------------------
sub sqlIsCachable {
  my ($obj, $sql) = @_;
  return 0 if !$obj->{config}->{memcached}->{cacheOn} || !$obj->{config}->{memcached}->{cacheSQL};
  return 0 if $sql =~ m{ order \s+ by \s+ rand\(\) }xmsi;
  return $sql =~ m/^\s*select/i;
}
#--------------------------------------------------------------------------------------------
# implementing this one for those cache methods that don't support deleting multiple items at once
sub deleteMulti {
  my ($obj, @cacheIds) = @_;
  return unless $obj->{config}->{memcached}->{cacheOn};
  
  foreach my $cacheId (@cacheIds) {
    $obj->delete($cacheId);
  }
}
#--------------------------------------------------------------------------------------------
sub setObject {
  my ($obj, $object, $timeout) = @_;
  return unless $obj->{config}->{memcached}->{cacheObject};
  return if !ref $object || !$object->can('getId');
  return $obj->setObjectById( $object->getId(), $object, $timeout );
}
#--------------------------------------------------------------------------------------------
sub setObjectById {
  my ($obj, $cacheId, $object, $timeout) = @_;
  return unless $obj->{config}->{memcached}->{cacheObject};
  
  if (ref $object && $object->can('isa') && $object->isa('O2::Obj::Object') && $object->isCachable()) {
    my $struct = eval {
      return $object->getObjectPlds(1);
    };
    if ($@) {
      warning sprintf "Couldn't cache object: %d (%s): $@", $object->getId(), $object->getMetaClassName();
      return 0;
    }
    debug "added object with cacheId: $cacheId to cache";
    return $obj->set('O2_OBJECT:' . $cacheId, $struct, $timeout);
  }
  return 0;
}
#--------------------------------------------------------------------------------------------
sub getObjectById {
  my ($obj, $cacheId) = @_;
  return unless $obj->{config}->{memcached}->{cacheObject};
  
  my $struct = $obj->get('O2_OBJECT:' . $cacheId);
  return 0 unless ref $struct;
  
  $obj->{serializer} ||= O2::Util::Serializer->new( format => 'DATAREF' );
  my $object = $obj->{serializer}->unserialize($struct);
  return 0 unless $object;
  
  debug "get object with cacheId: $cacheId, returned: $object";
  return $object;
}
#--------------------------------------------------------------------------------------------
sub deleteObject {
  my ($obj, $object) = @_;
  $object->getManager()->_uncacheForCurrentRequest( $object->getId() ) if $object;
  return unless $obj->{config}->{memcached}->{cacheObject};
  return if !ref $object || !$object->can('getId');
  return $obj->deleteObjectById( $object->getId() );
}
#--------------------------------------------------------------------------------------------
sub deleteObjectById {
  my ($obj, $objectId) = @_;
  return unless $obj->{config}->{memcached}->{cacheObject};
  
  debug "delete object with ID: $objectId";
  return $obj->delete("O2_OBJECT:$objectId");
}
#--------------------------------------------------------------------------------------------
# implementing here for those cache systems that don't support this
# NOTE a my $value=$cache->get(key) and then if(!$value) {..} would be faster in most cases
sub isCached {
  my ($obj, $cacheId) = @_;
  return 0 unless $obj->{config}->{memcached}->{cacheObject};
  return $obj->get($cacheId) ? 1 : 0;
}
#--------------------------------------------------------------------------------------------
# SQL helper methods
#--------------------------------------------------------------------------------------------
sub _getSQLTables {
  my ($obj, $sql) = @_;
  my $tables;
  if ($sql =~ m/^\s*select.+from\s+(.+?)\s+(where|order)/ims) { # select ... from TABLES where
    $tables = $1;
  }
  elsif ($sql =~ m/^\s*select.+from(.+)/ims) { # select ... from TABLES
    $tables = $1;
  }
  elsif ($sql =~ m/^\s*update\s+(.+?)\s+?set.+?/ims) { # update TABLES set where
    $tables = $1;
  }
  elsif ($sql =~ m/^\s*?insert\s+?into\s+(.+?)\s+?.+/ims ) {   # insert into TABLES () values ()
    $tables = $1;
  }
  elsif ($sql =~ m/^\s*?delete\s+?from\s+(.+?)\s+?(where|.*?)/ims) { # delete from TABLES where
     $tables = $1;
  }
  elsif ($sql =~ m/^\s*?drop\s+?table\s+(.+)\s*/ims) { # drop table TABLE
     $tables = $1;
  }
  elsif ($sql =~ m/^\s*?truncate\s+?table\s+(.+)\s*/ims) { # truncate table TABLE
     $tables = $1;
  }
  
  return undef unless $tables;
  
  my @foundTables =  split /,/, $tables;
  foreach my $t (@foundTables) {
    $t =~ s/^\s+//gms;
    $t =~ s/\s+$//gms;
    $t =~ s/^([^\s]+)\s+.+/$1/gms;
  }
  return wantarray ? @foundTables : \@foundTables;
}
#--------------------------------------------------------------------------------------------
sub getSQLCacheId {
  my ($obj, $sql) = @_;
  return unless $obj->{config}->{memcached}->{cacheSQL};
  
  my $cacheId = $obj->getSiteAwareCacheId($sql);
  $cacheId    =~ s/\n+/ /gms;
  return Digest::MD5::md5_hex($cacheId);
}
#--------------------------------------------------------------------------------------------
sub flushCacheForTablesInSQL { 
  my ($obj, $sql) = @_;
  return unless $obj->{config}->{memcached}->{cacheSQL};
  
  my $tables = $obj->_getSQLTables($sql);
  foreach my $table (@{$tables}) {
    $obj->flushCacheSQLForTable($table);
  }
  return 1;
}
#--------------------------------------------------------------------------------------------
sub getSiteAwareCacheId {
  my ($obj, $cacheId) = @_;
  return $context->getEnv('O2CUSTOMERROOT') . "|$cacheId";
}
#--------------------------------------------------------------------------------------------
1;
__END__

my $cacheHandler = $context->getMemcached();
my $value = $cacheHandler->get($cacheId);

$cacheHandler->delete( $cacheId );
$cacheHandler->set($cacheId, $value);
$cacheHandler->get($cacheId ) 

# SQL - only fetch

my $objectId = $cacheHandler->getSQL('select objectId from O2_OBJ_OBJECT where id = 100');

$cacheHandler->setSQL('select ....O2_OBJ_OBJECT', $result);
$cacheHandler->flushSQLCache();
$cacheHandler->flushSQLCacheForTable('O2_OBJ_OBJECT');
