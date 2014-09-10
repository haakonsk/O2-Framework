package O2::Obj::Object;

use strict;

use O2 qw($context $cgi $config $db);
use O2::Util::List qw(upush contains);

use overload(
  '""'  => '_toString',
);

#-----------------------------------------------------------------------------
sub new {
  my ($pkg, %init) = @_;
  
  $init{currentLocale} = undef;
  return bless {
    _metaObject => {
      createTime => time,
      changeTime => time,
      className  => $pkg,
      status     => 'new',
      ownerId    => undef,
    },
    %init,
  }, $pkg;
}
#-----------------------------------------------------------------------------
sub clone {
  my ($obj) = @_;
  my $clone = $obj->getManager()->newObject();
  
  foreach my $field ($obj->getModel()->getFields()) {
    my $listType = $field->getListType();
    if ($field->isObjectType() && $field->getClassName() ne 'O2::Obj::Object') { # Got to clone recursively
      my $getter = $field->getObjectGetAccessor();
      my $setter = $field->getObjectSetAccessor();
      if ($listType eq 'array') {
        my @objects = $obj->$getter();
        my @clonedObjects;
        foreach my $object (@objects) {
          push @clonedObjects, $object->clone();
        }
        $clone->$setter(@clonedObjects);
      }
      elsif ($listType eq 'hash') {
        my %objects = $obj->$getter();
        my %clonedObjects;
        while (my ($key, $object) = each %objects) {
          $clonedObjects{$key} = $object->clone();
        }
        $clone->$setter(%clonedObjects);
      }
      else {
        my $object = $obj->$getter();
        $clone->$setter( $object->clone() ) if $object;
      }
    }
    elsif ($listType eq 'array') {
      my @values = $obj->getModelValue( $field->getName() );
      my $setter = $field->getSetAccessor();
      $clone->$setter(@values);
    }
    elsif ($listType eq 'hash') {
      my %values = $obj->$obj->getModelValue( $field->getName() );
      my $setter = $field->getSetAccessor();
      $clone->$setter(%values);
    }
    else {
      my $newValue = $obj->getModelValue( $field->getName() );
      my $setter = $field->getSetAccessor();
      $clone->$setter($newValue) if defined $newValue;
    }
  }
  
  $clone->setId(undef);
  $clone->setMetaCreateTime(time);
  
  return $clone;
}
#-----------------------------------------------------------------------------
sub _toString {
  my ($obj) = @_;
  my $id     = $obj->getId();
  my $status = $obj->getMetaStatus() || '';
  my $str = overload::StrVal($obj);
  $str   .= " (ID=$id, $status)"      if $id;
  $str   .= " (Unsaved, $status)" unless $id;
  return $str;
}
#-----------------------------------------------------------------------------
sub hasUnsavedChanges {
  my ($obj) = @_;
  return $obj->{_hasUnsavedChanges};
}
#-----------------------------------------------------------------------------
sub setHasUnsavedChanges {
  my ($obj, $hasUnsavedChanges) = @_;
  $obj->{_hasUnsavedChanges} = $hasUnsavedChanges;
}
#-----------------------------------------------------------------------------
sub isSerializable {
  return 1;
}
#-----------------------------------------------------------------------------
sub isCachable {
  my ($obj) = @_;
  return $obj->isSerializable();
}
#-----------------------------------------------------------------------------
sub isRevisionable {
  return 0;
}
#-----------------------------------------------------------------------------
sub shouldLogStatusChange {
  my ($oldStatus, $newStatus) = @_;
  return 0;
}
#-----------------------------------------------------------------------------
# Start regular accessors from meta
#-----------------------------------------------------------------------------
sub setId {
  my ($obj, $id) = @_;
  $obj->{id} = $id;
  $obj->setHasUnsavedChanges(1);
}
#-----------------------------------------------------------------------------
sub getId {
  my ($obj) = @_;
  return $obj->{id};
}
#-----------------------------------------------------------------------------
sub setMetaParentId {
  my ($obj, $parentId) = @_;
  $obj->{_metaObject}->{parentId} = $parentId;
  $obj->setHasUnsavedChanges(1);
}
#-----------------------------------------------------------------------------
sub getMetaParentId {
  my ($obj) = @_;
  return $obj->{_metaObject}->{parentId};
}
#-----------------------------------------------------------------------------
sub getContext {
  return $context;
}
#-----------------------------------------------------------------------------
sub getParent {
  my ($obj) = @_;
  my $parentId = $obj->getMetaParentId();
  my $parent = $parentId ? $context->getObjectById($parentId) : undef;
  return $context->getTrashcan() if $obj->isTrashed() && !$parent->isTrashed();
  return $parent;
}
#-----------------------------------------------------------------------------
sub setMetaName {
  my ($obj, $name) = @_;
  $obj->{_metaObject}->{name} = $name;
  $obj->setHasUnsavedChanges(1);
}
#-----------------------------------------------------------------------------
sub getMetaName {
  my ($obj) = @_;
  return $obj->{_metaObject}->{name};
}
#-----------------------------------------------------------------------------
sub setMetaClassName {
  my ($obj, $className) = @_;
  my $originalClassName = $obj->{_metaObject}->{className};
  return $obj->{_metaObject}->{className} = $className if !$originalClassName || $originalClassName eq $className;
  
  # Class name was changed to something new. Let's transform the object into an object of the new class:
  die "Can't change class name of an object without an ID" unless $obj->getId();
  $obj->{_metaObject}->{className} = $className;
  $db->sql( 'update O2_OBJ_OBJECT set className = ? where objectId = ?', $className, $obj->getId() );
  
  # Clear cache
  my $objectId = $obj->getId();
  $context->getMemcached()->deleteObjectById($objectId);
  delete $O2::Mgr::UniversalManager::MANAGER_CACHE->{$objectId} if exists $O2::Mgr::UniversalManager::MANAGER_CACHE->{$objectId};
  
  my $newObj = $obj->reinstantiate();
  my $model  = $newObj->getModel();
  foreach (keys %{ $obj->{data} }) {
    delete $obj->{data}->{$_} unless $model->hasField($_);
  }
  foreach (keys %{ $newObj->{data} }) {
    $obj->{data}->{$_} = $newObj->{data}->{$_} unless exists $obj->{data}->{$_};
  }
  $obj->{manager} = $newObj->{manager};
  bless $obj, $className;
  $obj->{metaClassNameWasChangedFrom} = $originalClassName;
  $obj->setHasUnsavedChanges(1);
}
#-----------------------------------------------------------------------------
sub getMetaClassName {
  my ($obj) = @_;
  return $obj->{_metaObject}->{className};
}
#-----------------------------------------------------------------------------
sub setMetaCreateTime {
  my ($obj, $createTime) = @_;
  $obj->{_metaObject}->{createTime} = $createTime;
  $obj->setHasUnsavedChanges(1);
}
#-----------------------------------------------------------------------------
sub getMetaCreateTime {
  my ($obj) = @_;
  return $obj->{_metaObject}->{createTime};
}
#-----------------------------------------------------------------------------
sub getMetaCreateDateTime {
  my ($obj) = @_;
  return $context->getSingleton('O2::Mgr::DateTimeManager')->newObject( $obj->getMetaCreateTime() );
}
#-----------------------------------------------------------------------------
sub setMetaChangeTime {
  my ($obj, $changeTime, %params) = @_;
  $obj->{_metaObject}->{changeTime}      = $changeTime;
  $obj->{_dontOverwriteChangeTimeOnSave} = $params{dontOverwriteOnSave};
  $obj->setHasUnsavedChanges(1);
}
#-----------------------------------------------------------------------------
sub getMetaChangeTime {
  my ($obj) = @_;
  return $obj->{_metaObject}->{changeTime};
}
#-----------------------------------------------------------------------------
sub getMetaChangeDateTime {
  my ($obj) = @_;
  return $context->getSingleton('O2::Mgr::DateTimeManager')->newObject( $obj->getMetaChangeTime() );
}
#-----------------------------------------------------------------------------
sub setMetaStatus {
  my ($obj, $status, $dontLog) = @_;
  my $oldStatus = $obj->getMetaStatus();
  $obj->logStatusChange($oldStatus, $status) if !$dontLog && $obj->shouldLogStatusChange($oldStatus, $status);
  $obj->{_metaObject}->{status} = $status;
  $obj->setHasUnsavedChanges(1);
}
#-----------------------------------------------------------------------------
sub logStatusChange {
  my ($obj, $oldStatus, $newStatus) = @_;
  return     if $oldStatus eq $newStatus;
  return unless $obj->getId();
  return unless $context->getSingleton('O2::DB::Util::Introspect')->tableExists('O2_STATUS_CHANGE_LOG');
  
  my @stackTrace = $context->getConsole()->getStackTraceArray();
  
  $db->insert(
    'O2_STATUS_CHANGE_LOG',
    objectId   => $obj->getId(),
    userId     => $context->getUserId() || undef,
    oldStatus  => $oldStatus,
    newStatus  => $newStatus,
    dateTime   => $context->getSingleton('O2::Mgr::DateTimeManager')->newObject(time)->dbFormat(),
    caller     => $stackTrace[1]->{fileName} . ', line ' . $stackTrace[1]->{line},
    url        => $cgi ? $cgi->getCurrentUrl() : '',
  );
}
#-----------------------------------------------------------------------------
sub getMetaStatus {
  my ($obj) = @_;
  return $obj->{_metaObject}->{status};
}
#-----------------------------------------------------------------------------
sub setMetaOwnerId {
  my ($obj, $ownerId) = @_;
  $obj->{_metaObject}->{ownerId} = $ownerId;
  $obj->setHasUnsavedChanges(1);
}
#-----------------------------------------------------------------------------
sub getMetaOwnerId {
  my ($obj) = @_;
  return $obj->{_metaObject}->{ownerId};
}
#-----------------------------------------------------------------------------
# End regular accessors from meta
#-----------------------------------------------------------------------------
# returns object controlling these object. Allows objects to impersonate other objects (i.e. symlinks acting as the object they point to)
sub getRealObject {
  my ($obj) = @_;
  return $obj;
}
#-----------------------------------------------------------------------------
# returns value autogenerated accessor would. useful if you write your own get accessor
sub getModelValue {
  my ($obj, $fieldName, $localeCode) = @_;
  my $model = $obj->getManager()->getModel();
  my $field = $model->getFieldByName($fieldName);
  if (my ($metaFieldName) = $fieldName =~ m{ \A meta (.+) }xms) {
    $metaFieldName = lcfirst $metaFieldName;
    return $obj->{_metaObject}->{$metaFieldName} if exists $obj->{_metaObject}->{$metaFieldName};
  }
  my $value;
  if ($field->getMultilingual()) {
    $localeCode ||= $obj->getCurrentLocale();
    $value = $obj->{data}->{$fieldName}->{$localeCode};
  }
  else {
    $value = $obj->{data}->{$fieldName};
  }
  return @{$value} if wantarray && ref $value eq 'ARRAY';
  return %{$value} if wantarray && ref $value eq 'HASH';
  return ()        if wantarray && !defined $value;
  return $value;
}
#-----------------------------------------------------------------------------
sub setModelValue {
  my ($obj, $fieldName, $value, $localeCode) = @_;
  my $model = $obj->getManager()->getModel();
  my $field = $model->getFieldByName($fieldName);
  $field->validateValidValues($value);
  
  if (my ($metaFieldName) = $fieldName =~ m{ \A meta (.+) }xms) {
    $metaFieldName = lcfirst $metaFieldName;
    return $obj->{_metaObject}->{$metaFieldName} = $value if exists $obj->{_metaObject}->{$metaFieldName};
  }
  if ($field->getMultilingual()) {
    $localeCode ||= $obj->getCurrentLocale();
    return $obj->{data}->{$fieldName}->{$localeCode} = $value;
  }
  return $obj->{data}->{$fieldName} = $value;
}
#-----------------------------------------------------------------------------
sub setManager {
  my ($obj, $manager) = @_;
  $obj->{manager} = $manager;
}
#-----------------------------------------------------------------------------
sub getManager {
  my ($obj) = @_;
  return $obj->{manager};
}
#-----------------------------------------------------------------------------
# what language object currently works with
sub setCurrentLocale {
  my ($obj, $currentLocale) = @_;
  my @availableLocales = $obj->getAvailableLocales();
  my %availableLocales = map { $_ => 1 } @availableLocales;
  $obj->{currentLocale} = $currentLocale;
}
#-----------------------------------------------------------------------------
sub getCurrentLocale {
  my ($obj) = @_;
  return $obj->{currentLocale} || $context->getLocaleCode();
}
#-----------------------------------------------------------------------------
sub getModel {
  my ($obj) = @_;
  return $obj->getManager()->getModel();
}
#-----------------------------------------------------------------------------
sub getModelClassName {
  my ($obj) = @_;
  return $obj->getManager()->getModelClassName();
}
#-----------------------------------------------------------------------------
sub isMultilingual {
  my ($obj) = @_;
  return $obj->getModel()->isMultilingual();
}
#-----------------------------------------------------------------------------
# returns all locale codes used in object
sub getUsedLocales {
  my ($obj) = @_;
  my %used;
  my $model = $obj->getModel();
  foreach my $field ($model->getFields()) {
    next unless $field->isMultilingual();
    
    my @locales  =  keys  %{  $obj->{data}->{ $field->getName() }  };
    foreach my $locale (@locales) {
      $used{$locale} = 1;
    }
  }
  
  my %availableLocales = map { $_ => 1 } $obj->getAvailableLocales();
  my @usedLocales;
  foreach my $usedLocale (keys %used) {
    push @usedLocales, $usedLocale if $availableLocales{$usedLocale};
  }
  return @usedLocales;
}
#-----------------------------------------------------------------------------
# returns all available locale codes for this object
sub getAvailableLocales {
  my ($obj) = @_;
  return @{ $obj->{availableLocales} } if $obj->{availableLocales};
  
  my $locales = $obj->getPropertyValue('availableLocales');
  if ($locales) {
    $obj->{availableLocales} = [ split /,/, $locales ];
  }
  else {
    my $locales = $config->get('o2.locales');
    $locales = [ $locales ] unless ref $locales eq 'ARRAY';
    $obj->{availableLocales} = $locales;
  }
  return @{ $obj->{availableLocales} };
}
#-----------------------------------------------------------------------------
sub isAvailableLocale {
  my ($obj, $localeCode) = @_;
  my %availableLocales  =  map  { $_ => 1 }  $obj->getAvailableLocales();
  return $availableLocales{$localeCode};
}
#-----------------------------------------------------------------------------
# properties
#-----------------------------------------------------------------------------
sub getPropertyValue {
  my ($obj, $name) = @_;
  $obj->{manager}->getPropertyValue($obj, $name);
}
#-----------------------------------------------------------------------------
sub setPropertyValue {
  my ($obj, $name, $value) = @_;
  $obj->{manager}->setPropertyValue($obj->getId(), $name, $value);
}
#-----------------------------------------------------------------------------
sub deletePropertyValue {
  my ($obj, $name) = @_;
  $obj->{manager}->deletePropertyValue($obj->getId(), $name);
} 
# /properties
#-----------------------------------------------------------------------------
sub getKeywords {
  my ($obj) = @_;
  my @keywords = $context->getObjectsByIds( $obj->getKeywordIds() );
  return wantarray ? @keywords : \@keywords;
}
#-----------------------------------------------------------------------------
sub getKeywordsAsString {
  my ($obj) = @_;
  return join(",", map {$_->getFullName()} $obj->getKeywords());
}
#-----------------------------------------------------------------------------
sub addKeywordById {
  my ($obj, $id) = @_;
  my @kIds = $obj->getKeywordIds();
  my %kIds = map {$_ => 1} @kIds;
  push @kIds, $id unless $kIds{$id};
  $obj->setKeywordIds(@kIds);
}
#-----------------------------------------------------------------------------
sub delKeywordById {
  my ($obj, $id) = @_;
  my @kIds = $obj->getKeywordIds();
  my %kIds = map {$_ => 1} @kIds;
  if (delete $kIds{$id}) {
    @kIds = keys %kIds;
    $obj->setKeywordIds(@kIds);
  }
}
#-----------------------------------------------------------------------------
# returns true if this object may have child objects
sub isContainer {
  return 0;
}
#-----------------------------------------------------------------------------
# returns true if you may move this object to $toContainer
sub canMove {
  my ($obj, $fromContainer, $toContainer) = @_;
  return 0;
}
#-----------------------------------------------------------------------------
# called when object has moved to a new container
sub objectMoved {
  my ($obj, $fromContainer, $toContainer) = @_;
}
#-----------------------------------------------------------------------------
# must return true to allow $object to be placed in this container (applies only to container objects)
sub canAddObject {
  my ($obj, $fromContainer, $object) = @_;
  return 0;
}
#-----------------------------------------------------------------------------
sub canRemoveObject {
  my ($obj, $toContainer, $object) = @_;
  return 0;
}
#-----------------------------------------------------------------------------
# Override this method if you need to check something before saving
sub canSave {
  my ($obj, $errorMsgRef) = @_;
  return 1;
}
#-----------------------------------------------------------------------------
# When caching is on (Memcached), it looks like there's a problem with save calling save calling save etc when two objects
# have links to eachother. Haven't figured out why it happens, but checking for isSaving is a workaround for that.
sub save {
  my ($obj, %params) = @_;
  die sprintf "Can't call save on an object (ID: %d, className: %s) that's already in the process of being saved", $obj->getId(), $obj->getMetaClassName() if $obj->{isSaving};
  
  $obj->{isSaving} = 1;
  $obj->getManager()->save($obj, %params);
  $obj->{isSaving} = 0;
  return $obj;
}
#-----------------------------------------------------------------------------
sub delete {
  my ($obj) = @_;
  die "Object is not deletable!" unless $obj->isDeletable();
  
  $db->startTransaction();
  my $isOk = $obj->getManager()->deleteObject($obj);
  $db->endTransaction();
  return $isOk;
}
#-----------------------------------------------------------------------------
sub deletePermanently {
  my ($obj) = @_;
  $db->startTransaction();
  my $isOk = $obj->getManager()->deleteObjectPermanentlyById( $obj->getId() );
  $db->endTransaction();
  return $isOk;
}
#-----------------------------------------------------------------------------
sub isDeleted {
  my ($obj) = @_;
  return 1 if $obj->isTrashed();
  return $obj->getMetaStatus() eq 'deleted';
}
#-----------------------------------------------------------------------------
sub isTrashed {
  my ($obj) = @_;
  return $obj->getMetaStatus() =~ m{ \A (?: trashed | trashedAncestor ) \z }xms;
}
#-----------------------------------------------------------------------------
sub isDeletable {
  return 1;
}
#-----------------------------------------------------------------------------
sub isSearchable {
  my ($obj) = @_;
  return 0 if $obj->isDeleted();
  return 0 if $obj->getMetaStatus() =~ m{ \A (?: new | inactive ) \z }xms;
  return 1;
}
#-----------------------------------------------------------------------------
# returns 1 if object may be published at a specific url
sub isPublishable {
  my ($obj, $url) = @_;
  return 1;
}
#-----------------------------------------------------------------------------
sub getIndexableFields {
  return qw(metaName metaClassName);
}
#-----------------------------------------------------------------------------
sub serialize {
  my ($obj) = @_;
  die 'Object not serializable: ' . (ref $obj) unless $obj->isSerializable();
  return $context->getSingleton('O2::Data')->dump( $obj->getObjectPlds() );
}
#-----------------------------------------------------------------------------
sub toString {
  my ($obj) = @_;
  die 'Object not serializable: ' . (ref $obj) unless $obj->isSerializable();
  my $plds = $obj->getObjectPldsRecursive( $obj->getId() );
  my $string = $context->getSingleton('O2::Data')->dump($plds);
  $string    =~ s{ ^ ([ ]+) }{}xmsg;
  my @lines = split /\n/, $string;
  $string = '';
  my $indentLevel = 0;
  foreach my $line (@lines) {
    if ($line =~ m{ (?: [^\{[] | \A ) [\}\]] [;,]? \z }xms) {
      $indentLevel--;
    }
    $line = sprintf "%s$line", '    ' x $indentLevel;
    if ($line =~ m{ [\{[] \z }xms) {
      $indentLevel++;
    }
    $string .= "$line\n";
  }
  return $string;
}
#-----------------------------------------------------------------------------
sub getObjectPlds {
  my ($obj, $noRecursiveObjects) = @_;
  my $plds = {
    meta        =>   $obj->getMetaPlds(),
    data        =>   $obj->getContentPlds($noRecursiveObjects),
    keywordIds  => [ $obj->getKeywordIds() ],
    objectClass => ref $obj,
  };
  undef $plds->{currentLocale};
  return $plds;
}
#-----------------------------------------------------------------------------
sub getObjectPldsRecursive {
  my ($obj, @seenIds) = @_;
  my $plds = $obj->getObjectPlds();
  $plds->{data} = $obj->getContentPldsRecursive(@seenIds);
  return $plds;
}
#-----------------------------------------------------------------------------
sub setMetaPlds {
  my ($obj, $plds) = @_;
  $obj->setId(             $plds->{id}         );
  $obj->setMetaParentId(   $plds->{parentId}   );
  $obj->setMetaName(       $plds->{name}       );
  $obj->setMetaClassName(  $plds->{className}  );
  $obj->setMetaCreateTime( $plds->{createTime} );
  $obj->setMetaChangeTime( $plds->{changeTime} );
  $obj->setMetaStatus(     $plds->{status}, 1  );
  $obj->setMetaOwnerId(    $plds->{ownerId}    );
  return 1;
}
#-----------------------------------------------------------------------------
sub getMetaPlds {
  my ($obj) = @_;
  return {
    id         => $obj->getId(),
    parentId   => $obj->getMetaParentId(),
    name       => $obj->getMetaName(),
    className  => $obj->getMetaClassName(),
    createTime => $obj->getMetaCreateTime(),
    changeTime => $obj->getMetaChangeTime(),
    status     => $obj->getMetaStatus(),
    ownerId    => $obj->getMetaOwnerId(),
  };
}
#-----------------------------------------------------------------------------
sub getContentPlds {
  my ($obj, $noRecursiveObjects) = @_;
  
  my $plds = {};
  foreach my $field ($obj->getModel->getFields()) {
    my $fieldName = $field->getName();
    next if $fieldName eq 'id' || $fieldName eq 'keywordIds' || $fieldName =~ m{ \A meta [A-Z] }xms;
    
    if ($field->isMultilingual()) {
      foreach my $locale ($obj->getUsedLocales()) {
        $obj->setCurrentLocale($locale);
        $plds->{ $field->getName() }->{$locale} = $obj->getValueFromObjectByField($field, $noRecursiveObjects);
      }
    }
    else {
      $plds->{ $field->getName() } = $obj->getValueFromObjectByField($field, $noRecursiveObjects);
    }
  }
  return $plds;
}
#-----------------------------------------------------------------------------
sub getValueFromObjectByField {
  my ($obj, $field, $noRecursiveObjects) = @_;
  my $value = $obj->getModelValue( $field->getName() );
  if ($field->getListType() eq 'hash') {
    $value = $obj->getManager()->_fixHashValuesForSetter($field, $value);
  }
  elsif ($field->getListType() eq 'array') {
    $value = $obj->getManager()->_fixArrayValuesForSetter($field, $value);
  }
  else {
    $value = $context->getSingleton('O2::Mgr::DateTimeManager')->newObject($value)->dbFormat() if $value && $field->getType() eq 'date';
  }
  return $value;
}
#-----------------------------------------------------------------------------
sub getContentPldsRecursive {
  my ($obj, @seenIds) = @_;
  my $plds = $obj->getContentPlds();
  foreach my $fieldName (keys %{$plds}) {
    next if $fieldName =~ m{ \A _ }xms;
    my $field = $obj->getModel()->getFieldByName($fieldName);
    if ($field->isObjectType()) {
      if ($field->getListType() eq 'array') {
        my @values = @{ $plds->{$fieldName} || [] };
        $plds->{$fieldName} = [];
        foreach my $value (@values) {
          if (ref ($value) =~ m{ :: }xms && !$value->getId()) {
            push @{ $plds->{$fieldName} }, $value . '';
          }
          else {
            my $objectId = ref ($value) =~ m{ :: }xms  ?  $value->getId()  :  $value;
            if (!contains @seenIds, $objectId) {
              my $subPlds = $obj->_getSerializedSubObject($objectId, \@seenIds);
              push @{ $plds->{$fieldName} },  $subPlds if $subPlds;
            }
          }
        }
      }
      else {
        my $value = $plds->{$fieldName};
        my $objectId;
        if (ref ($value) =~ m{ :: }xms && !$value->getId()) {
          $plds->{$fieldName} = $value . '';
        }
        else {
          $objectId = ref ($value) =~ m{ :: }xms  ?  $value->getId()  :  $value;
        }
        if ($objectId && !contains @seenIds, $objectId) {
          my $subPlds = $obj->_getSerializedSubObject($objectId, \@seenIds);
          $plds->{$fieldName} = $subPlds if $subPlds;
        }
      }
    }
  }
  return $plds;
}
#-----------------------------------------------------------------------------
sub _getSerializedSubObject {
  my ($obj, $objectId, $seenIds) = @_;
  return unless $objectId;
  my $object = $context->getObjectById($objectId);
  return unless $object;
  upush @{$seenIds}, $objectId;
  my $objectPlds = $object->can('getObjectPldsRecursive')  ?  $object->getObjectPldsRecursive( @{$seenIds} )  :  $object->getObjectPlds();
  return { $objectId => $objectPlds };
}
#-----------------------------------------------------------------------------
sub setContentPlds {
  my ($obj, $plds) = @_;
  if ($obj->verifyContentPlds($plds)) {
    $obj->{data} = $plds;
  }
  else {
    die "ContentPLDS could not be verified: $@";
  }
}
#-----------------------------------------------------------------------------
sub verifyContentPlds {
  return 1;
}
#-----------------------------------------------------------------------------
sub getIconUrl {
  my ($obj, $size) = @_;
  my $iconMgr = $context->getSingleton('O2::Image::IconManager');
  return $iconMgr->getIconUrl( $obj->getMetaClassName(), $size || 16 );
}
#-----------------------------------------------------------------------------
# An object may be found at several urls, that's why I didn't just call the method getUrl
sub getDefaultUrl {
  my ($obj, %params) = @_;
  return $context->getSingleton('O2CMS::Publisher::UrlMapper')->generateUrl(
    object     => $obj,
    absolute   => $params{absolute} || 0,
    objectPath => $params{path}     || '',
  );
}
#-----------------------------------------------------------------------------
sub getOwner {
  my ($obj) = @_;
  my $ownerId = $obj->getMetaOwnerId();
  return unless $ownerId;
  return $context->getObjectById($ownerId);
}
#-----------------------------------------------------------------------------
sub getComments {
  my ($obj) = @_;
  return $context->getSingleton('O2::Mgr::CommentManager')->getCommentsFor( $obj->getId() );
}
#-----------------------------------------------------------------------------
sub setFromRequest {
  my ($obj, $objectStructure) = @_;
  $objectStructure ||= $cgi->getStructure('object');
  foreach my $fieldName (keys %{$objectStructure}) {
    my $originalFieldName = $fieldName;
    my $field = $obj->_getFieldByFieldName($fieldName);
    die "$originalFieldName is not a valid field" unless $field;

    my $value = $objectStructure->{$originalFieldName};
    if ($field->isObjectType() && $field->getListType() eq 'array' && @{$value} && ref $value->[0]) {
      $obj->_setRelatedObjectsFromRequest($field, $value);
    }
    elsif ($field->isObjectType() && $field->getListType() ne 'array' && ref $value) {
      $obj->_setRelatedObjectsFromRequest($field, [$value]);
    }
    else {
      my $setter = $field->isObjectType() ? $field->getIdSetAccessor() : $field->getSetAccessor();
      $obj->$setter( $field->getListType() eq 'array'  ?  @{$value}  :  $value );
    }
  }
}
#-----------------------------------------------------------------------------
sub _getFieldByFieldName {
  my ($obj, $fieldName, $model) = @_;
  $model ||= $obj->getModel();
  my $field = eval { $model->getFieldByName($fieldName) };
  if (!$field && $fieldName =~ m{ Ids? \z }xms) {
    $fieldName = $obj->getManager()->_removeIds($fieldName);
    $field = eval { $model->getFieldByName($fieldName) };
    if (!$field) {
      $fieldName =~ s{ Ids \z }{Id}xms;
      $field = $model->getFieldByName($fieldName);
    }
  }
  elsif (!$field) {
    $fieldName = $obj->getManager()->_removeIds($fieldName);
    $field = $model->getFieldByName($fieldName);
  }
  return $field;
}
#-----------------------------------------------------------------------------
sub _setRelatedObjectsFromRequest {
  my ($obj, $field, $value) = @_;
  my $universalMgr = $context->getUniversalMgr();
  my $idGetter = $field->getIdGetAccessor();
  my @oldIds = $obj->$idGetter();
  my @newObjects;
  my $mgr = $universalMgr->getManagerByClassName( $field->getType() );
  foreach my $struct ( @{$value} ) {
    my $object;
    $object   = $context->getObjectById( $struct->{objectId} ) if $struct->{objectId};
    $object ||= $mgr->newObject();
    while (my ($key, $val) = each %{$struct}) {
      next if $key eq 'objectId';
      my $subField = $obj->_getFieldByFieldName( $key, $object->getModel() );
      if ($subField->isObjectType() && ref $val) {
        $object->_setRelatedObjectsFromRequest( $subField, [$val] );
      }
      else {
        my $_setter = $subField->getSetAccessor();
        $object->$_setter($val);
      }
    }
    push  @newObjects, $object unless $object->getId();
    upush @newObjects, $object     if $object->getId();
  }
  my $setter = $field->isObjectType() ? $field->getObjectSetAccessor() : $field->getSetAccessor();
  $obj->$setter(@newObjects);
}
#-----------------------------------------------------------------------------
sub deprecated {
  my ($obj) = @_;
  if ($context->getSession()->get('debugEnabled')) {
    warn sprintf 'Called deprecated method %s in %s line %d. Stack trace: %s',
      [caller]->[3], [caller]->[0], [caller]->[2], $context->getConsole()->getStackTrace();
  }
}
#-----------------------------------------------------------------------------
# Return a reinstantiated version of the object
sub reinstantiate {
  my ($obj) = @_;
  $obj->getManager()->_uncacheForCurrentRequest( $obj->getId() );
  return $context->getObjectById( $obj->getId() );
}
#-----------------------------------------------------------------------------
# On which objects has this object been published
sub getPublishPlaces {
  my ($obj) = @_;
  my @rows = $db->fetchAll( "select objectId, slotId, templateId from O2CMS_OBJ_TEMPLATE_SLOT where contentId = ?", $obj->getId() );
  my @publishPlaces;
  foreach my $row (@rows) {
    my $object = $context->getObjectById( $row->{objectId} ) or next;
    push @publishPlaces, {
      object => $object,
      slotId => $row->{slotId},
    };
  }
  return @publishPlaces;
}
#-----------------------------------------------------------------------------
# Move object out of main database, store in parallel database
sub archive {
  my ($obj) = @_;
  $context->useArchiveDbh();
  $obj->save(archive => 1);
  $context->usePreviousDbh();
}
#-----------------------------------------------------------------------------
1;
