package Perl::Critic::Policy::O2::CodeLayout::RequireKRStyleBrackets;

use strict;
use Readonly;

use Perl::Critic::Utils qw{ :severities :classification :ppi };
use base 'Perl::Critic::Policy';

Readonly::Scalar my $DESC => 'Not K&R style brackets';
Readonly::Scalar my $EXPL => 'Use K%R style brackets. Must also have a space before the opening curly bracket.';

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
  return qw( PPI::Structure::Condition PPI::Structure::ForLoop PPI::Statement::Sub );
}
#-----------------------------------------------------------------------------
sub violates {
  my ($obj, $element, $document) = @_;
  if ($element->class() eq 'PPI::Structure::Condition' || $element->class() eq 'PPI::Structure::ForLoop') {
#    if ($element->previous_sibling()->content() !~ m{ \A [ ]* \z }xms) {
#      return $obj->violation($DESC, $EXPL, $element);
#    }
    return if $element->snext_sibling()->class() ne 'PPI::Structure::Block';
    if ($element->next_sibling()->content() !~ m{ \A [ ]+ \z }xms) {
      return $obj->violation($DESC, $EXPL, $element);
    }
    return;
  }
  if ($element->class() eq 'PPI::Statement::Sub') {
    my $methodNameNode = $element->first_token()->snext_sibling();
    if ($methodNameNode->next_sibling() !~ m{ \A [ ]+ \z }xms) {
      return $obj->violation($DESC, $EXPL, $element);
    }
    return;
  }
  return;
}
#-----------------------------------------------------------------------------

1;
