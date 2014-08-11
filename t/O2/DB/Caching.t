use strict;

use Test::More qw(no_plan);
use O2 qw($context $db);
use O2::Script::Test::Common;

use Time::HiRes qw(time);
use O2::Util::SetApacheEnv;

use O2::Data;
my $d = O2::Data->new();

$| = 1;
#$db->enableDebug();
#$db->disableDBCache();

my $doTest;
if($ARGV{-test}) {
  %{$doTest} = map { ($_-1) => $_ } split /,/, $ARGV{-test};
}

my @tests = (
  \&testIdentifySqlTables,
  \&testSQL,
  \&testSQLWithDistinct,
  \&testSQLWithNoResult,
  \&testFetch,
  \&testFetchAll,
  \&testFetchHashRef,
  \&testSqlHashRef,
  \&testPrepareAndExecute,
  \&testPrepareAndExecuteHashRef,
  \&testPrepareAndExecuteArrayRef,
  \&testPrepareAndExecuteArray,
  \&testPrepareAndExecuteHash,
  \&testSelectColumn,
  \&testSelectHash,
  \&testLimitSelect,
  \&testDoWhileLogic,
  \&testSqlUpdate,
  \&testIdInsertAndIdUpdateAndDelete,
  \&testSameSqlDifferentMethods,
  \&testEmptyFetch,
  \&testPrepareAndExecuteNoPlaceholders,
  \&testToggleCachingOnOff,
);

for (my $i = 0; $i < @tests;$i++) {
  $tests[$i]->() if !$doTest || exists $doTest->{$i};
}

#die "FIX SQLS that get cached as empty strings.e.g\n
#  select 1, value from O2_OBJ_OBJECT_PROPERTY where objectId=102 and name=availableLocales
#and
#  select c.managerClass from O2_OBJ_OBJECT o, O2_OBJ_CLASS c where o.objectId=1729 and o.className=c.className
#";
# 1. test sql
# 2. fetch
# 3. fetchAll
# 4. sqlHashRer
# 5.

