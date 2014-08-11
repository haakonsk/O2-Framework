package O2::Template::Node::Tag;

use strict;

use base 'O2::Template::Node';

#-----------------------------------------------------------------------------
sub getTagName {
  my ($obj) = @_;
  my ($tagName) = $obj->getValue() =~ m{ < (?:o2\s+)? (\w+) }xms;
  return $tagName || '';
}
#-----------------------------------------------------------------------------
sub getChildrenByTagName {
  my ($obj, $tagName, $nodeType) = @_;
  my @children;
  foreach my $child ($obj->getChildren()) {
    next if !$child->isa('O2::Template::Node::Tag');
    if (lc($child->getTagName())  eq  lc($tagName)) {
      if (!$nodeType || ref($child) eq "O2::Template::Node::$nodeType") {
        push @children, $child;
      }
      else {
        push @children, $child->getChildrenByTagName($tagName, $nodeType);
      }
    }
  }
  return @children;
}
#-----------------------------------------------------------------------------
sub getAttributes {
  my ($obj) = @_;
  my @children;
  foreach my $child ($obj->getChildren()) {
    push @children, $child if ref($child) eq 'O2::Template::Node::Attribute';
  }
  return @children;
}
#-----------------------------------------------------------------------------

1;
