package O2::Template::Critic::Policy::ProhibitNestedTables;

use strict;
use Readonly;

use base 'O2::Template::Critic::Policy';

Readonly::Scalar my $DESC => 'Found table within table';
Readonly::Scalar my $EXPL => $DESC;

#-----------------------------------------------------------------------------
sub new {
  my ($package, %config) = @_;
  my $obj = bless {}, $package;
  return $obj;
}
#-----------------------------------------------------------------------------
sub getSupportedParameters {
  return ();
}
#-----------------------------------------------------------------------------
sub getDefaultSeverity {
  return 3;
}
#-----------------------------------------------------------------------------
sub appliesTo {
  return qw( Node::HtmlTag );
}
#-----------------------------------------------------------------------------
sub violates {
  my ($obj, $element, $root) = @_;
  my $tagName = $element->getTagName();
  return if lc($tagName) ne 'table';
  my $node = $element;
  while ($node->hasParent()) {
    my $parent = $node->getParent();
    return $obj->violation($DESC, $DESC, $element) if ref($parent) eq 'O2::Template::Node::HtmlTag' && lc($parent->getTagName()) eq 'table';
    $node = $parent;
  }
  return;
}
#-----------------------------------------------------------------------------
1;
