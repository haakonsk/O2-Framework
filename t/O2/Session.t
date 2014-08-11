use strict;

use Test::More qw(no_plan);
use O2 qw($context $cgi);

use_ok 'O2::Session::Files';

my $dateTime = $context->getSingleton('O2::Mgr::DateTimeManager')->newObject('2013-03-11');

my $sessionId = 'test2';
my $session1 = newSession($sessionId);
ok($session1->isEmpty(), 'Session is empty');
$session1->set('username', 'haakonsk');
ok(!$session1->isEmpty(), 'Session is not empty');
$session1->delete('username');
ok($session1->isEmpty(), 'isEmpty() after delete()');
$session1->set( 'username',        'haakonsk' );
$session1->set( 'dateTime-object', $dateTime  );
$session1->save();

# test session loading
my $session2 = newSession($sessionId);
ok( $session2->get('username'), 'session2 username has value');
ok( $session1->get('username') eq $session2->get('username'), 'session1 username equals session2 username');
$dateTime = $session2->get('dateTime-object');
isa_ok( $dateTime,           'O2::Obj::DateTime',      'dateTime'           );
is(     $dateTime->format('yyyy-MM-dd'), '2013-03-11', "Date is 2013-03-11" );

# delete session test
$session1 = newSession($sessionId);
$session1->deleteSession();
$session2 = newSession($sessionId);
ok( !$session2->get('username'), 'deleteSession()');
ok($session1->isEmpty(), 'isEmpty() after deleteSession()');


# getUniqueId test
ok($session1->getUniqueId() ne $session1->getUniqueId(), 'getUniqueId() is unique');


# push/pop test
$session1->set('username', 'haakonsk');
$session1->pushSession();
ok($session1->isEmpty(), 'isEmpty after pushSession()');
$session1->set('lastname', 'Karlsen');
ok($session1->get('lastname') eq 'Karlsen', 'Lastname set correctly in pushed session');
ok($session1->canPopSession(), 'Can pop session');
$session1->popSession();
ok($session1->get('username') eq 'haakonsk', 'Username restored after pop');

# regenerate id
$session1->regenerateId('test3');
$session2 = newSession('test3');
ok($session1->get('username') eq 'haakonsk', 'Username found in renamed session');

# cleanup
$session1 = newSession($sessionId);
$session1->deleteSession();


sub newSession {
  my ($sessionId) = @_;
  return $context->getSingleton('O2::Session', sessionId => $sessionId);
}
