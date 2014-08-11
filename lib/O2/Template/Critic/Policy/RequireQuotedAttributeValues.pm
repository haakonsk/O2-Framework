package O2::Template::Critic::Policy::RequireQuotedAttributeValues;

use strict;
use Readonly;

use base 'O2::Template::Critic::Policy';

Readonly::Scalar my $DESC => 'Missing double or single quote around attribute value';
Readonly::Scalar my $EXPL => 'Missing double or single quote around attribute value';

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
  return 2;
}
#-----------------------------------------------------------------------------
sub appliesTo {
  return qw( Node::AttributeValue );
}
#-----------------------------------------------------------------------------
sub violates {
  my ($obj, $element, $root) = @_;
  my $previousSibling = $element->getPreviousSibling();
  my $firstCharacter = substr($element->getValue(), 0, 1);
  if ($firstCharacter ne '"' && $firstCharacter ne "'" && $previousSibling && $previousSibling->getValue() eq '=') {
    return $obj->violation($DESC, $EXPL, $element);
  }
  return;
}
#-----------------------------------------------------------------------------
1;
