use strict;

use Test::More qw(no_plan);
use O2 qw($context);
use O2::Script::Test::Common;

use_ok 'O2::HttpSession::Files';

my $session = $context->getSingleton('O2::HttpSession', sessionName => 'frontend');

$session->set('name', 'Håkon');
$session->set('email', 'haakonsk@gmail.com');
diag "session initialized\n";

ok($session->get('name')  eq 'Håkon',              'Name is correct');
ok($session->get('email') eq 'haakonsk@gmail.com', 'Email is correct');

ok(!$session->canPopSession(), '!canPopSession');
$session->pushSession();
$session->set('name',  'Karlsen');
$session->set('email', 'haakonsk@redpill-linpro.com');

$session->pushSession();

my $values = $session->getPushedSessionValues();
ok($values->{email} = 'haakonsk@redpill-linpro.com', 'pushedSessionValues ok');

$values = $session->getOriginalSessionValues();
ok($values->{email} = 'haakonsk@gmail.com', 'originalSessionValues ok');

$session->popSession();

ok( $session->get('name')  eq 'Karlsen',                     'Name is correct'  );
ok( $session->get('email') eq 'haakonsk@redpill-linpro.com', 'Email is correct' );

ok($session->canPopSession(), 'canPopSession');
$session->popSession();
ok(!$session->canPopSession(), '!canPopSession');

ok($session->get('name')  eq 'Håkon',              'Name is correct');
ok($session->get('email') eq 'haakonsk@gmail.com', 'Email is correct');

$session->deleteSession();
