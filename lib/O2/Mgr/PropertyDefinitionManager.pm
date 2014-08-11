package O2::Mgr::PropertyDefinitionManager;

use strict;

use base 'O2::Mgr::ObjectManager';

use O2 qw($context $db);
use O2::Obj::PropertyDefinition;

#-----------------------------------------------------------------------------
sub initModel {
  my ($obj, $model) = @_;
  $obj->SUPER::initModel($model);
  $model->registerFields(
    'O2::Obj::PropertyDefinition',
    propertyName     => { type => 'varchar'                      }, # what property are we controlling with this definition
    description      => { type => 'text'                         }, # description of property
    inputType        => { type => 'varchar'                      }, # how user choose value for propery (input, textarea or select)
    rule             => { type => 'varchar'                      }, # html input rule
    ruleErrorMessage => { type => 'varchar'                      }, # error message when rule doesn't validate
    applyToClasses   => { type => 'varchar', listType => 'array' }, # not implemented: propery only visible/usable for a certain number of classes
    optionsType      => { type => 'varchar', length => 32        }, # if inputType=='select', this field controls where the options are read from static: options are kept as a plds in optionsData method: optionsData contains Perl::Package::andMethod to method that returns options o2ContainerPath: options are read from getChildren() on objectId in optionsData. See O2::Obj::PropertyDefinition::getOptions for details
    optionsData      => { type => 'text'                         }, # general storage
  );
}
#-----------------------------------------------------------------------------
# return definition for a property (if it exists)
sub getPropertyDefinitionByName {
  my ($obj, $propertyName) = @_;
  my ($propertyDefinition) = $obj->objectSearch(
    propertyName => $propertyName,
  );
  return $propertyDefinition;
}
#-----------------------------------------------------------------------------
# return definition for a property, or a default definition if not found
sub getPropertyDefinitionOrDefaultByName {
  my ($obj, $propertyName) = @_;
  
  my $definition = $obj->getPropertyDefinitionByName($propertyName);
  if (!$definition) {
    $definition = $obj->newObject();
    $definition->setMetaName(     $propertyName );
    $definition->setPropertyName( $propertyName );
    $definition->setInputType(    'input'       );
    $definition->setDescription(  ''            );
  }
  return $definition;
}
#-----------------------------------------------------------------------------
# returns property definitions.
# If $onlyForId is specified, only global (parentId=null) and definitions registered in parent containers are returned
sub getPropertyDefinitions {
  my ($obj, $onlyForId) = @_;
  
  my @placeholders;
  my $sql = 'select o.objectId from O2_OBJ_OBJECT o, O2_OBJ_PROPERTYDEFINITION pd where o.objectId = pd.objectId';
  
  if ($onlyForId) {
    @placeholders = ( $onlyForId, $context->getSingleton('O2::Mgr::MetaTreeManager')->getIdPathTo($onlyForId) );
    $sql .= ' and (o.parentId is null or o.parentId in ('. join (',', map "?", @placeholders) .'))';
  }
  my @ids = $db->selectColumn($sql, @placeholders);
  return $context->getObjectsByIds(@ids);
}
#-----------------------------------------------------------------------------
1;
