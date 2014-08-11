package O2::Template::Critic::Policy::ProhibitSelfClosingHtmlTag;

use strict;
use Readonly;

use base 'O2::Template::Critic::Policy';

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
  return 5;
}
#-----------------------------------------------------------------------------
sub appliesTo {
  return qw( Node::HtmlTag );
}
#-----------------------------------------------------------------------------
sub violates {
  my ($obj, $element, $root) = @_;
  if ($element->getValue() =~ m{ /> \z }xms) {
    my $desc = 'Found self closing html tag (' . $element->getValue() . ')';
    return $obj->violation($desc, $desc, $element);
  }
  return;
}
#-----------------------------------------------------------------------------
1;
