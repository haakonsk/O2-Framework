package O2::Template::Critic::Policy::ProhibitAllCapitalLettersInTagName;

use strict;
use Readonly;

use base 'O2::Template::Critic::Policy';

Readonly::Scalar my $DESC => 'Found a tag name with all capital letters';
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
  return $obj->violation($DESC, $EXPL, $element) if uc($tagName) eq $tagName;
  return;
}
#-----------------------------------------------------------------------------
1;
