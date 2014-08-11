package O2::DB::LimitSth;

use strict;

# Statement handler class for emulating "sql limit".
# (And supplying the warm & cozy "next()" method;-)

#-------------------------------------------------------------------------------
# %init : sth - dbi statement handler, start - move forward to this row index, rowCount - only return this many rows
sub new {
  my ($pkg, %init) = @_;

  # skip first rows manually?
  if ($init{start} && $init{start} > 0) {
    $init{rowCountStart} = $init{start};
    $init{sth}->fetchrow_array() while $init{start}-- > 0;
  }
    
  return bless({
    dbh             =>  $init{dbh},
    sth             =>  $init{sth},
    rowCount        =>  $init{rowCount},
    rowCountStart   => ($init{rowCountStart}   || 0),
    useRowCount     => ($init{rowCount} && $init{rowCount} > 0),
    profilingId     =>  $init{profilingId}, # used if profiling mode is set
    sql             => ($init{sql}             || undef),
    cachedSQLResult => ($init{cachedSQLResult} || undef),
    _tmpArray       => [],          
  }, $pkg);
}
#-------------------------------------------------------------------------------
sub skip {
  my ($obj, $num) = @_;
  $num ||= 1;

  if ($#{ $obj->{cachedSQLResult} } > -1) {
    shift @{ $obj->{cachedSQLResult} } while $num-- > 0;
  }
  else {
    $obj->{sth}->fetchrow_array() while $num-- > 0;
  }
}
#-------------------------------------------------------------------------------
sub execute {
  my ($obj, @placeHolders) = @_;
  @placeHolders = $obj->_getDbUtil()->encodePlaceHolders(@placeHolders);
  my $tmpSql   = $obj->{dbh}->_expandPH($obj->{sql}, @placeHolders);
  my $cacheVal = $obj->{dbh}->getCachedSql($tmpSql, \@placeHolders);
  $obj->{executeSql} = $tmpSql;
  $obj->{_tmpArray} = [];
  if ($cacheVal) {
    $obj->{cachedSQLResult} = $cacheVal;
    return $obj;
  }
  my $pid;
  $pid = $obj->{dbh}->setupSubProfilingOfProfilingId($obj->{profilingId}, 'execute', \@placeHolders, caller) if $obj->{profilingId};

  if (  !eval { $obj->{sth}->execute(@placeHolders) }  ||  $@  ) {
    die "Error executing '$tmpSql': " . $obj->{sth}->errstr();
  }
  $obj->{hasExecutedSql} = 1;
  $obj->{dbh}->endProfiling($pid) if $pid;
  return $obj;
}
#-------------------------------------------------------------------------------
sub next {
  my ($obj) = @_;
  return $obj->_fetchrow('array');
}
#-------------------------------------------------------------------------------
sub nextArray {
  my ($obj) = @_;
  return $obj->_fetchrow('array');
}
#-------------------------------------------------------------------------------
sub nextArrayRef {
  my ($obj) = @_;
  return $obj->_fetchrow('arrayref');
}
#-------------------------------------------------------------------------------
sub nextHash {
  my ($obj) = @_;
  return $obj->_fetchrow('hash');
}
#-------------------------------------------------------------------------------
sub nextHashRef {
  my ($obj) = @_;
  return $obj->_fetchrow('hashref');
}
#-------------------------------------------------------------------------------
sub _fetchrow {
  my ($obj, $datatype) = @_;
  
  if ($obj->{dbh}->{o2DBCacheEnabled} && $obj->{sql} && $obj->{cachedSQLResult} ) {

    if ($#{ $obj->{cachedSQLResult} }  >=  0) {
      my $cacheVal;

      $cacheVal = shift @{ $obj->{cachedSQLResult} };
      if (defined $cacheVal) {
        return @{ $obj->{dbh}->_asArrayRef($obj->{sql},$cacheVal) } if $datatype eq 'array';
        return    $obj->{dbh}->_asArrayRef($obj->{sql},$cacheVal)   if $datatype eq 'arrayref';
        return   $cacheVal                                          if $datatype eq 'hashref';
        return %{$cacheVal}                                         if $datatype eq 'hash';
      }
    }
    return unless $obj->{hasExecutedSql} && $obj->{sth} && $obj->{executeSql}; #if we have an sth and we are in prepare execute mode
  }
  
  # return empty list and close statement handle when limit is reached.
  if ( $obj->{useRowCount} ) {
    $obj->{sth}->finish() if $obj->{rowCount}-- == 0;
    return if $obj->{rowCount} < 0;
  }

  # because of caching we always have to it out in hashref so we can keep the name => value structue
  my $result = $obj->{sth}->fetchrow_hashref();
  $result = $obj->_getDbUtil()->decodeResult($result);
  $obj->_cacheResult($result) if $obj->{dbh}->{o2DBCacheEnabled};

  return unless defined $result;
  return @{ $obj->{dbh}->_asArrayRef($obj->{sql},$result) } if $datatype eq 'array';
  return    $obj->{dbh}->_asArrayRef($obj->{sql},$result)   if $datatype eq 'arrayref';
  return $result                                            if $datatype eq 'hashref';
  if ($datatype eq 'hash') {
    return if ref($result) ne 'HASH';
    return %{ $result };
  }
  die "Illegal datatype: $datatype";
}
#-------------------------------------------------------------------------------
sub _cacheResult {
  my ($obj, $valToCache) = @_;
  
  if (ref $valToCache eq 'ARRAY' && $#{$valToCache} > -1) {
    my @copy = @{$valToCache};
    if ($obj->{rowCountStart} && $obj->{useRowCount}) { # <-- limitSelect is used
      push @{  $obj->{_tmpArray}->[ $obj->{rowCountStart} ]  }, \@copy;
    }
    else {
      push @{ $obj->{_tmpArray} }, \@copy;
    }
  }
  elsif (ref $valToCache eq 'HASH') {
    my %copy = %{$valToCache};
    if ($obj->{rowCountStart} && $obj->{useRowCount}) { # <-- limitSelect is used
      push @{  $obj->{_tmpArray}->[ $obj->{rowCountStart} ]  },\%copy;
    }
    else {
      push @{ $obj->{_tmpArray} }, \%copy;
    }
  }

  if (!$valToCache) {
    $obj->setResultsOnSQL( $obj->{_tmpArray} ); # incremantal set 
  }
}
#-------------------------------------------------------------------------------
sub _getDbUtil {
  my ($obj) = @_;
  return $obj->{dbh}->_getDbUtil();
}
#-------------------------------------------------------------------------------
sub finish {
  my ($obj) = @_;
  
  $obj->{sth}->finish() if defined $obj->{sth}; # If we are in "cache mode", sth is undefined
  $obj->{dbh}->endProfiling( $obj->{profilingId} ) if $obj->{profilingId};
  
  if ( !$obj->{cachedSQLResult}  &&  $obj->{sth}  &&  $obj->{dbh}->{o2DBCacheEnabled}  &&  $obj->{_tmpArray}  &&  ( $obj->{executeSql} || $obj->{sql} )  ) {
    $obj->setResultsOnSQL( $obj->{_tmpArray} );
    $obj->{_tmpArray} = undef;
  }
}
#-------------------------------------------------------------------------------
sub DESTROY {
  my ($obj) = @_;
  $obj->finish();
}
#-----------------------------------------------------------------------------------
# O2 DB caching logic
sub setResultsOnSQL {
  my ($obj, $results) = @_;
  if (defined $obj->{cachedSQLResult} && !$obj->{sth}) {
    return;
  }
  my $sqlToCacheOn = $obj->{executeSql} || $obj->{sql};
  if ($obj->{dbh}->{o2DBCacheHandler}->sqlIsCachable($sqlToCacheOn)) {
    $obj->{dbh}->{o2DBCacheHandler}->setSQL($sqlToCacheOn, $results);
  }
}
#-------------------------------------------------------------------------------
1;
