package O2::Mgr::DateTimeManager;

use strict;
use base 'O2::Mgr::ObjectManager';

use O2::Obj::DateTime;

#-----------------------------------------------------------------------------
sub initModel {
  my ($obj, $model) = @_;
  $obj->SUPER::initModel($model);
  $model->registerFields(
    'O2::Obj::DateTime',
    # Your class definition goes here:
    #-----------------------------------------------------------------------------
    year        => { type => 'int' },
    month       => { type => 'int' },
    dayOfMonth  => { type => 'int' },
    hours       => { type => 'int' },
    minutes     => { type => 'int' },
    seconds     => { type => 'int' },
    nanoSeconds => { type => 'int' },
    date        => { type => 'int' }, # This is kind of a virtual field, calculated from year, month and dayOfMonth. Nice to have when searching.
    #-----------------------------------------------------------------------------
  );
}
#-----------------------------------------------------------------------------
sub newObject {
  my ($obj, $date) = @_;
  $date = $date->dbFormat() if ref ($date) =~ m{ :: }xms && ($date->isa('O2::Obj::DateTime') || $date->isa('O2::Cgi::DateTime'));
  die 'DateTimeManager->newObject: Not sure what you mean (' . (ref $date) . ')' if ref $date;
  my $object = $obj->SUPER::newObject();
  return $object unless $date;
  if ($date =~ m{ \A \d{9,} \z }xms) {
    $object->setEpoch($date);
  }
  else {
    $object->setDateTime($date);
  }
  return $object;
}
#-----------------------------------------------------------------------------
sub save {
  my ($obj, $object) = @_;
  my $date = $object->format('yyyyMMdd');
  $object->setMetaName($date) unless $object->getMetaName();
  $object->setModelValue('date', $date);
  $obj->SUPER::save($object);
}
#-----------------------------------------------------------------------------
1;