#---------------------------------------------------------------------------------------------------
sub testIdentifySqlTables {
  my %sqlTests = (
    'update O2_OBJ_OBJECT set name = \'test\' where objectId = 12312321' => ['O2_OBJ_OBJECT'],
    'select * from O2_OBJ_OBJECT' => ['O2_OBJ_OBJECT'],
    'select objectId, name from O2_OBJ_OBJECT where status like ? and className like ?  order by objectId asc' => ['O2_OBJ_OBJECT'],
    'insert into O2_OBJ_OBJECT (\'test1\',\'foo\',\'bar\') values (\'foo1\',\'bar2\',\'bar3\')' => ['O2_OBJ_OBJECT'],
    'drop table  O2_OBJ_OBJECT' => ['O2_OBJ_OBJECT'],
    'DELETE FROM O2_OBJ_FOO wheRE objectID=?' => ['O2_OBJ_FOO'],
    'truncate table O2_OBJ_FOO' => ['O2_OBJ_FOO'],
    'select objectId,name,status from O2_OBJ_OBJECT order by objectId desc limit 5' => ['O2_OBJ_OBJECT'],
  );
  foreach my $test (keys %sqlTests) {
    my @tables = $db->{o2DBCacheHandler}->_getSQLTables($test);
    is_deeply(\@tables, $sqlTests{$test}, "test of _getSqlTables: $test got [" . join (",", @tables) . ']');
  }
}
#---------------------------------------------------------------------------------------------------
sub testSQL {
  
  my $sql = 'select objectId, name from O2_OBJ_OBJECT where status like ? and className like ?  order by objectId asc';
  my @ph  = ('active', 'O2CMS::Obj::WebCategory');
  
  $db->removeCachedSql($sql,@ph);
  diag "Test of sql with: ".$db->_expandPH($sql,@ph)."";

  my %res;
  my $startTime = time;
  my $sth = $db->sql($sql,@ph);
  while (my ($id, $name) = $sth->next()) {
    $res{$id}=$name;
  }
  diag "NO CACHE done - used:".sprintf('%.4f',(time-$startTime))."s";
  $startTime = time;
  my %cacheRes;
  $sth = $db->sql($sql, @ph);
  while (my ($id, $name) = $sth->next()) {
    $cacheRes{$id} = $name;
  }
  diag "CACHED done - used:".sprintf('%.4f',(time-$startTime))."s";


  $startTime = time;
  my %cacheRes2;
  $sth = $db->sql($sql, @ph);
  while (my %h = $sth->nextHash()) {
    $cacheRes2{ $h{objectId} } = $h{name}
  }
  diag "CACHED done - used:".sprintf('%.4f',(time-$startTime))."s";
  is_deeply( \%res, \%cacheRes,  'test 1 of sql' );
  is_deeply( \%res, \%cacheRes2, 'test 2 of sql' );
}
#---------------------------------------------------------------------------------------------------
sub testSQLWithDistinct {
  my $sql = 'select distinct(className), sum(objectId) from O2_OBJ_OBJECT where status like ?  group by className';
  my @ph  = ('active');
  
  $db->removeCachedSql($sql,@ph);
  diag "Test of sql with distinct with: ".$db->_expandPH($sql,@ph)."";

  my %res;
  my $startTime=time;
  my $sth = $db->sql($sql,@ph);
  while( my ($id,$name)= $sth->next()) {
    $res{$id}=$name;
  }
  diag "NO CACHE done - used:".sprintf('%.4f',(time-$startTime))."s";
  $startTime=time;
  my %cacheRes;
  $sth = $db->sql($sql,@ph);
  while( my ($id,$name)= $sth->next()) {
    $cacheRes{$id}=$name;
  }
  diag "CACHED done - used:".sprintf('%.4f',(time-$startTime))."s";


  $startTime = time;
  my %cacheRes2;
  $sth = $db->sql($sql, @ph);
  while (my %h = $sth->nextHash()) {
    $cacheRes2{ $h{className} } = $h{'sum(objectId)'};
  }
  diag "CACHED done - used:".sprintf('%.4f',(time-$startTime))."s";
  is_deeply( \%res, \%cacheRes,  'test 1 of sql' );
  is_deeply( \%res, \%cacheRes2, 'test 2 of sql' );
}
#---------------------------------------------------------------------------------------------------
sub testSQLWithNoResult {
  
  my $sql = 'select objectId, className from O2_OBJ_OBJECT where objectId = ?';
  my @ph  = (-1);
  
  $db->removeCachedSql($sql,@ph);
  diag "Test of sql with error with: ".$db->_expandPH($sql,@ph)."";

  my %res;
  my $startTime=time;
  my $sth = $db->sql($sql,@ph);
  while( my ($id,$name)= $sth->next()) {
    $res{$id}=$name;
  }
  diag "NO CACHE done - used:".sprintf('%.4f',(time-$startTime))."s";
  $startTime=time;
  my %cacheRes;
  $sth = $db->sql($sql,@ph);
  while( my ($id,$name)= $sth->next()) {
    $cacheRes{$id}=$name;
  }
  diag "CACHED done - used:".sprintf('%.4f',(time-$startTime))."s";



  $startTime=time;
  my %cacheRes2;
  $sth = $db->sql($sql,@ph);
  while( my %h= $sth->nextHash()) {
    $cacheRes2{$h{objectId}}=$h{name}
  }
  diag "CACHED done - used:".sprintf('%.4f',(time-$startTime))."s";
  is_deeply( \%res, \%cacheRes, 'test 1 of sql with no result' );
  is_deeply( \%res, \%cacheRes2, 'test 2 of sql with no result' );
}
#---------------------------------------------------------------------------------------------------
sub testFetch {
  my $sql = 'select objectId from O2_OBJ_OBJECT where className like ? limit 1';
  my @ph  = ('O2CMS::Obj::Site');

  diag "Test of fetch with: ".$db->_expandPH($sql,@ph)."";
  $db->removeCachedSql($sql,@ph);
  
  my $startTime=time;
  my $objectId = $db->fetch($sql,@ph);
  diag "NO CACHE done - used:".sprintf('%.4f',(time-$startTime))."s";

  $startTime=time;
  my $cacheObjectId = $db->fetch($sql,@ph);
  diag "CACHED done - used:".sprintf('%.4f',(time-$startTime))."s";
  is_deeply( $objectId, $cacheObjectId, 'test of fetch' );
}
#---------------------------------------------------------------------------------------------------
sub testFetchAll {
  my $sql = 'select objectId,name from O2_OBJ_OBJECT where className like ?';
  my @ph  = ('O2CMS::Obj::Site');
  diag "Test of fetchAll with: ".$db->_expandPH($sql,@ph)."";
  $db->removeCachedSql($sql,@ph);
  
  my $startTime=time;
  my @res = $db->fetchAll($sql,@ph);
  diag "NO CACHE done - used:".sprintf('%.4f',(time-$startTime))."s";
  $startTime=time;
  my @cacheRes = $db->fetchAll($sql,@ph);
  diag "CACHED done - used:".sprintf('%.4f',(time-$startTime))."s";
  
  is_deeply( \@res, \@cacheRes , 'test of fetchAll' );
}
#---------------------------------------------------------------------------------------------------
sub testFetchHashRef {
  my $sql = 'select objectId,name from O2_OBJ_OBJECT where className like ? limit 1';
  my @ph  = ('O2CMS::Obj::Site');

  diag "Test of fetchHashRef with: ".$db->_expandPH($sql,@ph)."";
  $db->removeCachedSql($sql,@ph);
  my $startTime=time;
  my $res = $db->fetchHashRef($sql,@ph);
  diag "NO CACHE done - used:".sprintf('%.4f',(time-$startTime))."s";
  $startTime=time;
  my $cacheRes = $db->fetchHashRef($sql,@ph);
  diag "CACHED done - used:".sprintf('%.4f',(time-$startTime))."s";
  
  is_deeply( $res, $cacheRes , 'test of fetchHashRef' );
}
#---------------------------------------------------------------------------------------------------
sub testSqlHashRef {
  my $sql = 'select objectId,name from O2_OBJ_OBJECT where className like ?';
  my @ph  = ('O2CMS::Obj::WebCategory');

  diag "Test of sqlHashRef with: ".$db->_expandPH($sql,@ph)."";
  $db->removeCachedSql($sql,@ph);
  my $startTime=time;
  my $res = $db->sqlHashRef($sql,@ph);
  diag "NO CACHE done - used:".sprintf('%.4f',(time-$startTime))."s";
  $startTime=time;
  my $cacheRes = $db->sqlHashRef($sql,@ph);
  diag "CACHED done - used:".sprintf('%.4f',(time-$startTime))."s";
  
  is_deeply( $res, $cacheRes , 'test of sqlHashRef' );
}
#---------------------------------------------------------------------------------------------------
sub testPrepareAndExecute {
 my $sql = 'select count(objectId) from O2_OBJ_OBJECT where className like ? and status not in(?,?)';
 my @execs = ('O2CMS::Obj::WebCategory', 'O2CMS::Obj::Article');



  diag "Test of PrepareAndExecute with: $sql";
  my $startTime=time;
  my $sth = $db->prepare($sql);
  my (@res,@cachedRes);
  foreach my $class (@execs) {
    my @placeHolders = ($class,'deleted','trashed');
    $db->removeCachedSql($sql,@placeHolders);
    diag "Test of execute and single nextArray with: (".join(",",@placeHolders).")";
    $sth->execute(@placeHolders);
    push @res, $sth->nextArray();
  }
  $sth->finish();
  diag "NO CACHE done - used:".sprintf('%.4f',(time-$startTime))."s";
  my $startTime=time;
  $sth = $db->prepare($sql);
  foreach my $class (@execs) {
    my @placeHolders = ($class,'deleted','trashed');
    diag "Test of execute and single nextArray with: (".join(",",@placeHolders).")";
    $sth->execute(@placeHolders);
    push @cachedRes, $sth->nextArray();
  }
  $sth->finish();
  diag "CACHED done - used:".sprintf('%.4f',(time-$startTime))."s";
  is_deeply( \@res, \@cachedRes , 'test of prepare, execute and nextArray' );
}
#---------------------------------------------------------------------------------------------------
sub testPrepareAndExecuteHashRef {
  my $sql = 'select objectId,name,status from O2_OBJ_OBJECT where className like ? and status not in(?,?) limit 5';
  my @execs  = ('O2CMS::Obj::WebCategory', 'O2CMS::Obj::Frontpage');

  
  diag "Test of PrepareAndExecuteHashRef with: $sql";
  my $startTime=time;
  my $sth = $db->prepare($sql);
  my (@res,@cachedRes);
  foreach my $class (@execs) {
    my @placeHolders = ($class,'deleted','trashed');
    $db->removeCachedSql($sql,@placeHolders);
    diag "Test of execute and nextHashRef with: (".join(",",@placeHolders).")";
    $sth->execute(@placeHolders);
    while( my $data = $sth->nextHashRef ) {
      push @res, $data;
    }
  }
  $sth->finish();
  diag "NO CACHE done - used:".sprintf('%.4f',(time-$startTime))."s";

  $startTime=time;
  $sth = $db->prepare($sql);
  foreach my $class (@execs) {
    my @placeHolders = ($class,'deleted','trashed');
    diag "Test of execute and nextHashRef with: (".join(",",@placeHolders).")";
    $sth->execute(@placeHolders);
    while( my $data = $sth->nextHashRef ) {
      push @cachedRes, $data;
    }
  }
  $sth->finish();
  diag "CACHED done - used:".sprintf('%.4f',(time-$startTime))."s";

  is_deeply( \@res, \@cachedRes , 'test of prepare, execute and nextHashRef' );
}
#---------------------------------------------------------------------------------------------------
sub testPrepareAndExecuteArrayRef {
  my $sql = 'select objectId,name,status from O2_OBJ_OBJECT where className like ? and status not in(?,?) limit 3';
  my @execs  = ('O2CMS::Obj::Article', 'O2CMS::Obj::Frontpage');


  diag "Test of PrepareAndExecuteArrayRef with: $sql";
  my $startTime=time;
  my $sth = $db->prepare($sql);
  my (@res,@cachedRes);
  foreach my $class (@execs) {
    my @placeHolders = ($class,'deleted','trashed');
    $db->removeCachedSql($sql,@placeHolders);
    diag "Test of execute and nextArrayRef with: (".join(",",@placeHolders).")";
    $sth->execute(@placeHolders);
    while( my $data = $sth->nextArrayRef ) {
      my @copy = @{$data};
      push @res, \@copy;
    }
  }
  $sth->finish();
  diag "NO CACHE done - used:".sprintf('%.4f',(time-$startTime))."s";
  my $startTime=time;
  $sth = $db->prepare($sql);
  foreach my $class (@execs) {
    my @placeHolders = ($class,'deleted','trashed');
    diag "Test of execute and nextArrayRef with: (".join(",",@placeHolders).")";
    $sth->execute(@placeHolders);
    while( my $data = $sth->nextArrayRef ) {
      my @copy = @{$data};
      push @cachedRes, \@copy;
    }
  }
  $sth->finish();
  diag "CACHED done - used:".sprintf('%.4f',(time-$startTime))."s";
  is_deeply( \@res, \@cachedRes , 'test of prepare, execute and nextArrayRef' );

}
#---------------------------------------------------------------------------------------------------
sub testPrepareAndExecuteArray {
  my $sql = 'select objectId,name,status from O2_OBJ_OBJECT where className like ? and status not in(?,?)  limit 3';
  my @execs  = ('O2CMS::Obj::Article', 'O2CMS::Obj::Frontpage');


  diag "Test of PrepareAndExecuteArray with: $sql";
  my $startTime=time;
  my $sth = $db->prepare($sql);
  my (@res,@cachedRes);
  foreach my $class (@execs) {
    my @placeHolders = ($class,'deleted','trashed');
    $db->removeCachedSql($sql,@placeHolders);
    diag "Test of execute and nextArray with: (".join(",",@placeHolders).")";
    $sth->execute(@placeHolders);
    while( my @data = $sth->nextArray ) {
      push @res, \@data;
    }
  }
  $sth->finish();
  diag "NO CACHE done - used:".sprintf('%.4f',(time-$startTime))."s";
  $startTime=time;
  $sth = $db->prepare($sql);
  foreach my $class (@execs) {
    my @placeHolders = ($class,'deleted','trashed');
    diag "Test of execute and nextArray with: (".join(",",@placeHolders).")";
    $sth->execute(@placeHolders);
    while( my @data = $sth->nextArray ) {
      push @cachedRes, \@data;
    }
  }
  $sth->finish();
  diag "CACHED done - used:".sprintf('%.4f',(time-$startTime))."s";
  is_deeply( \@res, \@cachedRes , 'test of prepare, execute and nextArray' );
}
#---------------------------------------------------------------------------------------------------
sub testPrepareAndExecuteHash {
  my $sql = 'select objectId,name,status from O2_OBJ_OBJECT where className like ? and status not in(?,?)';
  my @execs  = ('O2::Obj::File', 'O2::Obj::Image');


  diag "Test of PrepareAndExecuteHash with: $sql";
  my $startTime=time;
  my $sth = $db->prepare($sql);
  my (@res,@cachedRes);
  foreach my $class (@execs) {
    my @placeHolders = ($class,'deleted','trashed');
    $db->removeCachedSql($sql,@placeHolders);
    diag "Test of execute and nextHash with: (".join(",",@placeHolders).")";
    $sth->execute(@placeHolders);
    while( my %data = $sth->nextHash ) {
      push @res, \%data;
    }
  }
  $sth->finish();
  diag "NO CACHE done - used:".sprintf('%.4f',(time-$startTime))."s";
  $startTime=time;
  $sth = $db->prepare($sql);
  foreach my $class (@execs) {
    my @placeHolders = ($class,'deleted','trashed');
    diag "Test of execute and nextHash with: (".join(",",@placeHolders).")";
    $sth->execute(@placeHolders);
    while( my %data = $sth->nextHash ) {
      push @cachedRes, \%data;
    }
  }
  $sth->finish();
  diag "CACHED done - used:".sprintf('%.4f',(time-$startTime))."s";
  is_deeply( \@res, \@cachedRes , 'test of prepare, execute and nextHash' );
}
#---------------------------------------------------------------------------------------------------
sub testSelectColumn {
  my $sql = 'select objectId from O2_OBJ_OBJECT where parentId = (select min(parentId) from O2_OBJ_OBJECT)';
  
  diag "Test of SelectColumn with: $sql";
  $db->removeCachedSql($sql);
  my $startTime=time;
  my @res = $db->selectColumn($sql);
  diag "NO CACHE done - used:".sprintf('%.4f',(time-$startTime))."s";

  $startTime=time;
  my @cachedRes = $db->selectColumn($sql);
  diag "CACHED done - used:".sprintf('%.4f',(time-$startTime))."s";
  is_deeply( \@res, \@cachedRes , 'test of selectColumn' );
}
#---------------------------------------------------------------------------------------------------
sub testSelectHash {
  my $sql = 'select objectId,name from O2_OBJ_OBJECT where parentId = (select min(parentId) from O2_OBJ_OBJECT)';
  
  diag "Test of SelectHash with: $sql";
  $db->removeCachedSql($sql);

  my $startTime=time;
  my %res = $db->selectHash($sql);
  diag "NO CACHE done - used:".sprintf('%.4f',(time-$startTime))."s";
  $startTime=time;
  my %cachedRes = $db->selectHash($sql);
  diag "CACHED done - used:".sprintf('%.4f',(time-$startTime))."s";
  is_deeply( \%res, \%cachedRes , 'test of selectHash' );
}
#---------------------------------------------------------------------------------------------------
sub testLimitSelect {
  my $sql = 'select objectId,name,className, status from O2_OBJ_OBJECT where status not in (?,?)';
  my @placeHolders = ('deleted','trashed');
  diag "Test of limitSelect with: $sql";

  $db->removeCachedSql($sql.' limit 2, 5',@placeHolders); # Because we are testing against mysql and DB is transforming the SQL to mysql format

  my (@res,@cachedRes);
  my $startTime=time;
  my $sth = $db->limitSelect($sql, 2, 5, @placeHolders);
  while (my @data = $sth->next()) {
    push @res,\@data;
  }
  $sth->finish();
  diag "NO CACHE done - used:".sprintf('%.4f',(time-$startTime))."s";
  $startTime=time;
  $sth = $db->limitSelect($sql, 2, 5, @placeHolders);
  while (my @data = $sth->next()) {
    push @cachedRes,\@data;
  }
  $sth->finish();
  diag "CACHE done - used:".sprintf('%.4f',(time-$startTime))."s";
  is_deeply( \@res, \@cachedRes , 'test of limitSelect' );

}
#---------------------------------------------------------------------------------------------------
sub testDoWhileLogic {
  my $testMethod = sub  {
    my ($path) = @_;
    my (@path) = $path =~ m|\/+([^\/]+)|g;
    my $objectId = undef;
    my $sth = $db->prepare("select objectId from O2_OBJ_OBJECT where name=? and (parentId=? or (? is null and parentId is null)) and status not in ('trashed', 'deleted')");
    do {
      my $name = shift @path;
      $sth->execute($name, $objectId, $objectId);
      ($objectId) = $sth->nextArray();
      $sth->finish();
      
      return unless $objectId;
    } while (@path);
    return $objectId;
  };
    

  my $startTime=time;
  my $res = &$testMethod('/Templates/pages/applicationPages/memberPage.html');
  diag "NO CACHE done - used:".sprintf('%.4f',(time-$startTime))."s";
  $startTime=time;
  my $cachedRes = &$testMethod('/Templates/pages/applicationPages/memberPage.html');
  diag "CACHE done - used:".sprintf('%.4f',(time-$startTime))."s";

  $startTime=time;
  my $cachedRes2 = &$testMethod('/Templates/pages/applicationPages/memberPage.html');
  diag "CACHE2 done - used:".sprintf('%.4f',(time-$startTime))."s";


  is_deeply( \$res, \$cachedRes , 'test of testDoWhileLogic' );
  is_deeply( \$res, \$cachedRes2 , 'test of testDoWhileLogic' );
}
#---------------------------------------------------------------------------------------------------
sub testSqlUpdate {
  my $fetchSql = 'select objectId, name, status from O2_OBJ_OBJECT where className like ? and status not in(?,?) limit 1';
  my @fetchPH = ('O2CMS::Obj::Site','deleted','trashed');

  $db->removeCachedSql($fetchSql,@fetchPH);
  my $startTime=time;
  my $fetchHashNotCached = $db->fetchHashRef($fetchSql,@fetchPH);
  diag "NO CACHE done - used:".sprintf('%.4f',(time-$startTime))."s";

  $startTime=time;
  my $fetchHashCached = $db->fetchHashRef($fetchSql,@fetchPH);
  diag "CACHE done - used:".sprintf('%.4f',(time-$startTime))."s";

  is_deeply( $fetchHashNotCached, $fetchHashCached , 'test 1 of testSqlUpdate' );


  my $updateSql ='update O2_OBJ_OBJECT set name = ? where objectId = ?';
  my $testName = 'testSqlUpdate test'; #.$fetchHashCached->{name};
  my @updatePH = ($testName,$fetchHashCached->{objectId});
  
  my $sth = $db->sql($updateSql,@updatePH);
  $sth->finish();
  
  $startTime=time;
  my $fetchHashNotCached2 = $db->fetchHashRef($fetchSql, @fetchPH);
  diag "NO CACHE done - used:".sprintf('%.4f',(time-$startTime))."s";
  is( $fetchHashNotCached2->{name}, $testName , 'test 2 of testSqlUpdate' );

  $startTime=time;
  my $fetchHashCached2 = $db->fetchHashRef($fetchSql,@fetchPH);
  diag "NO CACHE done - used:".sprintf('%.4f',(time-$startTime))."s";
  is( $fetchHashCached2->{name}, $testName , 'test 3 of testSqlUpdate' );
  
  # restore original name again
  my $result = $db->do($updateSql, ($fetchHashCached->{name},$fetchHashCached->{objectId}));
  ok( $result, 'test 4 (do)  of testSqlUpdate' );

  
  $startTime=time;
  my $fetchHashNotCached3 = $db->fetchHashRef($fetchSql,@fetchPH);
  diag "NO CACHE done - used:".sprintf('%.4f',(time-$startTime))."s";

  is_deeply( $fetchHashNotCached3, $fetchHashNotCached , 'test 5 of testSqlUpdate' );
}
#---------------------------------------------------------------------------------------------------
sub testIdInsertAndIdUpdateAndDelete {

  my $maxSql = "select max(objectId) from O2_OBJ_OBJECT";
  $db->removeCachedSql($maxSql);
  my $startTime=time;
  my $maxId = $db->fetch($maxSql);
  diag "NO CACHE done - used:".sprintf('%.4f',(time-$startTime))."s";


  $startTime=time;
  my $maxIdCached = $db->fetch($maxSql);
  diag "CACHE done - used:".sprintf('%.4f',(time-$startTime))."s";
  is_deeply( $maxIdCached,$maxId , 'test 1 of testIdInsertAndDelete' );


  my $newInsertedId = $db->idInsert(
    'O2_OBJ_OBJECT', 'objectId',
    name       => 'o2TestDBCaching.pl',
    className  => 'O2::FOO::BAR',
    createTime => time,
    changeTime => time,
    status     => 'notSoNew',
  );
  my $startTime=time;
  my $maxId2 = $db->fetch($maxSql);
  # maxId2 is now the same as the new id
  is($maxId2,$newInsertedId,'test 2 of testIdInsertAndDelete');



  # let update the new ID and change name to "o2TestDbCaching2.pl"
  my $newName='o2TestDbCaching2.pl';
  my $affectedRows = $db->idUpdate('O2_OBJ_OBJECT','objectId',( name => $newName, objectId => $newInsertedId ));
  is($affectedRows,1,'test 3  of testIdInsertAndDelete');

  my $newNameFromDB = $db->fetch('select name from O2_OBJ_OBJECT where objectId = ?',($newInsertedId));
  is($newName, $newNameFromDB, 'test 4  of testIdInsertAndDelete');

  #lets testDelete id now
  $affectedRows = $db->do('delete from O2_OBJ_OBJECT where objectId=?',($newInsertedId));
  is($affectedRows,1,'test 5 of testIdInsertAndDelete');
  

  my $startTime=time;
  my $maxIdNow = $db->fetch($maxSql);
  diag "NO CACHE done - used:".sprintf('%.4f',(time-$startTime))."s";
  is($maxIdNow,$maxId,'test 6 of testIdInsertAndDelete (this test can fail if there has been other DB update while this script runs)');
  

  
}
#---------------------------------------------------------------------------------------------------s
sub testSameSqlDifferentMethods {
  my $sql = 'select objectId,name,status from O2_OBJ_OBJECT order by objectId desc limit 5';
  $db->removeCachedSql($sql);

  my (@testSql, @testSql2, @testPrepare,@testFetchAll);  
  my $startTime=time;
  my $sth = $db->sql($sql);
  while(my @data = $sth->next()) {
    push @testSql, \@data;
  }
  $sth->finish();
  diag "NO CACHE done - used:".sprintf('%.4f',(time-$startTime))."s";

  my $startTime=time;
  my $sth = $db->sql($sql);
  while(my @data = $sth->next()) {
    push @testSql2, \@data;
  }
  $sth->finish();
  diag "CACHE done - used:".sprintf('%.4f',(time-$startTime))."s";
  
#is_deeply( $maxIdCached,$maxId , 'test 1 of testSameSqlDifferentMethods' );
  $startTime=time;
  $sth = $db->prepare($sql);
  $sth->execute();
  while(my @data = $sth->next()) {
    push @testPrepare, \@data;
  }
  diag "CACHE done - used:".sprintf('%.4f',(time-$startTime))."s";

#  $db->removeCachedSql($sql);

  $startTime=time;
  @testFetchAll = $db->fetchAll($sql);
  # converting the array to the other formats so we can compare with is_deeplay
  my @tmp; push @tmp, [$_->{objectId},$_->{name},$_->{status}] foreach (@testFetchAll);  @testFetchAll=@tmp;
  diag "CACHE done - used:".sprintf('%.4f',(time-$startTime))."s";
  
  is_deeply( \@testSql,\@testSql2 , 'test 1 of testSameSqlDifferentMethods' );
  is_deeply( \@testSql,\@testPrepare , 'test 2 of testSameSqlDifferentMethods' );
  is_deeply( \@testSql,\@testFetchAll ,'test 3 of testSameSqlDifferentMethods' );

}
#---------------------------------------------------------------------------------------------------
sub testEmptyFetch {
  my $sql="select 1, value from O2_OBJ_OBJECT_PROPERTY where objectId=115288 and name='availableLocales'";
  $db->removeCachedSql($sql);
  
  my $startTime=time;
  my @res = $db->fetch($sql);
  diag "NO CACHE done - used:".sprintf('%.4f',(time-$startTime))."s";

  $startTime=time;
  my @resCached = $db->fetch($sql);
  diag "CACHE done - used:".sprintf('%.4f',(time-$startTime))."s";

  is_deeply( \@resCached,\@res , 'test 1 of testEmptyFetch' );
}
#---------------------------------------------------------------------------------------------------
sub testPrepareAndExecuteNoPlaceholders {
 my $sql = "show tables like 'O2_OBJ%'";
 
 diag "Test of PrepareAndExecuteNoPlaceholders with: $sql";
 $db->removeCachedSql($sql);
 my $startTime=time;
 my $sth = $db->prepare($sql);
 my (@res,@cachedRes);
 diag "Test of execute and nextArray";
 $sth->execute();
 while (my ($table)= $sth->nextArray()) {
   push @res, $table;
 }
 $sth->finish();
 diag "NO CACHE done - used:".sprintf('%.4f',(time-$startTime))."s";
 
 my $startTime=time;
 $sth = $db->prepare($sql);
 diag "Test of execute and nextArray";
 $sth->execute();
 while (my ($table)= $sth->nextArray()) {
   push @cachedRes, $table;
 }
 $sth->finish();
 diag "CACHED done - used:".sprintf('%.4f',(time-$startTime))."s";
 is_deeply( \@res, \@cachedRes , 'test of prepare, execute and nextArray' );
}
#---------------------------------------------------------------------------------------------------
sub testToggleCachingOnOff {
  my $cache = $context->getMemcached();
  diag "Enabling cache";
  $context->enableCache();
  is( $cache->canCache(),       1, 'Caching is on'    );
  is( $cache->canCacheObject(), 1, 'Can cache object' );
  is( $cache->canCacheSQL(),    1, 'Can cache SQL'    );
  diag "Disabling object cache";
  $context->disableObjectCache();
  is( $cache->canCache(),       1, 'Caching is on'        );
  is( $cache->canCacheObject(), 0, 'Can not cache object' );
  is( $cache->canCacheSQL(),    1, 'Can cache SQL'        );
  diag "Disabling SQL cache";
  $context->disableDbCache();
  is( $cache->canCache(),       1, 'Caching is on'        );
  is( $cache->canCacheObject(), 0, 'Can not cache object' );
  is( $cache->canCacheSQL(),    0, 'Can not cache SQL'    );
  diag "Disabling cache";
  $context->disableCache();
  is( $cache->canCache(),       0, 'Caching is off'       );
  is( $cache->canCacheObject(), 0, 'Can not cache object' );
  is( $cache->canCacheSQL(),    0, 'Can not cache SQL'    );
  diag "Enabling object cache";
  $context->enableObjectCache();
  is( $cache->canCache(),       1, 'Caching is on'     );
  is( $cache->canCacheObject(), 1, 'Can cache object'  );
  is( $cache->canCacheSQL(),    0, 'Can not cache SQL' );
  diag "Disabling object cache and enabling SQL cache";
  $context->disableObjectCache();
  $context->enableDbCache();
  is( $cache->canCache(),       1, 'Caching is on'        );
  is( $cache->canCacheObject(), 0, 'Can not cache object' );
  is( $cache->canCacheSQL(),    1, 'Can cache SQL'        );
  diag "Enabling object cache";
  $context->enableObjectCache();
  is( $cache->canCache(),       1, 'Caching is on'    );
  is( $cache->canCacheObject(), 1, 'Can cache object' );
  is( $cache->canCacheSQL(),    1, 'Can cache SQL'    );
}
#---------------------------------------------------------------------------------------------------
