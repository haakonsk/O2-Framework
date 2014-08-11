package O2::Util::Serializer;

use strict;

use O2 qw($context);

#----------------------------------------------------
sub new {
  my ($pkg, %args) = @_;

  die "Handler must implement it's own constructor (new)" unless $pkg eq __PACKAGE__;

  my $handler = $args{format} || 'PLDS';
  $handler = __PACKAGE__."::$handler";
  eval "require $handler";
  my $serializer = new $handler();
  die "No serializer could be instantiated" unless $serializer;

  return $serializer;
}
#----------------------------------------------------
sub serialize {
  my ($obj, $object) = @_;
  die "Object is not serializable" unless $object->isSerializable();
  my $plds = $object->getObjectPlds();
  return $obj->freeze($plds);
}
#----------------------------------------------------
sub unserialize {
  my ($obj, $serializedObject) = @_;
  my $structure = $obj->thaw($serializedObject);
  die "Couldn't thaw serializedObject: $@"                                           if $@ || !ref $structure; # thaw doesn't raise an error, but sets $@..
  die "Couldn't thaw serializedObject: Didn't find objectClass in thawed object" unless $structure->{objectClass};

  my $universalMgr = $context->getUniversalMgr();
  my $object    = $universalMgr->newObjectByClassName(  $structure->{objectClass} );
  my $objectMgr = $universalMgr->getManagerByClassName( $structure->{objectClass} );

  if ($objectMgr->can('getObjectByPlds')) {
    $object = $objectMgr->getObjectByPlds($structure);
  }
  elsif ($structure->{meta}  &&  ref $structure->{meta} eq 'HASH') {
    return $universalMgr->getObjectByPlds($structure);
  }
  my $model = $object->getModel();

  foreach my $field ( $model->getFields() ) {
    if ( exists $structure->{objectData}->{ $field->getName() } ) {
      
      # If it's multilingual and not a hash it's technically not correct, but we let it pass anyway and set it as the default language
      if ( $field->getMultilingual() && ref $structure->{objectData}->{ $field->getName() } eq 'HASH' ) {
        foreach my $locale (keys %{ $structure->{objectData}->{ $field->getName() } } ) {
          next unless $object->isAvailableLocale($locale);
          $object->setCurrentLocale( $locale );
          $obj->setValueOnObjectByField( $object, $field, $structure->{objectData}->{ $field->getName() }->{ $locale } );
        }
      }
      else {
        $obj->setValueOnObjectByField( $object, $field, $structure->{objectData}->{ $field->getName() } );
      }
    }
  }
  $object->setCurrentLocale( $structure->{currentLocale} ) if $structure->{currentLocale};
  return $object; 
}
#----------------------------------------------------
sub setValueOnObjectByField {
  my ($obj, $object, $field, $value) = @_;
  my $accessor = 'set'.ucfirst( $field->getName() );
  if ($field->getListType() eq 'hash') {
    my %values = ();
    if (ref $value eq 'HASH') {
      %values = %{ $value };
    }
    $object->$accessor(%values);
  }
  elsif ($field->getListType() eq 'array') {
    my @values = ();
    if (ref $value eq 'ARRAY') {
      @values = @{ $value };
    }
    $object->$accessor( @values );
  }
  else {
    $object->$accessor( $value );
  }
}
#----------------------------------------------------
sub freeze {
  die "Abstract method - must be inherited by handler";
}
#----------------------------------------------------
sub thaw {
  die "Abstract method - must be inherited by handler";
}
#----------------------------------------------------
1;
