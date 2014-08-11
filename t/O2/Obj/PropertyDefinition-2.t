use strict;

use Test::More qw(no_plan);

use_ok 'O2::Context';
use_ok 'O2::Mgr::PropertyDefinitionManager';

my $context = O2::Context->new();

my $propertyDefinitionMgr = O2::Mgr::PropertyDefinitionManager->new( context => $context );
my $definition = $propertyDefinitionMgr->newObject();
$definition->setPropertyName( 'My property definition' );
$definition->setMetaName(     'My property definition' );

$definition->setOptionsType('static');
$definition->setOptionsData('[{name=>"name", value=>"value"}]');
is_deeply([$definition->getOptions()], [{name=>"name", value=>"value"}], 'getOptions() static options type');

$definition->setOptionsType('method');
$definition->setOptionsData('O2::Obj::PropertyDefinition::StandardOptions::test');
$definition->save();

is_deeply([$definition->getOptions()], [{name=>"Test1", value=>"test1"}], 'getOptions() method options type');

ok( $propertyDefinitionMgr->getPropertyDefinitionByName( $definition->getPropertyName() ), 'getPropertyDefinitionByName()');

END {
  $definition->deletePermanently() if $definition;
}
