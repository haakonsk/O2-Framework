use strict;
use warnings;

use Test::More tests => 4;
use O2 qw($context);

my $classMgr = $context->getSingleton('O2::Mgr::ClassManager');

my $className = 'O2::Obj::ClassTest';

my $class = $classMgr->newObject();
$class->setClassName(    $className     );
$class->setEditTemplate( 'editTemplate' );
$class->setEditUrl(      'editUrl'      );
$class->save();

my $class2 = $classMgr->getObjectByClassName($className);
is( $class2->getClassName(),    $class->getClassName(),    'className ok'    );
is( $class2->getEditTemplate(), $class->getEditTemplate(), 'editTemplate ok' );
is( $class2->getEditUrl(),      $class->getEditUrl(),      'editUrl ok'      );
is( $class2->getManagerClass(), $class->getManagerClass(), 'managerClass ok' );

END {
  $class->deletePermanently() if $class;
}
