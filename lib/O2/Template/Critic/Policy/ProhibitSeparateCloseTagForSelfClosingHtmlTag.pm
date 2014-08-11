package O2::Template::Critic::Policy::ProhibitSeparateCloseTagForSelfClosingHtmlTag;

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
  return 1;
}
#-----------------------------------------------------------------------------
sub appliesTo {
  return qw( Node::HtmlTag );
}
#-----------------------------------------------------------------------------
sub violates {
  my ($obj, $element, $root) = @_;
  my $tagName = lc $element->getTagName();
  return if $tagName !~ m{ \A (?: br | hr | input | img | link | meta | param ) \z }xms;
  if ($element->getValue() =~ m{ </ $tagName > \z }xmsi) {
    my $desc = "Found separate closing tag (</$tagName>) for self-closing html tag <$tagName>, that's unnecessary";
    return $obj->violation($desc, $desc, $element);
  }
  return;
}
#-----------------------------------------------------------------------------
1;
