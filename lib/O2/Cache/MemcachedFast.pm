package O2::Cache::MemcachedFast;

# O2 API to Cache::Memcached::Fast
# http://www.danga.com/memcached/

use strict;

use base 'O2::Cache::Base';

use constant DEBUG => 0;

use O2 qw($context);
use Time::HiRes qw(time usleep);
use Cache::Memcached::Fast;

use constant DB_TABLES => $context->getEnv('O2CUSTOMERROOT') . "|__DB_TABLES";

#--------------------------------------------------------------------------------------------
sub new {
  my ($pkg, %params) = @_;
  my $cacheIsOn = $context->cacheIsEnabled();
  $cacheIsOn    = $params{config}->{memcached}->{cacheOn} unless defined $cacheIsOn;
  if (exists $params{config} && $cacheIsOn && $params{config}->{memcached}) {
    eval {
      $params{_memcached} = new Cache::Memcached::Fast {
        servers            => $params{config}->{memcached}->{servers},
        compress_threshold => $params{config}->{memcached}->{compress_threshold} || 10_000,
        utf8               => 1,
        # enable_compress    => 0,
      };
      $params{_memcached}->enable_compress(1);
    };
    return undef if $@;
  }
  return $pkg->SUPER::new(%params) if ref $params{_memcached} eq 'Cache::Memcached::Fast';
  return undef;
}
#--------------------------------------------------------------------------------------------
sub get {
  my ($obj, $cacheId) = @_;
  return unless $obj->{config}->{memcached}->{cacheOn};
  return $obj->_get($cacheId);
}
#--------------------------------------------------------------------------------------------
sub _get {
  my ($obj, $cacheId) = @_;
  $cacheId = $context->getEnv('O2CUSTOMERROOT') . "|$cacheId";
  return $obj->{_memcached}->get($cacheId);
}
#--------------------------------------------------------------------------------------------
sub set {
  my ($obj, $cacheId, $cacheItem, $timeout) = @_;
  return $obj->delete($cacheId) unless $obj->{config}->{memcached}->{cacheOn};
  
  my $isSuccess = eval {
    $obj->_set($cacheId, $cacheItem, $timeout);
  };
  if ($@) {
    require Data::Dumper;
    die "MemcachedFast->set failed for $cacheId: $@<br>\nCacheItem: " . Data::Dumper::Dumper($cacheItem);
  }
  die "MemcachedFast->set failed for $cacheId: Returned undef" unless defined $isSuccess;
  die "MemcachedFast->set failed for $cacheId: Returned false" unless         $isSuccess;
  return 1;
}
#--------------------------------------------------------------------------------------------
sub _set {
  my ($obj, $cacheId, $cacheItem, $timeout) = @_;
  $cacheId = $context->getEnv('O2CUSTOMERROOT') . "|$cacheId";
  no warnings;
  $obj->{_memcached}->set( $cacheId, $cacheItem, $timeout || 'never' );
}
#--------------------------------------------------------------------------------------------
sub delete {
  my ($obj, $cacheId) = @_;
  debug join ("::", caller) . " :\e[31mDELETE\e[0m, $cacheId";
  $obj->_delete($cacheId);
}
#--------------------------------------------------------------------------------------------
sub _delete {
  my ($obj, $cacheId) = @_;
  $cacheId = $context->getEnv('O2CUSTOMERROOT') . "|$cacheId";
  return $obj->{_memcached}->delete($cacheId);
}
#--------------------------------------------------------------------------------------------
sub deleteMulti {
 my ($obj, @cacheIds) = @_;
 @cacheIds = map { $context->getEnv('O2CUSTOMERROOT') . "|$_" } @cacheIds;
 return $obj->{_memcached}->delete_multi(@cacheIds);
}
#--------------------------------------------------------------------------------------------
sub flushCache {
  my ($obj) = @_;
  #  return $obj->{_memcached}->flush_all();
}
#--------------------------------------------------------------------------------------------
# SQL Caching from here
#--------------------------------------------------------------------------------------------
sub _getVersionSQLCacheId {
  my ($obj, $cacheId, $sql, $readOnlyMode) = @_;
  my $startTime = time;
  return unless $obj->{config}->{memcached}->{cacheSQL};
  my $tables = $obj->_getSQLTables($sql);
  my %tHash = map { $_ => 1 } @{$tables};
  
  my $tableVersions = $obj->_getCurrentVersionForTables($tables, $readOnlyMode);
  return unless $tableVersions; # We could not get a lock

  $cacheId .= '_' . join '_', map { $tableVersions->{$_} } grep { $tHash{$_} } sort keys %{$tableVersions};
  return $cacheId;
}
#--------------------------------------------------------------------------------------------
sub _getCurrentVersionForTables {
  my ($obj, $targetTables, $readOnlyMode) = @_;

  if ($readOnlyMode || $obj->_getLock(DB_TABLES) ) {
    my $tableVersions =  $obj->{_memcached}->get(DB_TABLES);
    my $hadToSetTable = 0;
    foreach my $tv (@{$targetTables}) {
      if ( !$tableVersions->{$tv} ) { # this table has not been cached before lets create a table version nr
        $tableVersions->{$tv} = 1;
        #$tableVersions->{$tv} = $obj->{_memcached}->incr($tv, 1);
        $hadToSetTable = 1;
      }
    }
    if (!$readOnlyMode) {
      $obj->{_memcached}->set('__DB_TABLES', $tableVersions) if $hadToSetTable;
      $obj->_releaseLock(DB_TABLES);
    }
    return $tableVersions;
  }
  return undef; # could not get a lock for this
}
#--------------------------------------------------------------------------------------------
sub setSQL {
  my ($obj, $sql, $cacheItem, $expires, $callerRef) = @_;
  return unless $obj->{config}->{memcached}->{cacheSQL};
  
  my $startTime = time;
  my $cacheId = $obj->getSQLCacheId($sql);

  if ( $obj->_getLock($cacheId) ) {

    my $versionCacheId = $obj->_getVersionSQLCacheId($cacheId, $sql);
    if (!$versionCacheId) {
      $obj->_releaseLock($cacheId); # release to lock for this cacheId
      warning join ('::', caller) . " : Could not get versionCacheId for cacheId: $cacheId, something wrong with get lock on __DB_TABLES?";
      return 0;
    }
    
    my $toCache = { 
      sql       => $sql,
      cacheTime => scalar localtime time,
      cacheItem => $cacheItem
    };
    
    $expires ||= 3600 * 48; # Default: expires in 48 hours
    if ( $obj->set($versionCacheId, $toCache, $expires) ) {
      $obj->_releaseLock($cacheId); # release to lock for this cacheId
      #   print "Used $sql: ".sprintf("%.3f",(time-$startTime))."s\n\n";
      if (DEBUG) {
        my $d = $context->getSingleton('O2::Data');
        debug join ("::", caller) . " :\e[31mSET\e[0m $versionCacheId -> $sql , set:\n" . $d->dump($toCache);
      }                 
      return 1;
    }
  }
  # We either couldn't get the lock or the setSQL went wrong
#  $obj->_releaseLock($cacheId); # release to lock for this cacheId
  return 0;
}
#--------------------------------------------------------------------------------------------
sub getSQL {
  my ($obj, $sql) = @_;
  return unless $obj->{config}->{memcached}->{cacheSQL};

  my $cacheId = $obj->getSQLCacheId($sql);
  my $versionCacheId = $obj->_getVersionSQLCacheId($cacheId, $sql, 'READONLY');

  my $cacheVal = $obj->get($versionCacheId);
  if (DEBUG && $cacheVal) {
    my $d = $context->getSingleton('O2::Data');
    debug join ("::", caller) . " :\e[32mGET\e[0m, $versionCacheId -> $sql , returned: \n" . $d->dump($cacheVal);
  }

  # Extra err handling when things are not cached as array
  return $cacheVal->{cacheItem} if ref $cacheVal eq 'HASH' && exists $cacheVal->{cacheItem};
  
  if ($cacheVal) {
    my $d = $context->getSingleton('O2::Data');
    warning join ('::', caller) . " :wrong format on cached element. $versionCacheId $sql -> " . $d->dump($cacheVal);
  }
  return undef;
}
#--------------------------------------------------------------------------------------------
sub removeSQL {
  my ($obj, $sql) = @_;
  return unless $obj->{config}->{memcached}->{cacheSQL};
  my $cacheId = $obj->getSQLCacheId($sql);
 
  if ( $obj->_getLock($cacheId) ) {
    my $versionCacheId = $obj->_getVersionSQLCacheId($cacheId, $sql);
    if ($obj->{_memcached}->delete($cacheId)) {
      debug join ("::", caller) . " :removed $sql to with $cacheId";
      $obj->_releaseLock($cacheId); # release to lock for this cacheId
      return 1;
    }
  }
  warning join ("::", caller) . " :could not remove $sql with $cacheId";
  return 0;
} 
#--------------------------------------------------------------------------------------------
sub flushCacheSQL {
  my ($obj) = @_;
  return unless $obj->{config}->{memcached}->{cacheSQL};
  
  my $startTime = time;
  
  if ( $obj->_getLock(DB_TABLES) ) {
    my $tables = $obj->{_memcached}->get(DB_TABLES);
    foreach my $table (keys %{$tables}) {
      $tables->{$table}++;
    }
    if ( $obj->{_memcached}->set(DB_TABLES, $tables) ) {
      $obj->_releaseLock(DB_TABLES);
      debug join ("::", caller) . " :flushed SQL cache, used: " . sprintf ('%.3f', time-$startTime) . 's';
      return 1;
    }
  }
  $obj->_releaseLock(DB_TABLES);
  warning join ("::", caller) . " :could not flush SQL cache, used: " . sprintf ('%.3f', time-$startTime) . 's';
  return 0;
} 
#--------------------------------------------------------------------------------------------
sub flushCacheSQLForTable {
  my ($obj, $tableName) = @_;
  return unless $obj->{config}->{memcached}->{cacheSQL};
  my $startTime = time;

  if ( $obj->_getLock(DB_TABLES) ) {
    my $tables = $obj->{_memcached}->get(DB_TABLES);
    if ( exists $tables->{$tableName} ) {
      $tables->{$tableName}++;
    }
    if ( $obj->{_memcached}->set(DB_TABLES, $tables) ) {
      $obj->_releaseLock(DB_TABLES);
      debug join ("::", caller) . " :flushed cache for table '$tableName', used: " . sprintf ('%.3f', time-$startTime) . 's';
      return 1;
    }
  }
  $obj->_releaseLock(DB_TABLES);
  warning join ("::", caller) . " :flushing of cache for table '$tableName' went wrong, used: " . sprintf ('%.3f', time-$startTime) . 's';
  return 0;
} 
#--------------------------------------------------------------------------------------------
sub flushCacheForTablesInSQL { 
  my ($obj, $sql) = @_;
  return unless $obj->{config}->{memcached}->{cacheSQL};
  my $startTime = time;
  my $tables = $obj->_getSQLTables($sql);
  my $tablesInCache;
  if( $obj->_getLock(DB_TABLES) ) {
    $tablesInCache = $obj->{_memcached}->get(DB_TABLES);
    my $didUpdate = 0;
    foreach my $table (@{$tables}) {
      if ( exists $tablesInCache->{$table} ) {
        $tablesInCache->{$table}++;
        $didUpdate = 1;
      }
    }
    if (!$didUpdate) {
      $obj->_releaseLock(DB_TABLES);
      return 1;
    }
  }

  if ( $obj->{_memcached}->set(DB_TABLES, $tablesInCache) ) {
    $obj->_releaseLock(DB_TABLES);
    debug join ("::", caller) . " :flushed cache for tables in $sql, used: " . sprintf ('%.3f', time-$startTime) . 's';
    return 1;
  }
  $obj->_releaseLock(DB_TABLES);
  warning join ("::", caller) . " :flushing of cache for tables in $sql went wrong, used: " . sprintf ('%.3f', time-$startTime) . 's';
  return 0;
}
#--------------------------------------------------------------------------------------------
sub getCachedTables {
  my ($obj) = @_;
  return unless $obj->{config}->{memcached}->{cacheSQL};
  return $obj->{_memcached}->get(DB_TABLES);
}
#--------------------------------------------------------------------------------------------
# Locking methods
#--------------------------------------------------------------------------------------------
sub _getLock {
  my ($obj, $cacheId) = @_;
  
  my $totalSleep = 100000;
  my $lockId = $cacheId . '_LOCK';
  while ($totalSleep > 0) {
    my $lockKey = $obj->{_memcached}->incr($lockId);
    if (!$lockKey) { # No key in cache.
      last if $obj->{_memcached}->set($lockId, 1); # We take the lock now
    } 
    elsif ($lockKey == 1) { # We got the lock. if 0 no look if > 1 somebody else have the lock atm
      last;
    }
    elsif ($lockKey > 1) {
      # it has been tried to be locked serveral times, we might want to release if this number gets to high
    }
    $totalSleep -= usleep(1000); #wait a litttttle bit, before we try again
  }
  if ($totalSleep < 0) { # didn't get the lock 
    warning join ("::", caller) . " : Lock could not be obtained for $cacheId [$lockId]";
    return 0;
  }

  if (DEBUG) {
    $obj->{_lockIds}->{$lockId} = time; # some debugging and timing info
    debug join ("::", caller) . " : Lock obtained for cacheId: $cacheId [$lockId]";
  }                 

  return 1;
}
#--------------------------------------------------------------------------------------------
# Should I maybe release all locks created by this PID/Process upon END or DESTROY????? Locks should probably never survive across PIDs or processes?
sub _releaseLock {
  my ($obj, $cacheId) = @_;
  my $lockId = $cacheId . '_LOCK';

  my $debugMethod = sub {
    my ($caller) = @_;
    if (DEBUG) {
      my $lockTime = sprintf ('%.4f', time - $obj->{_lockIds}->{$lockId} ); 
      debug $caller." : Lock released for cacheId: $cacheId [$lockId], lockTime: $lockTime s ";
      delete $obj->{_lockIds}->{$lockId}
    }                 
  };

  if ( $obj->{_memcached}->set($lockId, 0) ) { # release the lock by setting it to zero
    &$debugMethod(join "::", caller);
    return 1;
  }
  elsif ( $obj->{_memcached}->set($lockId, 0) ) { # release the lock by setting it to zero, basically this is the second try in case the first goes wrong
    &$debugMethod(join "::", caller);
    return 1;
  }
  
  warning join ("::", caller) . " : Lock could not be released for $cacheId [$lockId]";
  return 0; # could not release the obtained lock for some reason, even after the two above tries
}
#--------------------------------------------------------------------------------------------
sub _isLocked {
  my ($obj, $cacheId) = @_;
  my $lockId = $cacheId . '_LOCK';
  return $obj->{_memcached}->get($lockId) > 0;
}
#--------------------------------------------------------------------------------------------
sub _stealLock {
  my ($obj, $cacheId) = @_;
  #hmmmmmm......
}
#--------------------------------------------------------------------------------------------
1;
__END__

{
 version => 
 cacheItem =>
}




TABLE A

 select objectId from A where name like 'test';


 

__CACHE_TABLE_VERSION 

__CACHE_TABLE_A_VERSION 


CACHE LOOKING

getSQL wait if cacheId is locked 

setSQL 
  - retrieve lock for the key, regardless of version
    - update the key
  - unlick the lock for the key

removeSQL
  - retrieve lock for the key, regardless of version
    - remove the key (sql)
  - unlick the lock for the key
