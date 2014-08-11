package O2::Template::Critic::Policy::ProhibitSingleCellTable;

use strict;
use Readonly;

use base 'O2::Template::Critic::Policy';

Readonly::Scalar my $DESC => 'Found a table with just one cell';
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
  return if lc($element->getTagName()) ne 'table';
  my @tags = $element->getChildrenByTagName('tr', 'HtmlTag');
  return if scalar(@tags) != 1;
  @tags = $tags[0]->getChildrenByTagName('td', 'HtmlTag');
  return if @tags != 1;
  return $obj->violation($DESC, $EXPL, $element);
}
#-----------------------------------------------------------------------------
1;
