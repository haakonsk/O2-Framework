package O2::Util::AccessorMapper;

use strict;

#--------------------------------------------------------------------------------------#
sub new {
  my ($pkg) = @_;
  my $obj = bless {}, $pkg;
}
#--------------------------------------------------------------------------------------#
sub setAccessors {
  my ($obj, $object, %attribs) = @_;
  foreach my $attribute (keys %attribs) {
    my $method = $object->can($attribute) ? $attribute : 'set' . ucfirst $attribute;
    die "No such method $method" unless $object->can($method);
    
    my @values;
    if (ref $attribs{$attribute} eq 'ARRAY' ) {
      @values = @{ $attribs{$attribute} };
    }
    elsif (ref $attribs{$attribute} eq 'HASH' ) {
      @values = %{ $attribs{$attribute} };
    }
    else {
      @values = ( $attribs{$attribute} );
    }
    $object->$method(@values);
  }
  return $object;
}
#--------------------------------------------------------------------------------------#
sub getAccessors {
  my ($obj, $object, %attribs) = @_;
  my %values = ();
  foreach my $attribute (keys %attribs) {
    my $method = $object->can($attribute) ? $attribute : 'get' . ucfirst $attribute;
    die "No such method $method" unless $object->can($method);
    my @values = $object->$method();

    if (lc ($attribs{$attribute}) eq 'scalar') { # Must return as scalar
      $values{$attribute} = $values[0];
    }
    elsif (lc ($attribs{$attribute}) eq 'array') { # Must return as array
      $values{$attribute} = [ @values ];
    }
    elsif (lc ($attribs{$attribute}) eq 'hash') { # Must return as hash
      die "No valid-hash returned for accessor '$attribute'" . scalar @values if @values >= 0 && @values % 2; # Must be hash-compatible
      $values{$attribute} = { @values };
    }
  }
  return %values;
}
#--------------------------------------------------------------------------------------#
sub objectToHash {
  my ($obj, $object, %attribs) = @_;
  return unless $object;
  my %hash = (
    value       => $object->getId(),
    id          => $object->getId(),
    name        => $object->getMetaName(),
    className   => $object->getMetaClassName(),
    parentId    => $object->getMetaParentId(),
    isContainer => $object->isContainer(),
  );
  foreach my $fieldName (keys %attribs) {
    my $dataType = $attribs{$fieldName};

    eval {
      my $method = $object->can($fieldName) ? $fieldName : 'get' . ucfirst $fieldName;
      my @result = $object->$method();
      if ($dataType eq 'array') {
        @result = map { (ref $_) =~ m/::Obj::/ ? { $obj->objectToHash($_) } : $_ } @result;
        $hash{$fieldName} = \@result;
      }
      elsif ($dataType eq 'hash') {
        $hash{$fieldName} = { @result };
      }
      else {
        $hash{$fieldName} = $result[0];
      }
    };
  }
  return %hash;
}
#--------------------------------------------------------------------------------------#
1;
