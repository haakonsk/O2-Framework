package O2::Template::Node::Attribute;

use strict;

use base 'O2::Template::Node';

#-----------------------------------------------------------------------------
sub getAttributeKey {
  my ($obj) = @_;
  return $obj if ref($obj) eq 'O2::Template::Node::AttributeKey';
  foreach my $child ($obj->getChildren()) {
    return $child->getValue()        if ref($child) eq 'O2::Template::Node::AttributeKey';
    return $child->getAttributeKey() if ref($child) eq 'O2::Template::Node::Attribute';
  }
  return '';
}
#-----------------------------------------------------------------------------
sub getAttributeValue {
  my ($obj) = @_;
  return $obj if ref($obj) eq 'O2::Template::Node::AttributeValue';
  foreach my $child ($obj->getChildren()) {
    if (ref($child) eq 'O2::Template::Node::AttributeValue') {
      my $value = $child->getValue();
      $value    =~ s{ \A [\"\'] (.*) [\"\'] \z }{$1}xms; # Stripping away the quotes
      return $value;
    }
    return $child->getAttributeValue() if ref($child) eq 'O2::Template::Node::Attribute';
  }
  return '';
}
#-----------------------------------------------------------------------------
sub getTag {
  my ($obj) = @_;
  my $node = $obj;
  while ($node->hasParent()) {
    my $parent = $node->getParent();
    return $parent if ref($parent) =~ m{ \A O2::Template::Node:: (?:Html|O2) Tag \z }xms;
    $node = $parent;
  }
  die "Didn't find corresonding tag for attribute " . $obj->getValue();
}
#-----------------------------------------------------------------------------

1;
