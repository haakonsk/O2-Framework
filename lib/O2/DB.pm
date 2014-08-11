package O2::DB;

use strict;

use constant DEBUG => 0;
use O2 qw($context);
use DBI;
use O2::DB::LimitSth;
use Time::HiRes qw(time);

#-----------------------------------------------------------------------------
sub new {
  my ($pkg, %login) = @_;
  
  foreach my $key (qw(dataSource username)) {
    die "$key missing" unless $login{$key};
  }
  
  my $obj = bless {
    dataSource       => $login{dataSource},
    username         => $login{username},
    password         => $login{password},
    host             => $login{host}        || undef,
    port             => $login{port}        || undef,
    mysqlSocket      => $login{mysqlSocket} || undef, # mysql_socket faster than tcp/ip connections
    attr             => $login{attr}        || { RaiseError => 1, AutoCommit => 1, PrintError => 0, mysql_enable_utf8 => 1 },
    dbh              => undef, # lazy initialization of DBI handle
    login            => \%login,
    transactionLevel => 0,
    o2DBCacheEnabled => 0,
    o2DBCacheHandler => $context->getMemcached(),
  }, $pkg;

  if ($context->isProfiling()) {
    $obj->disableDBCache(); # Disabling the query cache when we do profiling
    $obj->enableProfiling();
  }

  $obj->enableO2DBCache() if $context->getMemcached()->canCacheSQL();
  debug 'CALLED BY[' . join ('|', caller) . "] ->new DBH: " . join ',', %login;
  return $obj;
}
#-----------------------------------------------------------------------------
# returns DBI object (lazy init)
sub getDbh {
  my ($obj) = @_;
  return $obj->{dbh} if $obj->{dbh};

  my $pid;
  $pid = $obj->startProfiling('getDbh', 'none', caller) if $obj->{dbProfilingEnabled};
  # 20071109 nilschd following DBI recommandation: http://search.cpan.org/~timb/DBI/DBI.pm#connect
  my $hostAndPort = ($obj->{host}        ? ";host=$obj->{host}"                : '')  .  ($obj->{port} ? ";port=$obj->{port}" : '');
  my $mysqlSocket =  $obj->{mysqlSocket} ? ";mysql_socket=$obj->{mysqlSocket}" : '';

  my @login = (
    "dbi:mysql:$obj->{dataSource}$hostAndPort$mysqlSocket",
    $obj->{username},
    $obj->{password},
    $obj->{attr},
  );
  debug "DBI connect: ('$login[0]', '$login[1]', ...)";
  $obj->{dbh} = DBI->connect(@login) or $obj->_error("DBI connect: ('$login[0]', '$login[1]', ...)");
  $obj->{dbh}->{LongReadLen} = 512*1024;
  $obj->{dbh}->{LongTruncOk} = 1;
  $obj->do("SET sql_mode = 'STRICT_TRANS_TABLES';");

  $obj->endProfiling($pid) if $obj->{dbProfilingEnabled} && $pid;
  return $obj->{dbh};
}
#-----------------------------------------------------------------------------
sub normalizeSqlAndPlaceHolderValues {
  my ($obj, $sql, @placeHolders) = @_;
  my @newPlaceHolders;
  foreach my $placeHolder (@placeHolders) {
    if ('ARRAY' eq ref $placeHolder) {
      if ($sql !~ m{ \?\? }xms) {
        require Data::Dumper;
        die sprintf "Unexpected array ref among place holders in sql query ($sql), placeHolders: " . Data::Dumper::Dumper(\@placeHolders);
      }
      my $questionMarks = '?,' x scalar @{$placeHolder};
      chop $questionMarks;
      $sql =~ s{ \?\? }{$questionMarks}xms;
      push @newPlaceHolders, @{$placeHolder};
    }
    else {
      push @newPlaceHolders, $placeHolder;
    }
  }
  $sql =~ s{ \S+ \s in \s \(\) }{ 1=0 }xmsg;
  return ($sql, @newPlaceHolders);
}
#-----------------------------------------------------------------------------
# just like the selectcol_arrayref
sub selectColumn {
  my ($obj, $statement, @params) = @_;
  ($statement, @params) = $obj->normalizeSqlAndPlaceHolderValues($statement, @params);

  my $cacheVal = $obj->getCachedSql($statement, \@params);
  if ($cacheVal) {
    my $arrayRef = $obj->_rowAsArrayRef($statement, $cacheVal);
    return wantarray ? @{ $arrayRef } : $arrayRef;
  }

  my $pid;
  $pid = $obj->startProfiling( 'selectColumn', $obj->_expandPH($statement, @params), caller ) if $obj->{dbProfilingEnabled};

  debug 'selectColumn(' . $obj->_expandPH($statement, @params) . ')', 2;
  my @encodedPlaceHolders = $obj->_getDbUtil()->encodePlaceHolders(@params);

  my $arrayRef = $obj->getDbh()->selectcol_arrayref($statement, undef, @encodedPlaceHolders);
  $arrayRef    = $obj->_getDbUtil()->decodeResult($arrayRef);

  my $hashResult = $obj->_rowAsHashRef($statement, $arrayRef);

  $obj->cacheSQL( $statement, \@params, $hashResult || {} );

  $obj->endProfiling($pid) if $obj->{dbProfilingEnabled} && $pid;
  return ref $arrayRef eq 'ARRAY' ? @{ $arrayRef } : ();
}
#-----------------------------------------------------------------------------
# just like the fetchall_arrayref( {} ) but returns an array with hash-refs
sub fetchAll {
  my ($obj, $statement, @placeHolders) = @_;
  ($statement, @placeHolders) = $obj->normalizeSqlAndPlaceHolderValues($statement, @placeHolders);

  my $cacheVal = $obj->getCachedSql($statement, \@placeHolders);
  if ($cacheVal) {
    return ref $cacheVal eq 'ARRAY' ? @{ $cacheVal } : () if wantarray;
    return ref $cacheVal eq 'ARRAY' ?    $cacheVal   : [];
  }

  my $pid;
  $pid = $obj->startProfiling( 'fetchAll', $obj->_expandPH($statement, @placeHolders), caller ) if $obj->{dbProfilingEnabled};

  debug 'fetchAll(' . $obj->_expandPH($statement, @placeHolders) . ')', 2;
  my @encodedPlaceHolders = $obj->_getDbUtil()->encodePlaceHolders(@placeHolders);
  my $sth = $obj->getDbh()->prepare($statement);
  $sth->execute(@encodedPlaceHolders);
  my $arrayRef = $sth->fetchall_arrayref( {} );
  $arrayRef    = $obj->_getDbUtil()->decodeResult($arrayRef);

  $obj->endProfiling($pid) if $obj->{dbProfilingEnabled} && $pid;

  $obj->cacheSQL($statement,\@placeHolders,$arrayRef);
  return ref $arrayRef eq 'ARRAY' ? @{ $arrayRef } : () if wantarray;
  return ref $arrayRef eq 'ARRAY' ?    $arrayRef   : [];
}
#-----------------------------------------------------------------------------
sub selectHash {
  my ($obj, $sql, @placeholders) = @_;
  ($sql, @placeholders) = $obj->normalizeSqlAndPlaceHolderValues($sql, @placeholders);

  my $cacheVal = $obj->getCachedSql($sql, \@placeholders);
  if ($cacheVal) {
    if (ref $cacheVal eq 'ARRAY') { # it's always stored as an array on the cache server
      my ($fields) =  $sql =~ m{ select \s+ (.+?) \s+ from }i;
      my @sqlFields = split /\,/, $fields;
      my @keyValue; 
      foreach my $field (@sqlFields) {
        my @f = split /[\s\.]+/, $field;
        push @keyValue, $f[-1];
      }
      return map { $_->{$keyValue[0]} => $_->{$keyValue[1]} } @{$cacheVal};
    }
    return; # was an empty query
  }

  my $pid;
  $pid = $obj->startProfiling('selectHash', $obj->_expandPH($sql, @placeholders), caller) if $obj->{dbProfilingEnabled};

  debug 'selectHash(' . $obj->_expandPH($sql, @placeholders) . ')', 2;
  my $sth = $obj->sql($sql, @placeholders);
  my %returnHash;
  while (my ($key, $value) = $sth->next()) {
    $returnHash{$key} = $value;
  }
  my $returnHash = $obj->_getDbUtil()->decodeResult(\%returnHash);
  $sth->finish();

  $obj->endProfiling($pid) if $obj->{dbProfilingEnabled} && $pid;

  return %{$returnHash};
}
#-----------------------------------------------------------------------------
# returns an O2::DB object with a new database connection
sub clone {
  my ($obj) = @_;
  my %login = %{ $obj->{login} };
  debug 'clone() CALLED BY[' . join ('|', caller) . "] ->new DBH: " . join ',', %login;
  return O2::DB->new(%login);
}
#-----------------------------------------------------------------------------
sub startTransaction {
  my ($obj) = @_;
  $obj->{transactionLevel}++;
  return if $obj->{transactionLevel} > 1;
  $obj->getDbh()->begin_work();
}
#-----------------------------------------------------------------------------
sub endTransaction {
  my ($obj) = @_;
  die 'Transaction never started' unless $obj->{transactionLevel};
  $obj->{transactionLevel}--;
  return if $obj->{transactionLevel} >= 1;
  $obj->getDbh()->commit();
}
#-----------------------------------------------------------------------------
sub rollback {
  my ($obj) = @_;
  die 'rollback: Transaction never started' unless $obj->{transactionLevel};
  $obj->{transactionLevel} = 0;
  $obj->getDbh()->rollback();
}
#-----------------------------------------------------------------------------
# inserts row into a table with auto-increment primary key.
sub idInsert {
  my ($obj, $table, $idField, %fields) = @_;
  my $pid;
  $pid = $obj->startProfiling('idInsert', "$table $idField", caller) if $obj->{dbProfilingEnabled};
  
  my $wantsSomethingBack = defined wantarray; # Not void context, ie the calling code expects something back
  # LAST_INSERT_ID() should be done in the same transaction as the insert to ensure that it always returns the correct ID (I hope)
  my $transactionWasStarted = 0;
  if ($wantsSomethingBack && $obj->{transactionLevel} == 0) {
    $obj->startTransaction();
    $transactionWasStarted = 1;
  }
  
  delete $fields{$idField} if exists $fields{$idField};
  $obj->insert($table, %fields);
  
  my $rowId;
  if ($wantsSomethingBack) {
    $rowId = $obj->getLastInsertedId() or $obj->_error("Didn't find last inserted ID");
    $obj->endTransaction() if $transactionWasStarted;
  }
  
  $obj->endProfiling($pid) if $obj->{dbProfilingEnabled} && $pid;
  return $rowId;
}
#-----------------------------------------------------------------------------
# insert a row
sub insert {
  my ($obj, $table, %fields) = @_;

  my @sortedFields = sort keys %fields;
  my $sql = sprintf "insert into $table (`%s`) values (%s)", (join '`, `', @sortedFields), (join ',', map '?', @sortedFields);
  my @values = map $fields{$_}, @sortedFields;

  $obj->getCachedSql($sql, \@values); # will make sure to delete cache for the tables involved in the query

  my $pid;
  $pid = $obj->startProfiling( 'insert', $obj->_expandPH($sql, @values), caller ) if $obj->{dbProfilingEnabled};

  debug 'insert(' . $obj->_expandPH($sql, @values) . ')';
  my @encodedValues = $obj->_getDbUtil()->encodePlaceHolders(@values);
  my $numRowsAffected = eval {
    $obj->getDbh()->do($sql, undef, @encodedValues) or $obj->_error( $obj->_expandPH($sql, @values) );
  };
  $obj->_error( "Error in sql\n" . $obj->_expandPH($sql, @values) . "\nError message: $@" ) if $@;
  $obj->_error( "insert: no rows affected, sql is:\n  " . $obj->_expandPH($sql, @values)  ) if $numRowsAffected == 0;

  $obj->endProfiling($pid) if $obj->{dbProfilingEnabled} && $pid;

  return $numRowsAffected;
}
#-----------------------------------------------------------------------------
# update a row with 
sub idUpdate {
  my ($obj, $table, $idField, %fields) = @_;
  my $idValue = delete $fields{$idField};
  $obj->_error("No value given for id-field '$idField'") unless defined $idValue;
  my @keys   = keys %fields;
  my @values = map  $fields{$_}, @keys;
  my $sql = sprintf "update $table set %s where $idField = ?", (join ',', map "`$_` = ?", @keys);

  $obj->getCachedSql($sql, \@values); # will make sure to delete cache for the tables involved in the query

  my $pid;
  $pid = $obj->startProfiling('idUpdate', $sql, caller) if $obj->{dbProfilingEnabled};
  debug 'idUpdate(' . $obj->_expandPH($sql, @values, $idValue) . ')';
  my @encodedValues = $obj->_getDbUtil()->encodePlaceHolders(@values);
  my $numRowsAffected = eval {
    $obj->getDbh()->do($sql, undef, @encodedValues, $idValue);
  };
  return $obj->_error( $obj->_expandPH($sql, @values, $idValue) ) if $@;
  warn "idUpdate: no rows affected, sql is:\n  " . $obj->_expandPH($sql, @values, $idValue) if $numRowsAffected == 0;
  $obj->endProfiling($pid) if $obj->{dbProfilingEnabled} && $pid;
  return $numRowsAffected;
}
#-----------------------------------------------------------------------------
sub prepare {
  my ($obj, $sql) = @_;
  my $pid;
  $pid = $obj->startProfiling('prepare', $sql, caller) if $obj->{dbProfilingEnabled};
  
  my $sth = $obj->getDbh()->prepare($sql) || $obj->_error("prepare($sql)");
  $obj->endProfiling($pid) if $obj->{dbProfilingEnabled} && $pid;
  return O2::DB::LimitSth->new(
    sth            => $sth,
    dbh            => $obj,
    profilingId    => $pid,
    sql            => $sql,
    cacheSQLResult => {},
  ); # To be able to use next() instead of fetchrow_array() etc
}
#-----------------------------------------------------------------------------
sub sql {
  my ($obj, $sql, @placeholders) = @_;
  ($sql, @placeholders) = $obj->normalizeSqlAndPlaceHolderValues($sql, @placeholders);

  my $cacheVal = $obj->getCachedSql( $sql, \@placeholders );
  my $tmpSql   = $obj->_expandPH(    $sql,  @placeholders );

  if ($cacheVal) {
    return O2::DB::LimitSth->new(
      sth             => undef,
      dbh             => $obj,
      profilingId     => undef,
      sql             => $tmpSql,
      cachedSQLResult => $cacheVal,
    );
  }
  my $pid;
  $pid = $obj->startProfiling( 'sql', $obj->_expandPH($sql, @placeholders), caller ) if $obj->{dbProfilingEnabled};

  my @encodedPlaceHolders = $obj->_getDbUtil()->encodePlaceHolders(@placeholders);
  if ($sql =~ m{ (select[ ].*?) \s limit \s+ ([\s\d,]+) \z }xmsis ) {
    my $selectSql = $1;
    my @limit = $2 =~ m{ (\d+) }xmsgs;
    $obj->endProfiling($pid)                                                  if $obj->{dbProfilingEnabled} && $pid && @limit == 1;
    return $obj->limitSelect($selectSql, 0,         $limit[0], @placeholders) if @limit == 1;
    $obj->endProfiling($pid)                                                  if $obj->{dbProfilingEnabled} && $pid && @limit == 2;
    return $obj->limitSelect($selectSql, $limit[0], $limit[1], @placeholders) if @limit == 2;
    $obj->_error( "Illegal 'limit' expression in: " . $obj->_expandPH($sql, @placeholders) );
  }
  else {
    debug 'sql(' . $obj->_expandPH($sql, @placeholders) . ')', ($sql =~ m{ \A \s* select }xmsi ? 2 : ());
    my $sth = $obj->getDbh()->prepare($sql) or $obj->_error("prepare($sql)");
    eval {
      $sth->execute(@encodedPlaceHolders) or $obj->_error( "execute(): " . $obj->_expandPH($sql, @placeholders) );
    };
    $obj->_error( $@ . "<br><br>\n\nsql:<br>\n" . $obj->_expandPH($sql, @placeholders) ) if $@;
    return O2::DB::LimitSth->new(
      sth         => $sth,
      dbh         => $obj,
      profilingId => $pid,
      sql         => $tmpSql,
    ); # To be able to use next() instead of fetchrow_array() etc
  }
}
#-----------------------------------------------------------------------------
# $sql : the select sql
# $start : zero-based start offset
# $rowCount : how many rows to return. Ignored if 0.
# @placeholders : refers to ?-characters in the sql expression
sub limitSelect {
  my ($obj, $sql, $start, $rowCount, @placeholders) = @_;
  ($sql, @placeholders) = $obj->normalizeSqlAndPlaceHolderValues($sql, @placeholders);

  $start    = $start    > 0 ? $start    : 0;
  $rowCount = $rowCount > 0 ? $rowCount : 0;
    
  my $dbh = $obj->getDbh();
  if ($rowCount > 0) {
    $sql .= $start > 0 ? " limit $start, $rowCount" : " limit $rowCount";
    $start    = 0;
    $rowCount = 0;
  }
  else {
    debug "Using manual limit($start,$rowCount)", 2;
  }

  my $cacheVal = $obj->getCachedSql($sql, \@placeholders);
  my $tmpSql = $obj->_expandPH($sql, @placeholders);
  if ($cacheVal) {
    return O2::DB::LimitSth->new(
      sth             => undef,
      dbh             => $obj,
      profilingId     => undef,
      sql             => $tmpSql,
      start           => $start,
      rowCount        => $rowCount,
      cachedSQLResult => $cacheVal,
    );
  }

  my $pid;
  $pid = $obj->startProfiling( 'limitSelect', $obj->_expandPH($sql, @placeholders), caller ) if $obj->{dbProfilingEnabled};

  my @encodedPlaceHolders = $obj->_getDbUtil()->encodePlaceHolders(@placeholders);

  debug 'limitSelect: ' . $obj->_expandPH($sql, @placeholders), 2;
  my $sth = $dbh->prepare($sql) or $obj->_error("prepare($sql)");
  $sth->execute(@encodedPlaceHolders) or $obj->_error('execute(' . (join ',', @placeholders) . ')');

  $sth = O2::DB::LimitSth->new(
    sth      => $sth,
    start    => $start,
    rowCount => $rowCount,
    dbh      => $obj,
    sql      => $tmpSql,
  );
  
  $obj->endProfiling($pid) if $obj->{dbProfilingEnabled} && $pid;
  return $sth;
}
#-----------------------------------------------------------------------------
sub fetch {
  my ($obj, $sql, @placeholders) = @_;
  ($sql, @placeholders) = $obj->normalizeSqlAndPlaceHolderValues($sql, @placeholders);

  my $cacheVal = $obj->getCachedSql($sql,\@placeholders);
  if ($cacheVal) {
    if ( @{$cacheVal} ) {
      my $arrayRef = $obj->_asArrayRef( $sql, $cacheVal->[0] );
      return $arrayRef->[0] if @{$arrayRef} == 1; # old behaviour
      return wantarray ? @{ $arrayRef } : $arrayRef;
    }
    return; # empty result;
  }

  my $pid;
  $pid = $obj->startProfiling( 'fetch', $obj->_expandPH($sql, @placeholders), caller ) if $obj->{dbProfilingEnabled};

  my @encodedPlaceHolders;
  @encodedPlaceHolders = $obj->_getDbUtil()->encodePlaceHolders(@placeholders) if @placeholders;
  debug 'fetch(' . $obj->_expandPH($sql, @placeholders) . ')', 2;

  my $result = $obj->getDbh()->selectrow_hashref($sql, undef, @encodedPlaceHolders);
  $result    = $obj->_getDbUtil()->decodeResult($result);

  $obj->cacheSQL( $sql, \@placeholders, [$result] || [] );

  my $arrayRef = $obj->_asArrayRef($sql, $result);

  $obj->endProfiling($pid) if $obj->{dbProfilingEnabled} && $pid;

  return $arrayRef->[0] if @{$arrayRef} == 1; # old behaviour
  return wantarray ? @{$arrayRef} : $arrayRef;
}
#-----------------------------------------------------------------------------
sub fetchHashRef {
  my ($obj, $sql, @placeHolders) = @_;
  ($sql, @placeHolders) = $obj->normalizeSqlAndPlaceHolderValues($sql, @placeHolders);

  my $cacheVal = $obj->getCachedSql($sql, \@placeHolders);
  if ($cacheVal) {
    return unless @{$cacheVal};
    return wantarray ? @{ $cacheVal->[0] } : $cacheVal->[0];
  }

  my $pid;
  $pid = $obj->startProfiling( 'fetchHashRef', $obj->_expandPH($sql, @placeHolders), caller ) if $obj->{dbProfilingEnabled};
  debug 'fetchHashRef(' . $obj->_expandPH($sql, @placeHolders) . ')', 2;
  my @encodedPlaceHolders = $obj->_getDbUtil()->encodePlaceHolders(@placeHolders);
  my $result = $obj->getDbh()->selectrow_hashref($sql, undef, @encodedPlaceHolders);
  $result    = $obj->_getDbUtil()->decodeResult($result);
  $obj->cacheSQL( $sql, \@placeHolders, [$result] || [] );
  $obj->endProfiling($pid) if $obj->{dbProfilingEnabled} && $pid;
  return $result;
}
#-----------------------------------------------------------------------------
sub sqlHashRef {
  my ($obj, $sql, @placeholders) = @_;
  ($sql, @placeholders) = $obj->normalizeSqlAndPlaceHolderValues($sql, @placeholders);

  my $cacheVal = $obj->getCachedSql($sql, \@placeholders);
  if ($cacheVal) {
    return unless @{$cacheVal};
    return wantarray ? @{ $cacheVal->[0] } : $cacheVal->[0];
  }

  my $pid;
  $pid = $obj->startProfiling( 'sqlHashRef', $obj->_expandPH($sql, @placeholders), caller ) if $obj->{dbProfilingEnabled};
  debug 'sqlHashRef(' . $obj->_expandPH($sql, @placeholders) . ')', 2;
  my @encodedPlaceHolders = $obj->_getDbUtil()->encodePlaceHolders(@placeholders);
  my %hash   =   map   {  $_->[0] => $_->[1]  }   @{  $obj->getDbh()->selectall_arrayref($sql, undef, @encodedPlaceHolders)  };
  my $result = $obj->_getDbUtil()->decodeResult(\%hash);
  $obj->cacheSQL($sql, \@placeholders, [$result]);
  $obj->endProfiling($pid) if $obj->{dbProfilingEnabled} && $pid;
  return $result;
}
#-----------------------------------------------------------------------------
sub do {
  my ($obj, $sql, @placeholders) = @_;
  ($sql, @placeholders) = $obj->normalizeSqlAndPlaceHolderValues($sql, @placeholders);

  $obj->getCachedSql($sql, \@placeholders); # will make sure to delete cache for the tables involved in the query

  my $pid;
  $pid = $obj->startProfiling('do', $obj->_expandPH($sql, @placeholders), caller) if $obj->{dbProfilingEnabled};
  debug 'do(' . $obj->_expandPH($sql, @placeholders) . ')';
  my @encodedPlaceHolders = $obj->_getDbUtil()->encodePlaceHolders(@placeholders);
  my $result = $obj->getDbh()->do($sql, undef, @encodedPlaceHolders);
  $obj->endProfiling($pid) if $obj->{dbProfilingEnabled} && $pid;
  return $result;
}
#-----------------------------------------------------------------------------
sub getLastInsertedId {
  my ($obj) = @_;
  die 'getLastInsertedId must be called inside a transaction' if $obj->{transactionLevel} == 0;
  
  my $pid;
  $pid = $obj->startProfiling('getLastInsertedId', 'none', caller) if $obj->{dbProfilingEnabled};
  my ($id) = $obj->getDbh()->selectrow_array('select LAST_INSERT_ID()');
  $obj->endProfiling($pid) if $obj->{dbProfilingEnabled} && $pid;
  return $id;
}
#-----------------------------------------------------------------------------
# convert a fileglob match expression to "sql like" ("?_face*.jpg" => "_\_face%.jpg")
sub glob2like {
  my ($obj, $glob) = @_;
  # escape special
  $glob =~ s/\%/\%\%/g;
  $glob =~ s/\_/\\_/g;
  # convert
  $glob =~ s/\?/_/g;
  $glob =~ s/\*/\%/g;
  return $glob;
}
#-----------------------------------------------------------------------------
sub _asArrayRef {
  my ($obj, $sql, $hashRef) = @_;

  return [ values %{$hashRef} ] if $sql =~ m{ \A show \s+ tables .+ }xmsi; # show tables is a bit special

  my $tmpSql = lc $sql;
  my $selectIdx = index ($tmpSql, 'select ', 0          ) + length('select ');
  my $fromIdx   = index ($tmpSql, ' from ',  $selectIdx );
  die "Error in sql: $sql" if $selectIdx == -1 || $fromIdx == -1 || $fromIdx <= $selectIdx;

  my $fields = substr $sql, $selectIdx, $fromIdx-$selectIdx;

  $fields =~ s{ \A \s+    }{};
  $fields =~ s{    \s+ \z }{};
  my @sqlFields = split /,/, $fields;

  if ($sqlFields[0] ne '*') {
    my @returnArray;
    foreach my $field (@sqlFields) {
      if (exists $hashRef->{$field}) {
        push @returnArray, $hashRef->{$field};
      }
      else {
        my @f = split /[\s\.]+/, $field;
        my $f = $f[-1];

        if (exists $hashRef->{$f}) {
          push @returnArray, $hashRef->{$f};
        }
        else {
          my ($ff) = $f =~ m{ [^\(]+ \( ([^\)]+)+ \) }xms;
          if (defined $ff && exists $hashRef->{$ff}) {
            push @returnArray, $hashRef->{$ff};
          }
          else {
            $f =~ s{ \s*? \) \z }{}xms;
            push @returnArray, $hashRef->{$f};
          }
        }
      }
    }
    return \@returnArray;
  }
  return [ values %{$hashRef} ] if ref $hashRef eq 'HASH';
  return;
}
#-----------------------------------------------------------------------------
sub _rowAsHashRef {
  my ($obj, $sql, $arrayRef) = @_;

  my ($fields) = $sql =~ m{ select \s+ (.+?) \s+ from }xmsi;
  my @sqlFields = split /,/, $fields;
  my @array;
  foreach my $row ( @{$arrayRef} ) {
    if (ref $row eq 'ARRAY') {
      my @tmp = @sqlFields;
      my %tmp = map { shift @tmp => $_ } @{$row};
      push @array, \%tmp;
    }
    else {
      push @array, { $sqlFields[0] => $row };
    }
  }
  return \@array;
}
#-----------------------------------------------------------------------------
sub _rowAsArrayRef {
  my ($obj, $sql, $arrayRef) = @_;

  my ($fields) = $sql =~ m{ select \s+ (.+?) \s+ from }xmsi;
  my @sqlFields = split /,/, $fields;

  my @array;
  foreach my $row (@{$arrayRef}) {
    if (@sqlFields == 1) {
      push @array, $row->{ $sqlFields[0] };
    }
    else {
      my @t;
      push @t, $row->{$_} foreach (@sqlFields);
      push @array, \@t;
    }
  } 
  return \@array;
}
#-----------------------------------------------------------------------------
# critical error handler
sub _error {
  my ($obj, $msg) = @_;
  my $dbError = $obj->{dbh} ? $obj->{dbh}->errstr() : $DBI::errstr;
  die "DB.pm says: $msg\nDBI says: $dbError" if $dbError;
  die "DB.pm says: $msg\nDBI is silent";
}
#-----------------------------------------------------------------------------
# returns sql with placeholders expanded to real values
sub _expandPH {
  my ($obj, $sql, @placeholders) = @_;
  ($sql, @placeholders) = $obj->normalizeSqlAndPlaceHolderValues($sql, @placeholders);
  my $ph = ref $placeholders[0] ne 'ARRAY'  ?  \@placeholders  :  $placeholders[0];
  
  my $i = 0;
  my $index = index $sql, '?';
  while ($index > -1 && $i <= $#{$ph}) {
    substr $sql, $index, 1, $ph->[$i++] || '';
    $index = index $sql, '?';
  }
  return $sql;
}
#-----------------------------------------------------------------------------
sub _getDbUtil {
  my ($obj) = @_;
  return $obj->{dbUtil} if $obj->{dbUtil};
  require O2::DB::Util;
  $obj->{dbUtil} = O2::DB::Util->new(
    dbh => $obj,
  );
  return $obj->{dbUtil};
}
#-----------------------------------------------------------------------------
sub disconnect {
  my ($obj) = @_;
  $obj->{dbh}->disconnect() if $obj->{dbh};
}
#-----------------------------------------------------------------------------
# START: O2 DB caching
#-----------------------------------------------------------------------------
# enable O2 to cache sql queries
sub enableO2DBCache {
  my ($obj) = @_;
  $obj->{o2DBCacheEnabled} = 1;
}
#-----------------------------------------------------------------------------
sub disableO2DBCache {
  my ($obj) = @_;
  $obj->{o2DBCacheEnabled} = 0;
}
#-----------------------------------------------------------------------------
sub o2DBCacheEnabled {
  my ($obj) = @_;
  return $obj->{o2DBCacheEnabled} || 0; # default off
}
#-----------------------------------------------------------------------------
# returns undef if not cached and or not cacheable
sub getCachedSql {
  my ($obj, $sql, $placeholders) = @_;
  return unless $obj->{o2DBCacheEnabled};

  # if the sql is cacheable, lets try to get it from cache

  if ( $obj->{o2DBCacheHandler}->sqlIsCachable($sql) ) {
    my $sqlCacheStr = $obj->_expandPH($sql, @{$placeholders}); 
    my $cacheVal    = $obj->{o2DBCacheHandler}->getSQL($sqlCacheStr);
    debug '"' . $obj->_expandPH( $sql, @{$placeholders} ) . '" was cached, retVal:' . $cacheVal, 2 if $cacheVal;
    return $cacheVal;
  }

  #ok, this sql is doing something with the table, so we need to delete 
  #any cached values for the table(s) included in the sql statement
  $obj->{o2DBCacheHandler}->flushCacheForTablesInSQL($sql);
  return undef;
}
#-----------------------------------------------------------------------------
sub cacheSQL {
  my ($obj, $sql, $placeholders, $result, $callerRef) = @_;
  return if !$obj->{o2DBCacheEnabled} || !$obj->{o2DBCacheHandler}->sqlIsCachable($sql);
  my $sqlCacheStr = $obj->_expandPH($sql, @{$placeholders}); 
  return if !$sqlCacheStr || $sqlCacheStr eq '';
  return $obj->{o2DBCacheHandler}->setSQL($sqlCacheStr, $result, $callerRef);
}
#-----------------------------------------------------------------------------
sub removeCachedSql {
  my ($obj, $sql, @placeholders) = @_;
  return unless $obj->{o2DBCacheEnabled};
  my $sqlCacheStr = $obj->_expandPH($sql, @placeholders); 
  return $obj->{o2DBCacheHandler}->removeSQL($sqlCacheStr);
}
#-----------------------------------------------------------------------------
# END: O2 DB Caching
#-----------------------------------------------------------------------------
# allows you to disable the DB query cache
sub disableDBCache {
  my ($obj) = @_;
  $obj->do('SET SESSION query_cache_type = OFF');
  $obj->{dbCacheEnabled} = 0;
}
#-----------------------------------------------------------------------------
# allows you to enable the DB cache again
sub enableDBCache {
  my ($obj) = @_;
  $obj->do('SET SESSION query_cache_type = ON');
  $obj->{dbCacheEnabled} = 1;
}
#-----------------------------------------------------------------------------
# query wether the DB cache is enabled
sub dbCacheEnabled {
  my ($obj) = @_;
  return $obj->{dbCacheEnabled} || 1; # default always on, well this depends of the DB config of course
}
#-----------------------------------------------------------------------------
sub enableProfiling {
  my ($obj) = @_;
  $obj->{dbProfilingEnabled} = 1;
  $obj->{dbProfilingId}      = 0;
  $O2::Util::WebProfiler::O2PROFILESQLDATA = $obj->{dbProfilingProcesess} = {};
}
#-----------------------------------------------------------------------------
sub disabledProfiling {
  my ($obj) = @_;
  $obj->{dbProfilingEnabled}   = 0;
  $obj->{dbProfileId}          = 0;
  $obj->{dbProfilingProcesess} = undef;
}
#-----------------------------------------------------------------------------
# start DB profiling
sub startProfiling {
  my ($obj, $method, $sql, @callData) = @_;
  return 0 unless $obj->{dbProfilingEnabled};
  
  my $profilingId = ++$obj->{dbProfilingId};
  $obj->{dbProfilingProcesess}->{$profilingId} = {
    package   => $callData[0],
    file      => $callData[1],
    line      => $callData[2],
    method    => $method,
    sql       => $sql,
    startTime => time,
  };
  return $profilingId;
}
#-----------------------------------------------------------------------------
# End DB profiling, returns time spent
sub endProfiling {
  my ($obj, $profilingId) = @_;
  return if !$obj->{dbProfilingEnabled} || !$profilingId || $obj->{dbProfilingProcesess}->{$profilingId}->{runTime};
  
  $obj->{dbProfilingProcesess}->{$profilingId}->{endTime} = time;
  $obj->{dbProfilingProcesess}->{$profilingId}->{runTime} = $obj->{dbProfilingProcesess}->{$profilingId}->{endTime} - $obj->{dbProfilingProcesess}->{$profilingId}->{startTime};
  $O2::Util::WebProfiler::O2PROFILESQLDATA = $obj->{dbProfilingProcesess};
  return $obj->{dbProfilingProcesess}->{$profilingId}->{runTime};
}
#-----------------------------------------------------------------------------
sub setupSubProfilingOfProfilingId {
  my ($obj, $profilingId, $method, $placeHolders, @callData) = @_;
  return unless $obj->{dbProfilingProcesess}->{$profilingId};
  
  my $sql = $obj->{dbProfilingProcesess}->{$profilingId}->{sql};
  $sql    = $obj->_expandPH( $sql, @{$placeHolders} );
  my $pid = $obj->startProfiling($method, $sql, @callData);
  $obj->{dbProfilingProcesess}->{$pid}->{parentPID} = $profilingId;
  return $pid;
}
#-----------------------------------------------------------------------------
sub setProfilingData {
  my ($obj, $profilingId, $key, $value) = @_;
  return unless $obj->{dbProfilingProcesess}->{$profilingId};
  $obj->{dbProfilingProcesess}->{$profilingId}->{extraData}->{$key} = $value;
}
#-----------------------------------------------------------------------------
sub getProfilingData {
  my ($obj) = @_;
  return undef unless $obj->{dbProfilingEnabled};
  return $obj->{dbProfilingProcesess};
}
#-----------------------------------------------------------------------------
sub DESTROY {
  my ($obj) = @_;
  $obj->disconnect();
}
#-----------------------------------------------------------------------------
1;
