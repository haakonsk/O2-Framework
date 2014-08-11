package O2::Obj::PropertyDefinition;

use strict;

use base 'O2::Obj::Object';

use O2 qw($context);

#-------------------------------------------------------------------------------
sub getOptions {
  my ($obj, %params) = @_;
  
  if ($obj->getOptionsType() eq 'static') {
#    no strict;
    my $options = eval $obj->getOptionsData();
    die $@ if $@;
    return @{$options};
  }
  elsif ($obj->getOptionsType() eq 'method') {
    my ($className, $method) = $obj->getOptionsData() =~ m/(.*)::(\w+)$/;
    return $context->getSingleton($className)->$method($obj, %params);
  }
  elsif ($obj->getOptionsType() eq 'o2ContainerPath') {
    my ($container) = $context->getSingleton('O2::Mgr::MetaTreeManager')->getObjectByPath( $obj->getOptionsData() );
    die 'optionsData (' . $obj->getOptionsData() . ') is not a valid O2 path'               unless $container;
    die 'optionsData (' . $obj->getOptionsData() . ') does not point to a container object' unless $container->can('getChildren');
    return map { { name => $_->getMetaName(), value => $_->getId() } } $container->getChildren();
  }
  
  die "unknown optionsType: " . $obj->getOptionsType();
}
#-------------------------------------------------------------------------------
1;
