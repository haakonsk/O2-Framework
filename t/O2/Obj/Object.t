use strict;
use warnings;

use Test::More qw(no_plan);
use O2 qw($context);

use_ok 'O2::Util::AccessorMapper';

my $objectMgr = $context->getSingleton('O2::Mgr::ObjectManager');
# create tempoarary methods to test all datatype and locale combinations (not listType=>scalar since it requires table creation)
my $model = $objectMgr->getModel();
my %localizedSetData;
my @locales = @{ $context->getConfig()->get('o2.locales') };
foreach my $type ( qw(varchar text int float object) ) {
  foreach my $listType ( qw(array hash) ) {
    my $name = $type.ucfirst($listType);
    $name   .= 'Ids' if $type eq 'object';
    # fake accessors
    $model->registerFields('O2::Obj::Object', $name      => {type=>$type, listType=>$listType                 });
    $model->registerFields('O2::Obj::Object', $name.'Ml' => {type=>$type, listType=>$listType, multilingual=>1});
    # create test data for two locales (non multilingual fields should have same test data for both locales)
    my $args = generateTestArgs($listType);
    foreach my $locale (@locales) {
      $localizedSetData{$locale}->{$name} = $args;
      $localizedSetData{$locale}->{$name.'Ml'} = generateTestArgs($listType);
    }
  }
}

my $object = $objectMgr->newObject();
$object->setMetaName('Test object');
# call set accessors with test data, and store object
my $accessorMapper = O2::Util::AccessorMapper->new();
foreach my $locale (@locales) {
  $object->setCurrentLocale($locale);
  $accessorMapper->setAccessors( $object, %{ $localizedSetData{$locale} } );
}
$object->save();
ok($object->getId()>0, 'save()');

my $dbObject = $objectMgr->getObjectById($object->getId());
ok( $dbObject->getId()==$object->getId(), 'getObjectById()');

# call all get accessors
foreach my $locale (@locales) {
  $dbObject->setCurrentLocale($locale);
  my %set = %{$localizedSetData{$locale}};
  my %accessors = map { ($_=>ref $set{$_}) } keys %set;
  my %get = $accessorMapper->getAccessors($dbObject, %accessors);
  # compare result with what we set
  foreach my $name (sort keys %get) {
    is_deeply($get{$name}, $set{$name}, "$locale $name()");
  }
}

my $object2 = $objectMgr->newObject();
my $object3 = $objectMgr->newObject();
$object2->setMetaName('Test object 2');
$object3->setMetaName('Test object 3');
$object2->save();
$object->setObjectHashIds( a => $object->getId(), b => $object2, c => $object3 );
$object->save();

END {
  $object->deletePermanently()  if $object;
  $object2->deletePermanently() if $object2;
  $object3->deletePermanently() if $object3;
}

sub generateTestArgs {
  my ($listType) = @_;
  return [rnd(),rnd(),rnd()]          if $listType eq 'array';
  return {rnd()=>rnd(), rnd()=>rnd()} if $listType eq 'hash';
  die "'$listType' not defined";
}
sub rnd {
  return int rand 10000;
}
