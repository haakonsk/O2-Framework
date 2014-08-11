package Perl::Critic::Policy::O2::CodeLayout::RequireSpaceAroundControlKeywords;

use strict;
use Readonly;

use Perl::Critic::Utils qw{ :severities :classification :ppi };
use base 'Perl::Critic::Policy';

Readonly::Scalar my $DESC => 'Missing space around control keyword';
Readonly::Scalar my $EXPL => 'Separate your control keywords from the following opening bracket';

#-----------------------------------------------------------------------------
sub new {
  my ($package, %config) = @_;
  my $obj = bless {}, $package;
  return $obj;
}
#-----------------------------------------------------------------------------
sub supported_parameters {
  return ();
}
#-----------------------------------------------------------------------------
sub default_severity {
  return $SEVERITY_LOWEST;
}
#-----------------------------------------------------------------------------
sub default_themes {
  return qw( o2 );
}
#-----------------------------------------------------------------------------
sub applies_to {
  return qw( PPI::Token::Word );
}
#-----------------------------------------------------------------------------
sub violates {
  my ($obj, $element, $document) = @_;
  return if $element->content() !~ m{ \A (?: if | elsif | else | while | do | until | for | foreach ) \z }xms;
  return if $element->content() =~ m{ do \z }xms  &&  $element->next_sibling()  &&  $element->next_sibling() =~ m{ \( }xms; # This is probably a method call, which is ok.
  if ($element->next_sibling() && $element->next_sibling()->content() !~ m{ \A [ ]+ \z }xms) {
    return $obj->violation($DESC, $EXPL, $element);
  }
  if ($element->content() =~ m{ \A (?: elsif | else ) \z }xms) {
    my $previousNode = $element->previous_sibling();
    if ($previousNode && $previousNode->class() ne 'PPI::Token::Whitespace') {
      return $obj->violation($DESC, $EXPL, $element);
    }
    # XXX This should actually be handled by O2::CodeLayout::RequireKRStyleBrackets
    if ($previousNode && $previousNode->content() !~ m{\n}ms && $previousNode->previous_sibling()->class() ne 'PPI::Token::Whitespace' && $previousNode->previous_sibling()->content() !~ m{ \A [ ]+ \z }xms) {
      return $obj->violation($DESC, $EXPL, $element);
    }
  }
  return;
}
#-----------------------------------------------------------------------------

1;
