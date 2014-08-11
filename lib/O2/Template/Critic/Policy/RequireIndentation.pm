package O2::Template::Critic::Policy::RequireIndentation;

use strict;

use base 'O2::Template::Critic::Policy';

use Readonly;
Readonly::Scalar my $DESC => 'Incorrect indentation of tag';
Readonly::Scalar my $EXPL => 'Incorrect indentation of tag';

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
  return qw( Node::Tag );
}
#-----------------------------------------------------------------------------
sub violates {
  my ($obj, $element, $root) = @_;
  my $depth = 0;
  my $node = $element->getParent();
  while (ref($node) ne 'O2::Template::Node::Root') {
    $depth++ if ref($node) eq 'O2::Template::Node::HtmlTag' || ref($node) eq 'O2::Template::Node::O2Tag';
    $node = $node->getParent();
  }
  my $previousSibling = $element->getPreviousSibling();
  return if !$previousSibling || ref($previousSibling) ne 'O2::Template::Node::Blanks' || $previousSibling->getValue() !~ m{ \n }xms;
  my ($indent) = $previousSibling->getValue() =~ m{ (?: \A | [^ ] )    ([ ]*)  \z }xms;
  return $obj->violation($DESC . ', expected ' . (2*$depth) . ' spaces, tag is ' . $element->getTagName(), $EXPL, $element) if 2*$depth != length $indent;
  return;
}
#-----------------------------------------------------------------------------
1;
