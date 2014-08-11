package O2::Template::Critic::Policy::ProhibitTagInsideOpeningTag;

use strict;
use Readonly;

use base 'O2::Template::Critic::Policy';

Readonly::Scalar my $DESC => 'Found an o2 tag inside an opening tag';
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
  return 4;
}
#-----------------------------------------------------------------------------
sub appliesTo {
  return qw( Node::O2TagInsideOpeningTag );
}
#-----------------------------------------------------------------------------
sub violates {
  my ($obj, $element, $root) = @_;
  my $parent = $element->getParent();
  return $obj->violation($DESC, $EXPL, $element) if $parent->isa('O2::Template::Node::Attribute') || $parent->isa('O2::Template::Node::AttributeValue');
}
#-----------------------------------------------------------------------------
1;
