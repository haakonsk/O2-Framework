package O2::Mgr::DatePeriodManager;

use strict;

use base 'O2::Mgr::ObjectManager';

use O2::Obj::DatePeriod;

#-----------------------------------------------------------------------------
sub initModel {
  my ($obj, $model) = @_;
  $obj->SUPER::initModel($model);
  $model->registerFields(
    'O2::Obj::DatePeriod',
    # Your class definition goes here:
    #-----------------------------------------------------------------------------
    numSeconds => { type => 'int'  },
    fromDate   => { type => 'date' },
    toDate     => { type => 'date' },
    #-----------------------------------------------------------------------------
  );
}
#-----------------------------------------------------------------------------
sub newObject {
  my ($obj, %params) = @_;
  my $object = $obj->SUPER::newObject();
  return $object unless %params;
  
  if ( !exists $params{fromDate} && !exists $params{toDate}
    || !exists $params{fromDate} && !exists $params{numSeconds}
    || !exists $params{toDate}   && !exists $params{numSeconds}) {
    die "Need two of the three parameters: fromDate, toDate, numSeconds";
  }
  
  $object->setFromDate(   $params{fromDate}   ) if $params{fromDate};
  $object->setToDate(     $params{toDate}     ) if $params{toDate};
  $object->setNumSeconds( $params{numSeconds} ) if $params{numSeconds};
  
  $object->_calculateToDate()     if  $object->getFromDate() && !$object->getToDate();
  $object->_calculateFromDate()   if !$object->getFromDate() &&  $object->getToDate();
  $object->_calculateNumSeconds() if  $object->getFromDate() &&  $object->getToDate() && !$object->getNumSeconds();
  
  $object->setMetaName( $object->getFromDate()->format('yyyy-MM-dd HH:mm:ss') . ' - ' . $object->getToDate()->format('yyyy-MM-dd HH:mm:ss') );
  
  return $object;
}
#-----------------------------------------------------------------------------
1;
