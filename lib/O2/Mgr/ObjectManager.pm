package O2::Mgr::ObjectManager;

use strict;
use O2::Obj::Object;

use O2 qw($context $db);
use O2::Util::List qw(upush contains);
use Time::HiRes    qw(gettimeofday);

our %CACHED_OBJECTS;
#-----------------------------------------------------------------------------
sub new {
  my ($pkg, %init) = @_;

  # Setup of caching logic, minimize number of method calls
  my $cacheHandler = $context->getMemcached();
  
  return bless {
    cacheHandler                 => $cacheHandler,
    originalListFieldTableValues => {},
    %init
  }, $pkg;
}
#-----------------------------------------------------------------------------
sub newObject {
  my ($obj) = @_;
  my $modelClassName = $obj->getModelClassName();
  my $object = bless {}, $modelClassName;
  $obj->_setupRuntimeMethods($object);
  $object = $modelClassName->new(manager => $obj);
  return $object;
}
#-----------------------------------------------------------------------------
sub search {
  my ($obj, %params) = @_;
  my $query = $obj->searchParamsToQueryObject(%params);
  require O2::Obj::Object::Query::Result;
  return O2::Obj::Object::Query::Result->new($obj, $query);
}
#-----------------------------------------------------------------------------
sub objectIdSearch {
  my ($obj, %params) = @_;
  my $query = $obj->searchParamsToQueryObject(%params);
  return $query->getObjectIds();
}
#-----------------------------------------------------------------------------
sub objectSearch {
  my ($obj, %params) = @_;
  my $query = $obj->searchParamsToQueryObject(%params);
  return $query->getObjects();
}
#-----------------------------------------------------------------------------
sub searchParamsToQueryObject {
  my ($obj, %params) = @_;
  return $obj->{mostRecentlyUsedQueryObject} = $context->getSingleton('O2::Mgr::Object::QueryManager')->newObjectBySearchParams($obj, %params);
}
#-----------------------------------------------------------------------------
sub getTotalNumSearchResults {
  my ($obj) = @_;
  my $query = $obj->{mostRecentlyUsedQueryObject} or die 'No search performed';
  return $query->getTotalNumSearchResults();
}
#-----------------------------------------------------------------------------
sub getModelClassName {
  my ($obj) = @_;
  my $className = ref $obj;
  if ( $className !~ s|::Mgr::(.*)Manager$|::Obj::$1| ) {
    die "Illegal manager class name: " . ref $obj;
  }
  return $className;
}
#-----------------------------------------------------------------------------
sub getContext {
  return $context;
}
#-----------------------------------------------------------------------------
sub getDbh {
  return $db;
}
#-----------------------------------------------------------------------------
sub _cacheForCurrentRequest {
  my ($obj, $object) = @_;
  return if !$object || $object->isDeleted();
  $CACHED_OBJECTS{ $object->getId() } = $object;
}
#-----------------------------------------------------------------------------
sub _uncacheForCurrentRequest {
  my ($obj, $objectId) = @_;
  $CACHED_OBJECTS{$objectId} = undef;
}
#-----------------------------------------------------------------------------
sub getObjectById {
  my ($obj, $objectId) = @_;
  return $CACHED_OBJECTS{$objectId} if $CACHED_OBJECTS{$objectId};
  
  my $object = $obj->_getObjectById($objectId);
  $object->setHasUnsavedChanges(0) if $object;
  $obj->_cacheForCurrentRequest($object);
  return $object;
}
#-----------------------------------------------------------------------------
sub _getObjectById {
  my ($obj, $objectId) = @_;

  if ( $obj->{cacheHandler}->canCacheObject() && $objectId ) {
    my $object = $obj->{cacheHandler}->getObjectById($objectId);
    return $object if ref $object && $object->getId();
  }

  my $tmpObject = $obj->newObject();
  $tmpObject->setId($objectId);
  my $object = $obj->init($tmpObject);

  if ( $obj->{cacheHandler}->canCacheObject() ) {
    if ($objectId && $object->can('isCachable') && $object->isCachable() && !$object->isDeleted()) {
      $obj->{cacheHandler}->setObject($object); # add to cache
    }
    elsif ($objectId) {
      $obj->{cacheHandler}->deleteObjectById($objectId) if !$object->can('isCachable') || !$object->isCachable();
    }
  }

  return undef if $object->isDeleted();
  return $object;
}
#-----------------------------------------------------------------------------
sub getObjectsByIds {
  my ($obj, @objectIds) = @_;
  my @objects = grep  { defined $_ }  map  { $obj->getObjectById($_) }  @objectIds;
  return wantarray ? @objects : \@objects;
}
#-----------------------------------------------------------------------------
sub getTrashedObjectById {
  my ($obj, $objectId) = @_;
  my $object = $obj->newObject();
  $object->setId($objectId);
  return $obj->init($object);
}
#-----------------------------------------------------------------------------
sub setPropertyValue {
  my ($obj, $objectId, $name, $value) = @_;
  my $propertyMgr = $context->getSingleton('O2::Mgr::PropertyManager');
  $propertyMgr->setPropertyValue($objectId, $name, $value);
}
#-----------------------------------------------------------------------------
sub getPropertyValue {
  my ($obj, $objectOrObjectId, $name) = @_;
  return $context->getSingleton('O2::Mgr::PropertyManager')->getPropertyValue($objectOrObjectId, $name);
}
#-----------------------------------------------------------------------------
sub deletePropertyValue {
  my ($obj, $objectId, $name) = @_;
  return $context->getSingleton('O2::Mgr::PropertyManager')->deletePropertyValue($objectId, $name);
}
#-----------------------------------------------------------------------------
sub init {
  my ($obj, $object) = @_;

  die 'Missing object argument'                          unless ref $object;
  die 'Missing objectId in ' . (ref $object) . ' object' unless $object->getId() > 0;

  # load meta fields from O2_OBJ_OBJECT
  my $objectId = $object->getId();
  my $meta = $db->fetchHashRef('select * from O2_OBJ_OBJECT where objectId = ?', $objectId);
  die 'ObjectId ' . $object->getId() . ' not found in O2_OBJ_OBJECT' unless $meta->{objectId} > 0;
  
  $object->setId(             $meta->{objectId}   );
  $object->setMetaClassName(  $meta->{className}  );
  $object->setMetaName(       $meta->{name}       );
  $object->setMetaChangeTime( $meta->{changeTime} );
  $object->setMetaCreateTime( $meta->{createTime} );
  $object->setMetaParentId(   $meta->{parentId}   );
  $object->setMetaStatus(     $meta->{status}, 1  );
  $object->setMetaOwnerId(    $meta->{ownerId}    );

  # load each "class table" (typically O2_OBJ_*)
  my $model = $obj->getModel();
  foreach my $className ( $model->getClassNames() ) {
    if ($model->getTableFieldsByClassName($className) ) {
      my $tableName = $obj->_classNameToTableName($className);
      my $row = $db->fetchHashRef("select * from $tableName where objectId=?", $object->getId());
      delete $row->{objectId}; # don't need to set objectId for each table
      foreach my $column (keys %{$row}) {
        my $method = 'set' . ucfirst $column;
        eval {
          $object->$method( $row->{$column} );
        };
        die "ObjectManager->init: (Id: $meta->{objectId}) Could not call $method($row->{$column}) in " . ref ($object) . ": $@" if $@;
      }
    }
  }
  $obj->_initListFields($object, $model);
  return $object;
}
#-----------------------------------------------------------------------------
# load list types (multilingual, array and hash) from O2_OBJ_OBJECT_<dataType> tables
sub _initListFields {
  my ($obj, $object, $model) = @_;

  my $originalCurrentLocale = $object->getCurrentLocale();
  # create a mapping between fieldname and datatype (datatype being listtype + multilingual or not)
  my (%tables, %fieldListtype);
  foreach my $field ($model->getListFields()) {
    my $tableName = $field->getListTableName();
    $tables{$tableName} = 1;
    $fieldListtype{ $field->getName() } = $field->getListType() . ($field->getMultilingual() ? 'Multilingual' : '');
  }
  foreach my $table (keys %tables) {
    my %calls;
    # accumulate call arguments
    my $sth = $db->sql("select name,value from $table where objectId=?", $object->getId());
    while ( my ($name, $value) = $sth->next() ) {
      my ($fieldName, @path) = split /\./, $name;
#      print "Got $fieldListtype{$fieldName} field ($fieldName, @path) $value\n";
      if ($fieldListtype{$fieldName} eq 'array') {
        $calls{$fieldName}->[ join '.', @path ] = $value;
      }
      elsif ($fieldListtype{$fieldName} eq 'hash' || $fieldListtype{$fieldName} eq 'noneMultilingual') {
        $calls{$fieldName}->{ join '.', @path } = $value;
      }
      elsif ($fieldListtype{$fieldName} eq 'arrayMultilingual') {
        $calls{$fieldName}->{ shift @path }->[ join '.', @path ] = $value;
      }
      elsif ($fieldListtype{$fieldName} eq 'hashMultilingual') {
        $calls{$fieldName}->{ shift @path }->{ join '.', @path } = $value;
      }
      else {
        die "Found fieldName '$fieldName' in table '$table' (of fieldListtype '$fieldListtype{$fieldName}'). Don't know how to handle it. The current object (" . $object->getId() . ") is of class '" . $object->getMetaClassName() . "'";
      }
    }

    # invoke calls with arguments based on 
    foreach my $fieldName (keys %calls) {
      my $method = 'set' . ucfirst $fieldName;
      if ($fieldListtype{$fieldName} eq 'array') {
#        print "$method(@{$calls{$fieldName}})\n";
        $object->$method(@{$calls{$fieldName}});
      }
      elsif ($fieldListtype{$fieldName} eq 'hash') {
#        print "$method($calls{$fieldName})\n";
        $object->$method(%{$calls{$fieldName}});
      }
      else {
        # multilingual (first level of struct is locale)
        foreach my $locale (keys %{ $calls{$fieldName} }) {
          next unless $object->isAvailableLocale($locale);
          $object->setCurrentLocale($locale);
          my $args = $calls{$fieldName}->{$locale};
#          print "$method($args) [locale=$locale]\n";
          if ($fieldListtype{$fieldName} eq 'noneMultilingual') {
            $object->$method($args);
          }
          elsif ($fieldListtype{$fieldName} eq 'arrayMultilingual') {
            $object->$method(@$args);
          }
          elsif ($fieldListtype{$fieldName} eq 'hashMultilingual') {
            $object->$method(%$args);
          }
        }
      }
    }
  }
  $obj->setOriginalListFieldTableValues($object);
  $object->setCurrentLocale($originalCurrentLocale); # reset locale
}
#-----------------------------------------------------------------------------
sub setOriginalListFieldTableValues {
  my ($obj, $object) = @_;
  my %seenTableNames;
  foreach my $field ($obj->getModel()->getListFields()) {
    my $tableName = $field->getListTableName();
    next if $seenTableNames{$tableName};
    $seenTableNames{$tableName} = 1;
    my $sth = $db->sql( "select name,value from $tableName where objectId = ?", $object->getId() );
    $obj->{originalListFieldTableValues}->{ $object->getId() }->{$tableName} = {};
    while ( my ($name, $value) = $sth->next() ) {
      $obj->{originalListFieldTableValues}->{ $object->getId() }->{$tableName}->{$name}                 = $value;
      $obj->{originalListFieldTableValues}->{ $object->getId() }->{$tableName}->{lowercase}->{lc $name} = $value;
    }
  }
}
#-----------------------------------------------------------------------------
our %runtimeMethodsSetup = ();
sub _setupRuntimeMethods {
  my ($obj, $object) = @_;

  return if $runtimeMethodsSetup{ref $object};
  $runtimeMethodsSetup{ref $object} = 1;

  my $model = $obj->getModel();

  foreach my $className ($model->getClassNames()) {
#    print "setup: $className\n";
    {
      my %methods;
    FIELD:
      foreach my $field ($model->getTableFieldsByClassName($className)) {
#        printf "setting up get/set accessors for %s for $className\n", $field->getName();

        if ($field->isObjectType()) {
          $obj->_setObjectFieldAccessors($field, \%methods);
        }
        else {
          $obj->_setNormalFieldAccessors($field, \%methods);
        }
      }

      foreach my $field ($model->getListFields()) {
        next if $field->getClassName() ne $className;
#        print "setting up list accessors for " . $field->getName() . "\n";
        if ($field->getListType() eq 'array') {
          $obj->_setListTypeArrayAccessors($field, \%methods);
        }
        elsif ($field->getListType() eq 'hash') {
          $obj->_setListTypeHashAccessors($field, \%methods);
        }
        else { # multilingual scalar
          $obj->_setMultilingualAccessors($field, \%methods);
        }
      }
      # set all methods
      foreach my $method (keys %methods) {
        no strict 'refs';
        *{$className.'::'.$method} = $methods{$method} unless $className->can($method);
      }
    } # end scope
  } # end main foreach 
}
#-----------------------------------------------------------------------------
sub _setNormalFieldAccessors {
  my ($obj, $field, $methods) = @_;
  $methods->{ $field->getSetAccessor() } = sub {
    my ($obj, $value) = @_;
    $field->validateValidValues($value);
    $obj->{data}->{ $field->getName() } = $obj->getManager()->_fixValueForSetter($field, $value);
    $obj->setHasUnsavedChanges(1);
  };
  $methods->{ $field->getGetAccessor() } = sub {
    my ($obj) = @_;
    my $value = defined $obj->{data}->{ $field->getName() }  ?  $obj->{data}->{ $field->getName() }  :  $field->getDefaultValue();
    return $obj->getManager()->_fixValueForGetter($field, $value);
  };
}
#-----------------------------------------------------------------------------
sub _getDateInDbFormat {
  my ($obj, $date) = @_;
  return unless $date;
  return $context->getSingleton('O2::Mgr::DateTimeManager')->newObject($date)->dbFormat();
}
#-----------------------------------------------------------------------------
sub _getDateObjectFromDbString {
  my ($obj, $dateTime) = @_;
  return if !$dateTime || $dateTime eq '0000-00-00 00:00:00';
  return $context->getSingleton('O2::Mgr::DateTimeManager')->newObject($dateTime);
}
#-----------------------------------------------------------------------------
sub _setObjectFieldAccessors {
  my ($obj, $field, $methods) = @_;
  my ($idSetter, $objectSetter);
  if ($field->getName() !~ m{ Id \z }xms) {
    $idSetter     = $field->getSetAccessor() . 'Id';
    $objectSetter = $field->getSetAccessor();
  }
  else {
    $idSetter       = $field->getSetAccessor();
    ($objectSetter) = $idSetter =~ m{ \A (.+) Id \z }xms;
  }
  $methods->{$idSetter} = $methods->{$objectSetter} = sub {
    my ($obj, $value) = @_;
    $obj->{data}->{ $field->getName() } = $value;
    $obj->setHasUnsavedChanges(1);
  };

  my ($objectGetter, $idGetter);
  if ($field->getName() =~ m{ Id \z }xms) {
    $idGetter     = $field->getGetAccessor();
    $objectGetter = $idGetter;
    $objectGetter =~ s{ Id \z }{}xms;
    $methods->{$idGetter} = sub {
      my ($obj) = @_;
      return $field->getDefaultValue() unless defined $obj->{data}->{ $field->getName() };
      my $value = $obj->{data}->{ $field->getName() };
      return $value unless $value;
      return
               $value  =~ m{ \A \d+ \z }xms                                ? $value
        : ref ($value) =~ m{ ::Obj::   }xms                                ? $value->getId() || $value
        : ref ($value) eq 'HASH' && $value->{meta} && $value->{meta}->{id} ? $value->{meta}->{id}
        :                                                                    die "Could not call method $idGetter: value = $value";
    };
    $methods->{$objectGetter} = sub {
      my ($obj) = @_;
      my $value = $obj->getModelValue( $field->getName() );
      return unless $value;
      return
          ref ($value) =~ m{ ::Obj:: }xms                                  ? $value
        : ref ($value) eq 'HASH' && $value->{meta} && $value->{meta}->{id} ? $context->getObjectById( $value->{meta}->{id} )
        : $value =~ m{ \A \d+ \z }xms                                      ? $context->getObjectById( $value               )
        :                                                                    die "Could not call method $objectGetter: value = $value"
        ;
    };
  }
  else {
    $objectGetter = $field->getGetAccessor();
    $idGetter     = "${objectGetter}Id";
    $methods->{$objectGetter} = sub {
      my ($obj) = @_;
      my $value = $obj->getModelValue( $field->getName() );
      return unless $value;
      return
          ref ($value) =~ m{ ::Obj:: }xms                                  ? $value
        : ref ($value) eq 'HASH' && $value->{meta} && $value->{meta}->{id} ? $context->getObjectById( $value->{meta}->{id} )
        : $value =~ m{ \A \d+ \z }xms                                      ? $context->getObjectById( $value               )
        :                                                                    die "Could not call method $objectGetter: value = $value"
        ;
    };
    $methods->{$idGetter} = sub {
      my ($obj) = @_;
      my $value = $obj->getModelValue( $field->getName() );
      return unless $value;
      return
          ref ($value) =~ m{ ::Obj:: }xms ? $value->getId()
        : ref ($value) eq 'HASH' && $value->{meta} && $value->{meta}->{id} ? $value->{meta}->{id}
        : $value =~ m{ \A \d+ \z }xms                                      ? $value
        :                                                                    die "Could not call method $idGetter: value = $value"
        ;
    };
  }
}
#-----------------------------------------------------------------------------
sub _setListTypeArrayAccessors {
  my ($obj, $field, $methods) = @_;
  if ($field->isMultilingual()) {
    $methods->{ $field->getSetAccessor() } = sub {
      my ($obj, @values) = @_;
      $field->validateValidValues(@values);
      $obj->{data}->{ $field->getName() }->{ $obj->getCurrentLocale() } = $obj->getManager()->_fixArrayValuesForSetter($field, \@values);
      $obj->setHasUnsavedChanges(1);
    };
    $methods->{ $field->getGetAccessor() } = sub {
      my ($obj) = @_;
      my $values = $obj->{data}->{ $field->getName() }->{ $obj->getCurrentLocale() };
      $values    = $obj->getManager()->_fixArrayValuesForGetter($field, $values);
      return wantarray ? @{$values} : $values;
    };
  }
  else {
    if ($field->isObjectType()) {
      my $idSetter = $field->getSetAccessor();
      my $objectSetter;
      if ($idSetter =~ m{ Ids \z }xms) {
        $objectSetter = $idSetter;
        $objectSetter =~ s{ Ids \z }{s}xms;
      }
      else {
        $objectSetter = $idSetter;
        $idSetter = $obj->_appendIds($idSetter);
      }
      $methods->{$idSetter} = $methods->{$objectSetter} = sub {
        my ($obj, @values) = @_;
        $field->validateValidValues(@values);
        $obj->{data}->{ $field->getName() } = $obj->getManager()->_fixArrayValuesForSetter($field, \@values);
        $obj->setHasUnsavedChanges(1);
      };
      my ($idGetter, $objectGetter) = ($idSetter, $objectSetter);
      $idGetter     =~ s{ \A set }{get}xms;
      $objectGetter =~ s{ \A set }{get}xms;
      $methods->{$idGetter} = sub {
        my ($obj) = @_;
        my @rawValues;
        @rawValues = @{  $obj->{data}->{ $field->getName() }  } if $obj->{data}->{ $field->getName() };
        my @values;
        foreach my $value (@rawValues) {
          if (ref ($value) eq 'HASH') {
            my ($id, $struct) = each %{$value};
            push @values, $id;
          }
          else {
            push @values, ref ($value) =~ m{ ::Obj:: }xms && $value->getId() ? $value->getId() : $value;
          }
        }
        my $values = $obj->getManager()->_fixArrayValuesForGetter($field, \@values);
        return wantarray ? @{$values} : $values;
      };
      $methods->{$objectGetter} = sub {
        my ($obj) = @_;
        my @rawValues;
        @rawValues = @{  $obj->{data}->{ $field->getName() }  } if $obj->{data}->{ $field->getName() };
        my @values;
        foreach my $value (@rawValues) {
          next unless $value;
          $value = $context->getObjectById($value) unless ref $value;
          push @values, $value if $value;
        }
        my $values = $obj->getManager()->_fixArrayValuesForGetter($field, \@values);
        return wantarray ? @{$values} : $values;
      };
    }
    else { # Not object-type
      $methods->{ $field->getSetAccessor() } = sub {
        my ($obj, @values) = @_;
        $field->validateValidValues(@values);
        $obj->{data}->{ $field->getName() } = $obj->getManager()->_fixArrayValuesForSetter($field, \@values);
        $obj->setHasUnsavedChanges(1);
      };
      $methods->{ $field->getGetAccessor() } = sub {
        my ($obj) = @_;
        my @values;
        @values = @{  $field->getDefaultValue()            } if $field->getDefaultValue();
        @values = @{  $obj->{data}->{ $field->getName() }  } if $obj->{data}->{ $field->getName() };
        my $values = $obj->getManager()->_fixArrayValuesForGetter($field, \@values);
        return wantarray ? @{$values} : $values;
      };
    }
  }
}
#-----------------------------------------------------------------------------
sub _setListTypeHashAccessors {
  my ($obj, $field, $methods) = @_;
  if ($field->isMultilingual()) {
    $methods->{ $field->getSetAccessor() } = sub {
      my ($obj, %values) = @_;
      $obj->{data}->{ $field->getName() }->{ $obj->getCurrentLocale() } = $obj->getManager()->_fixHashValuesForSetter($field, \%values);
      $obj->setHasUnsavedChanges(1);
    };
    $methods->{ $field->getGetAccessor() } = sub {
      my ($obj) = @_;
      my %values = %{  $obj->{data}->{ $field->getName() }->{ $obj->getCurrentLocale() }  ||  {}  };
      return wantarray ? %values : \%values;
    };
  }
  else {
    if ($field->isObjectType()) {
      my $idSetter = $field->getSetAccessor();
      my $objectSetter;
      if ($idSetter =~ m{ Ids \z }xms) {
        $objectSetter = $idSetter;
        $objectSetter =~ s{ Ids \z }{s}xms;
      }
      else {
        $objectSetter = $idSetter;
        $idSetter = $obj->_appendIds($idSetter);
      }
      $methods->{$idSetter} = $methods->{$objectSetter} = sub {
        my ($obj, %values) = @_;
        $obj->{data}->{ $field->getName() } = $obj->getManager()->_fixHashValuesForSetter($field, \%values);
        $obj->setHasUnsavedChanges(1);
      };
      my ($idGetter, $objectGetter) = ($idSetter, $objectSetter);
      $idGetter     =~ s{ \A set }{get}xms;
      $objectGetter =~ s{ \A set }{get}xms;
      $methods->{$idGetter} = sub {
        my ($obj) = @_;
        my %rawValues;
        %rawValues = %{  $obj->{data}->{ $field->getName() }  } if $obj->{data}->{ $field->getName() };
        my %values;
        while (my ($key, $value) = each %rawValues) {
          $values{$key} = ref ($value) =~ m{ ::Obj:: }xms && $value->getId() ? $value->getId() : $value;
        }
        my $values = $obj->getManager()->_fixHashValuesForGetter($field, \%values);
        return wantarray ? %{$values} : $values;
      };
      $methods->{$objectGetter} = sub {
        my ($obj) = @_;
        my %rawValues;
        %rawValues = %{  $obj->{data}->{ $field->getName() }  } if $obj->{data}->{ $field->getName() };
        my %values;
        while (my ($key, $value) = each %rawValues) {
          next unless $value;
          $value = $context->getObjectById($value) unless ref $value;
          $values{$key} = $value if $value;
        }
        my $values = $obj->getManager()->_fixHashValuesForGetter($field, \%values);
        return wantarray ? %{$values} : $values;
      };
    }
    else { # Not object-type
      $methods->{ $field->getSetAccessor() } = sub {
        my ($obj, %values) = @_;
        $obj->{data}->{ $field->getName() } = $obj->getManager()->_fixHashValuesForSetter($field, \%values);
        $obj->setHasUnsavedChanges(1);
      };
      $methods->{ $field->getGetAccessor() } = sub {
        my ($obj) = @_;
        my $values = $obj->{data}->{ $field->getName() }  ||  {};
        return %{ $obj->getManager()->_fixHashValuesForGetter($field, $values) };
      };
    }
  }
}
#-----------------------------------------------------------------------------
sub _setMultilingualAccessors {
  my ($obj, $field, $methods) = @_;
  $methods->{ $field->getSetAccessor() } = sub {
    my ($obj, $value) = @_;
    $obj->{data}->{ $field->getName() }->{ $obj->getCurrentLocale() } = $value;
    $obj->setHasUnsavedChanges(1);
  };
  $methods->{ $field->getGetAccessor() } = sub {
    my ($obj) = @_;
    return $obj->{data}->{ $field->getName() }->{ $obj->getCurrentLocale() };
  };
}
#-----------------------------------------------------------------------------
sub _fixArrayValuesForSetter {
  my ($obj, $field, $values) = @_;
  foreach my $i (0 .. $#{$values}) {
    $values->[$i] = $obj->_fixValueForSetter( $field, $values->[$i] );
  }
  return $values;
}
#-----------------------------------------------------------------------------
sub _fixArrayValuesForGetter {
  my ($obj, $field, $values) = @_;
  foreach my $i (0 .. $#{$values}) {
    $values->[$i] = $obj->_fixValueForGetter( $field, $values->[$i] );
  }
  return $values;
}
#-----------------------------------------------------------------------------
sub _fixHashValuesForSetter {
  my ($obj, $field, $values) = @_;
  foreach my $key (keys %{$values}) {
    $values->{$key} = $obj->_fixValueForSetter( $field, $values->{$key} );
  }
  return $values;
}
#-----------------------------------------------------------------------------
sub _fixHashValuesForGetter {
  my ($obj, $field, $values) = @_;
  foreach my $key (keys %{$values}) {
    $values->{$key} = $obj->_fixValueForGetter( $field, $values->{$key} );
  }
  return $values;
}
#-----------------------------------------------------------------------------
sub _fixValueForSetter {
  my ($obj, $field, $value) = @_;
  return $obj->_getDateInDbFormat($value) if $field->getType() eq 'date';
  return $value;
}
#-----------------------------------------------------------------------------
sub _fixValueForGetter {
  my ($obj, $field, $value) = @_;
  return $obj->_getDateObjectFromDbString($value) if $field->getType() eq 'date';
  return $value;
}
#-----------------------------------------------------------------------------
sub _appendIds {
  my ($obj, $methodName) = @_;
  if ($methodName =~ m{ s \z }xms) {
    $methodName =~ s{ (ie)? s \z }{ ($1 ? 'y' : '') . 'Ids' }xmse;
    return $methodName;
  }
  return $methodName . 'Ids';
}
#-----------------------------------------------------------------------------
sub _removeIds {
  my ($obj, $methodName) = @_;
  return $methodName if $methodName !~ m{ Ids? \z }xms;
  
  my $isPlural = $methodName =~ m{ Ids \z }xms;
  $methodName =~ s{ Id (s?) \z }{$1}xms;
  $methodName =~ s{  y      \z }{ies}xms if $isPlural;
  return $methodName;
}
#-----------------------------------------------------------------------------
sub save {
  my ($obj, $object, %params) = @_;
  my $originalObjectId = $object->getId() || 0;
  $obj->_uncacheForCurrentRequest($originalObjectId) if $originalObjectId;

  # insert O2_OBJ_OBJECT row
  my $changeTime = $object->{_dontOverwriteChangeTimeOnSave} ? $object->getMetaChangeTime() : time;
  my $createTime = $object->getMetaCreateTime() || $changeTime;
  my $ownerId    = $object->getMetaOwnerId()    || $context->getUserId();
  my %columns = (
    objectId   => $originalObjectId,
    parentId   => $object->getMetaParentId(),
    name       => $object->getMetaName(),
    className  => $object->getMetaClassName(),
    createTime => $createTime,
    changeTime => $changeTime,
    status     => $object->getMetaStatus(),
    ownerId    => $ownerId,
  );

  # The following fields may have been changed, so we need to set them so they will be stored correctly in the cache.
  $object->setMetaCreateTime( $createTime );
  $object->setMetaChangeTime( $changeTime );
  $object->setMetaOwnerId(    $ownerId    );

  my $isUpdate = $originalObjectId > 0;

  $context->startTransaction();
  
  if ($isUpdate) {
    my $numRowsAffected = $db->idUpdate('O2_OBJ_OBJECT', 'objectId', %columns);
    if ($numRowsAffected == 0) { # Object might have been deleted permanently and reinstantiated with the same ID.
      $isUpdate = 0;
      $db->insert('O2_OBJ_OBJECT', %columns, objectId => $originalObjectId);
    }
  }
  else {
    my $objectId = $db->idInsert('O2_OBJ_OBJECT', 'objectId', %columns);
    $object->setId($objectId);
  }
  
  # In some (or many) cases, we need the id to be able to check if we're allowed to save or not. So we can't call canSave at the very start of this method.
  my $errorMsg = '';
  if (!$object->canSave(\$errorMsg)) {
    $context->rollback();
    die "Not allowed to save object: $errorMsg";
  }
  
  
  my $model = $obj->getModel();
  
  # Save related objects that need saving
  foreach my $field ($model->getFields()) {
    if ($field->isObjectType()) {
      my $value = $object->{data}->{ $field->getName() };
      if ($field->getListType() eq 'array'  &&  ref $value eq 'ARRAY') {
        for my $i ( 0 .. $#{$value} ) {
          my $item = $value->[$i];
          $item->save()                                                 if ref $item  &&  ( !$item->getId() || $item->hasUnsavedChanges() );
          $object->{data}->{ $field->getName() }->[$i] = $item->getId() if ref $item; # Convert from object to ID
          $i++;
        }
      }
      elsif ($field->getListType() eq 'hash'  &&  ref $value eq 'HASH') {
        while (my ($key, $item) = each %{$value}) {
          next if !ref $item || ref ($item) !~ m{ ::Obj:: }xms;
          
          $item->save() if !$item->getId() || $item->hasUnsavedChanges();
          $object->{data}->{ $field->getName() }->{$key} = $item->getId(); # Convert from object to ID
        }
      }
      elsif ($field->getListType() eq 'none') {
        $value->save() if ref $value  &&  ( !$value->getId() || $value->hasUnsavedChanges() );
        $object->{data}->{ $field->getName() } = $value->getId() if ref $value; # Convert from object to ID
      }
    }
  }
  
  # insert into each class' "class table" (like O2_OBJ_MEMBER)
  my @classNames = $model->getClassNames();
  foreach my $className (@classNames) {
    
    my $tableName = $obj->_classNameToTableName($className);
    
    # gather 
    my %classColumns;
    foreach my $field ($model->getTableFieldsByClassName($className)) {
      my $value = $object->getModelValue( $field->getName() );
      $value    = $context->getSingleton('O2::Mgr::DateTimeManager')->newObject($value) if $value && $field->getType() eq 'date';
      $classColumns{ $field->getName() } = $value;
      $classColumns{ $field->getName() } = $value->format('yyyy-MM-dd HH:mm:ss') if $value && $field->getType() eq 'date';
    }
    # does this class have its own table?
    if (%classColumns) {
      $classColumns{objectId} = $object->getId();
      $obj->_saveInModelTable($tableName, $isUpdate || $object->{metaClassNameWasChangedFrom}, %classColumns);
    }
    elsif ((!$isUpdate || $object->{metaClassNameWasChangedFrom})  &&  $className ne 'O2::Obj::Object') {
      my $dbIntrospect = $context->getSingleton('O2::DB::Util::Introspect');
      if ($dbIntrospect->tableExists($tableName)) {
        eval { # Catch duplicate entry exception. Might be thrown if class name was changed.
          $obj->_saveInModelTable( $tableName, 0, objectId => $object->getId() );
        };
      }
    }
  }
  
  eval {
    $obj->_saveListFields($object, $model);
  };
  if ($@) {
    $context->rollback();
    die "Couldn't call method _saveListFields: $@";
  }
  
  $context->endTransaction();
  
  if ($context->cmsIsEnabled()) {
    # Update page cache only for objects whose class has an object template associated with it
    my @objectTemplates = $context->getSingleton('O2CMS::Mgr::Template::ObjectManager')->getObjectTemplatesByClassName(ref $object);
    if (@objectTemplates) {
      my $eventListenerMgr = $context->getSingleton('O2::Mgr::EventListenerManager');
      if (!$eventListenerMgr->newEventExists('updatePageCache', $object) && !$obj->_newUpdatePageCacheEventForFrontpageExists($object)) {
        $eventListenerMgr->raiseEvent('updatePageCache', $object);
      }
    }
  }
  
  $obj->saveRevision($object);

  if ($obj->{cacheHandler}->canCacheObject())  {
    if ($object->getId() && $object->can('isCachable') && $object->isCachable() && !$object->isDeleted()) {
      $obj->{cacheHandler}->setObject($object); # add to cache
    }
    else {
      $obj->{cacheHandler}->deleteObjectById( $object->getId() );
    }
  }
  $object->setHasUnsavedChanges(0);
  $obj->_cacheForCurrentRequest($object);
  
  my $originalClassName = $object->{metaClassNameWasChangedFrom};
  # If class name was changed...
  if ($originalClassName) {
    # ...delete from tables not used by the new class name:
    my $otherMgr = $context->getUniversalMgr()->getManagerByClassName($originalClassName);
    my $otherModel = $otherMgr->getModel();
    foreach my $className ($otherModel->getClassNames()) {
      my $tableName = $obj->_classNameToTableName($className);
      $db->sql( "delete from $tableName where objectId = ?", $object->getId() ) unless contains @classNames, $className;
    }
    # ...delete list fields not used by the new class:
    my %fieldNames = map { $_->getName() => 1 } $model->getListFields();
    foreach my $field ($otherModel->getListFields()) {
      my $fieldName = $field->getName();
      if (!$fieldNames{$fieldName}) { # Not one of this class' fields, so must be deleted
        my $tableName = $field->getListTableName();
        $db->sql("delete from $tableName where objectId = ? and name like ?", $object->getId(), "$fieldName.%");
      }
    }
  }
  $object->{metaClassNameWasChangedFrom} = undef;
  
  if ($params{archive}) {
    # Object has been saved in archive-database, let's delete it from "normal" database:
    $context->useNormalDbh();
    $object->deletePermanently();
    $context->usePreviousDbh();
  }
  else {
    # Make sure to remove object from archive
    $context->useArchiveDbh();
    if ($db->fetch('select objectId from O2_OBJ_OBJECT where objectId = ?', $object->getId())) {
      $object->deletePermanently();
    }
    $context->usePreviousDbh();
  }

  return $object;
}
#-----------------------------------------------------------------------------
sub saveRevision {
  my ($obj, $object, %params) = @_;
  return if !$object->can('isRevisionable') || !$object->isRevisionable();
  
  my $revisionedObject = $params{revisionedObject};
  if (!$revisionedObject) {
    my $revisionedObjectMgr = $context->getSingleton('O2::Mgr::RevisionedObjectManager');
    $revisionedObject = $revisionedObjectMgr->newObject();
  }
  $revisionedObject->setMetaName(           $object->getMetaName() || $revisionedObject->getMetaName() );
  $revisionedObject->setMetaOwnerId(        $context->getUserId()                                      );
  $revisionedObject->setRevisionedObjectId( $object->getId() || -1                                     );
  $revisionedObject->setSerializedObject(   $object->serialize()                                       );
  
  $revisionedObject->save();
}
#-----------------------------------------------------------------------------
sub indexForSearch {
  my ($obj, $object, $indexName, $fieldsToIndex) = @_;
  return unless $context->cmsIsEnabled();
  
  $fieldsToIndex  ||= [ $object->getIndexableFields() ];
  my $objectIndexer = $context->getSingleton('O2CMS::Search::ObjectIndexer', indexName => $indexName);
  return $objectIndexer->addOrUpdateObject($object) unless @{$fieldsToIndex};
  
  my %attributes;
  foreach my $field (@{$fieldsToIndex}) {
    my $method = 'get' . ucfirst $field;
    my $value  = $object->$method();
    $value     =~ s{ :: }{_}xmsg if $field eq 'metaClassName'; # Swish doesn't index words containing colons
    $attributes{$field} = $value;
  }
  $objectIndexer->addOrUpdateObject( $object, attributes => \%attributes );
}
#-----------------------------------------------------------------------------
sub _saveInModelTable {
  my ($obj, $table, $isUpdate, %classColumns) = @_;
  if ($isUpdate) { # If class name was changed, we don't know if we should insert or update
    my $numRowsAffected = $db->idUpdate($table, 'objectId', %classColumns);
    return if $numRowsAffected > 0;

    # If no rows were affected and there's no row with the given id, then we should do an insert (after this if block)
    my ($objectId) = $db->fetch("select objectId from $table where objectId = ?", $classColumns{objectId});
    return if $objectId;
  }
  $db->insert($table, %classColumns);
}
#-----------------------------------------------------------------------------
sub _updatePageCache {
  my ($obj, $event) = @_;
  my $object = $context->getObjectById( $event->getCallerObjectId() );
  my $pageCacher = $context->getSingleton('O2CMS::Publisher::PageCache');
  
  my $parent = $object->getParent();
  return if $parent && $parent->getMetaClassName() eq 'O2::Obj::Object'; # Ignore caching if called from a test script
  
  if ($object->isDeleted()) {
    $pageCacher->delCached($object);
  }
  elsif ($pageCacher->isCached($object)) {
    $pageCacher->regenerateCached($object); # This will also remove "illegal" cache files and regenerate frontpages where this object is published
  }
  else {
    $pageCacher->cacheObject($object); # (Will only be cached if the object is cachable)
  }
}
#-----------------------------------------------------------------------------
sub _newUpdatePageCacheEventForFrontpageExists {
  my ($obj, $object) = @_;
  
  my $objectCacheHandler = $context->getSingleton('O2CMS::Publisher::PageCache::ObjectCacheHandler');
  
  # The IDs of the frontpages the current object is published on:
  my @frontpageIds = $objectCacheHandler->getIdsOfFrontpagesContainingObjects( $object->getId() );
  
  # IDs of objects with unhandled events:
  my @objectIds = $context->getSingleton('O2::Mgr::EventManager')->search(
    status          => 'new',
    callerEventName => 'updatePageCache',
  )->getAll('callerObjectId');
  
  # The IDs of the frontpages these objects are published on
  my @existingFrontpageIds = $objectCacheHandler->getIdsOfFrontpagesContainingObjects(@objectIds);
  
  return contains(@existingFrontpageIds, @frontpageIds);
}
#-----------------------------------------------------------------------------
sub _saveListFields {
  my ($obj, $object, $model) = @_;
  # prepare to insert list types (multilingual, array and hash)
  my %tables;
  my @locales = $object->getUsedLocales();
  foreach my $field ($model->getListFields()) {
    my $tableName = $field->getListTableName() or die "Don't know what table to save fields of type '" . $field->getType() . "'";
    my $value     = $object->getModelValue( $field->getName() );
    my $result;
    if ($field->getMultilingual()) {
      my $currentLocale = $object->getCurrentLocale();

      foreach my $locale (@locales) {
        $object->setCurrentLocale($locale);
        if ($field->getListType() eq 'none') {
          $result->{$locale} = $value;
        }
        elsif ($field->getListType() eq 'hash') {
          $result->{$locale} = $obj->_fixHashValuesForSetter($field, $value);
        }
        elsif ($field->getListType() eq 'array') {
          $result->{$locale} = $obj->_fixArrayValuesForSetter($field, $value);
        }
      }
      $object->setCurrentLocale($currentLocale);
    }
    else {
      if ($field->getListType() eq 'hash') {
        $result = $obj->_fixHashValuesForSetter($field, $value);
      }
      elsif ($field->getListType() eq 'array') {
        $result = $obj->_fixArrayValuesForSetter($field, $value);
      }
    }
    push @{ $tables{$tableName} }, $obj->_formatStruct( $field->getName(), $result );
  }

  # Insert list types into O2_OBJ_OBJECT_* tables.
  my $listFieldTableValues = {};
  foreach my $tableName (keys %tables) {
    my $insertSth = $db->prepare( "insert into $tableName (objectId, name, value) values (?, ?, ?)"      );
    my $updateSth = $db->prepare( "update      $tableName set value = ? where objectId = ? and name = ?" );
    my $deleteSth = $db->prepare( "delete from $tableName               where objectId = ? and name = ?" );
    foreach my $row (@{ $tables{$tableName} }) {
      my $name     = $row->{name};
      my $newValue = $row->{value};
      $listFieldTableValues->{$tableName}->{$name}                 = $newValue;
      $listFieldTableValues->{$tableName}->{lowercase}->{lc $name} = $newValue;
      my $rowExists     = exists $obj->{originalListFieldTableValues}->{ $object->getId() }->{$tableName}->{lowercase}->{lc $name};
      my $originalValue = delete $obj->{originalListFieldTableValues}->{ $object->getId() }->{$tableName}->{$name};
      $originalValue    = '' unless defined $originalValue;
      next if $newValue eq $originalValue;
      $updateSth->execute( $newValue, $object->getId(), $name )     if $rowExists;
      $insertSth->execute( $object->getId(), $name, $newValue ) unless $rowExists;
    }
    $updateSth->finish();
    $insertSth->finish();
    foreach my $name (keys %{ $obj->{originalListFieldTableValues}->{ $object->getId() }->{$tableName} }) {
      $deleteSth->execute( $object->getId(), $name );
    }
    $deleteSth->finish();
  }
  $obj->{originalListFieldTableValues}->{ $object->getId() } = $listFieldTableValues;
}
#-----------------------------------------------------------------------------
# recursive method for converting a datastructure to key/value pairs.
# key is dotted. So title.en_US=Hello means (title=>{en_US=>'Hello'}}
sub _formatStruct {
  my ($obj, $prefix, $struct) = @_;
  my @rows;
  if (ref $struct eq 'HASH') {
    foreach my $key (keys %{$struct}) {
      push @rows, $obj->_formatStruct( "$prefix.$key", $struct->{$key} );
    }
    return @rows;
  }
  if (ref $struct eq 'ARRAY') {
    foreach my $index (0 .. $#$struct) {
      push @rows, $obj->_formatStruct( sprintf ("$prefix.%.8d", $index), $struct->[$index] );
    }
    return @rows;
  }
  return defined $struct  ?  { name => $prefix, value => $struct }  :  ();
}
#-----------------------------------------------------------------------------
sub getModel {
  my ($obj) = @_;
  return $obj->{model} if $obj->{model}; # model cached
  require O2::Mgr::Object::ModelManager;
  my $modelMgr = O2::Mgr::Object::ModelManager->new();
  $obj->{model} = $modelMgr->newObject();
  $obj->{model}->setClassName(        $obj->getModelClassName() );
  $obj->{model}->setManagerClassName( ref $obj                  );
  $obj->initModel( $obj->{model} );
  return $obj->{model};
}
#-----------------------------------------------------------------------------
sub initModel {
  my ($obj, $model) = @_;

  $model->registerFields(
    'O2::Obj::Object',
    id             => { type => 'int',                                  },
    metaParentId   => { type => 'O2::Obj::Object',                      },
    metaName       => { type => 'varchar',                              },
    metaClassName  => { type => 'varchar',                              },
    metaCreateTime => { type => 'epoch',                                },
    metaChangeTime => { type => 'epoch',                                },
    metaStatus     => { type => 'varchar',                              },
    metaOwnerId    => { type => 'O2::Obj::Person',                      },
    keywordIds     => { type => 'O2::Obj::Keyword', listType => 'array' },
  );

  $model->registerIndexes(
    'O2::Obj::Object',
    { name => 'parentId_index',  columns  => [qw(parentId)],  isUnique => 0 },
    { name => 'className_index', columns  => [qw(className)], isUnique => 0 },
    { name => 'status_index',    columns  => [qw(status)],    isUnique => 0 },
  );
}
#-----------------------------------------------------------------------------
sub deleteObject {
  my ($obj, $object) = @_;
  my $objectId = $object->getId();
  
  $obj->_uncacheForCurrentRequest($objectId);
  
  if ($context->cmsIsEnabled()) {
    if ($object && $object->getMetaParentId()) { # Don't want objects without parent ID in trashcan
      $context->getTrashcan()->trashObject($object);
    }
    elsif ($object) {
      $object->setMetaStatus('deleted');
      $object->save();
    }
  }
  else {
    $object->setMetaStatus('trashed');
    $object->save();
  }
  
  $obj->{cacheHandler}->deleteObjectById($objectId) if $obj->{cacheHandler}->canCacheObject();
  
  return 1;
}
#-----------------------------------------------------------------------------
# Move to trash - but what's the ID of the trashcan???
sub deleteObjectById {
  my ($obj, $objectId) = @_;
  $obj->deleteObject( $context->getObjectById($objectId) );
}
#-----------------------------------------------------------------------------
# remove object from database
sub deleteObjectPermanentlyById {
  my ($obj, $objectId) = @_;
  $obj->_uncacheForCurrentRequest($objectId);

  $obj->_deleteFromDbTables($objectId);

  my @revisionedObjectIds = $db->selectColumn("select objectId from O2_OBJ_REVISIONEDOBJECT where revisionedObjectId = ?", $objectId);
  foreach my $id (@revisionedObjectIds) {
    my $revisionedObject = $context->getObjectById($id);
    $revisionedObject->deletePermanently() if $revisionedObject;
  }

  $obj->{cacheHandler}->deleteObjectById($objectId) if $obj->{cacheHandler}->canCacheObject();
}
#-----------------------------------------------------------------------------
sub _deleteFromDbTables {
  my ($obj, $objectId) = @_;
  my %removeFromTables = ('O2_OBJ_OBJECT' => 1);
  my $model = $obj->getModel();
  # find list tables used
  foreach my $field ($model->getListFields()) {
    $removeFromTables{ $field->getListTableName() } = 1;
  }
  # find class tables used
  foreach my $className ($model->getClassNames()) {
    my $tableName = $obj->_classNameToTableName($className);
    $removeFromTables{$tableName} = 1;
  }
  # remove from involved tables
  foreach my $tableName (keys %removeFromTables) {
    eval { # In an eval block in case the table doesn't exist
      $db->sql("delete from $tableName where objectId = ?", $objectId);
    };
  }
}
#-----------------------------------------------------------------------------
sub _classNameToTableName {
  my ($obj, $className) = @_;
  my $tableName = uc $className;
  $tableName    =~ s{ :: }{_}xmsg;
  return $tableName;
}
#-----------------------------------------------------------------------------
sub error {
  my ($obj, $msg) = @_;
  die $msg;
}
#-----------------------------------------------------------------------------
1;
