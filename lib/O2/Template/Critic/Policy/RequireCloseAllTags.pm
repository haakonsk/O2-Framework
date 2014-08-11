package O2::Template::Critic::Policy::RequireCloseAllTags;

use strict;
use Readonly;

use base 'O2::Template::Critic::Policy';

Readonly::Scalar my $DESC => 'Found unclosed tag';
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
  return 5;
}
#-----------------------------------------------------------------------------
sub appliesTo {
  return qw( Node::HtmlTag );
}
#-----------------------------------------------------------------------------
sub violates {
  my ($obj, $element, $root) = @_;
  my $tagName = lc $element->getTagName();
  return if $tagName =~ m{ \A (?: br | hr | input | img | link | meta | param ) \z }xms;
  if ($element->getValue() !~ m{ </ $tagName > \z }xmsi && $element->getValue() !~ m{ /> \z }xms) {
    my $desc = "$DESC ($tagName)";
    return $obj->violation($desc, $desc, $element);
  }
  return;
}
#-----------------------------------------------------------------------------
1;
