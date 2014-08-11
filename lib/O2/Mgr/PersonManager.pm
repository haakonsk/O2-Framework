package O2::Mgr::PersonManager;

use strict;

use base 'O2::Mgr::ObjectManager';

use O2::Obj::Person;

#-----------------------------------------------------------------------------
sub initModel {
  my ($obj, $model) = @_;
  $obj->SUPER::initModel($model);
  $model->registerFields(
    'O2::Obj::Person',
    # Your class definition goes here:
    #-----------------------------------------------------------------------------
    firstName   => { type => 'varchar'                                    },
    middleName  => { type => 'varchar'                                    },
    lastName    => { type => 'varchar'                                    },
    gender      => { type => 'varchar', validValues => ['male', 'female'] },
    birthDate   => { type => 'date'                                       },
    email       => { type => 'varchar'                                    },
    address     => { type => 'varchar'                                    },
    postalCode  => { type => 'varchar'                                    },
    postalPlace => { type => 'varchar'                                    },
    cellPhone   => { type => 'varchar'                                    },
    phone       => { type => 'varchar'                                    },
    countryCode => { type => 'char', length => 2                          },
    attributes  => { type => 'varchar', listType => 'hash'                },
    #-----------------------------------------------------------------------------
  );
  $model->registerIndexes(
    'O2::Obj::Person',
    { name => 'emailIndex', columns => [qw(email)], isUnique => 0 },
  );
}
#-----------------------------------------------------------------------------
sub save {
  my ($obj, $object) = @_;
  $object->setMetaName( $object->getFullName() ) unless $object->getMetaName();
  $obj->indexForSearch($object, 'o2Shop') if $object->getId();
  $obj->SUPER::save($object);
}
#-----------------------------------------------------------------------------
1;
