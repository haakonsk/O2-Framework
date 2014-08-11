package O2::Mgr::PropertyManager::Property;

use strict;

use O2 qw($context);

#-----------------------------------------------------------------------------
sub new {
  my ($pkg, %init) = @_;
  return bless \%init, $pkg;
}
#-----------------------------------------------------------------------------
sub setObjectId {
  my ($obj, $objectId) = @_;
  $obj->{objectId} = $objectId;
}
#-----------------------------------------------------------------------------
sub getObjectId {
  my ($obj) = @_;
  return $obj->{objectId};
}
#-----------------------------------------------------------------------------
sub setName {
  my ($obj, $name) = @_;
  $obj->{name} = $name;
}
#-----------------------------------------------------------------------------
sub getName {
  my ($obj) = @_;
  return $obj->{name};
}
#-----------------------------------------------------------------------------
sub setValue {
  my ($obj, $value) = @_;
  $obj->{value} = $value;
}
#-----------------------------------------------------------------------------
sub getValue {
  my ($obj) = @_;
  return $obj->{value};
}
#-----------------------------------------------------------------------------
sub setOriginatorId {
  my ($obj, $originatorId) = @_;
  $obj->{data}->{originatorId} = $originatorId;
}
#-----------------------------------------------------------------------------
# returns id of object where property was defined
sub getOriginatorId {
  my ($obj) = @_;
  return $obj->{data}->{originatorId};
}
#-----------------------------------------------------------------------------
# returns true if property is inherited from a different object
sub isInherited {
  my ($obj) = @_;
  return $obj->getOriginatorId() > 0  &&  $obj->getOriginatorId() != $obj->getObjectId();
}
#-----------------------------------------------------------------------------
sub isSet {
  my ($obj) = @_;
  return $obj->getOriginatorId() > 0;
}
#-----------------------------------------------------------------------------
sub getDefinition {
  my ($obj) = @_;
  my $propertyDefinitionMgr = $context->getSingleton('O2::Mgr::PropertyDefinitionManager');
  return $propertyDefinitionMgr->getPropertyDefinitionOrDefaultByName( $obj->getName() );
}
#-----------------------------------------------------------------------------
# returns description of value, or value itself if no description is available
sub getHumanReadableValue {
  my ($obj) = @_;
  my $definition = $obj->getDefinition();
  return $obj->getValue() unless $definition->getInputType() eq 'select';
  
  # return name of value corresponding to value
  foreach my $option ( $definition->getOptions() ) {
    return $option->{name} if $option->{value} eq $obj->getValue();
  }
  return $obj->getValue(); # value was not among the options. should maybe die? (but let undefined values pass through)
}
#-----------------------------------------------------------------------------
sub save {
  my ($obj) = @_;
  $obj->{manager}->setPropertyValue( $obj->getObjectId(), $obj->getName(), $obj->getValue() );
}
#-----------------------------------------------------------------------------
1;
