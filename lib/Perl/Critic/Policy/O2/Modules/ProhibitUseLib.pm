package Perl::Critic::Policy::O2::Modules::ProhibitUseLib;

use strict;
use Readonly;

use Perl::Critic::Utils qw{ :severities :classification :ppi };
use base 'Perl::Critic::Policy';

Readonly::Scalar my $DESC => 'use lib';
Readonly::Scalar my $EXPL => "You shouldn't use 'use lib'";

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
  return $SEVERITY_HIGH;
}
#-----------------------------------------------------------------------------
sub default_themes {
  return qw( o2 );
}
#-----------------------------------------------------------------------------
sub applies_to {
  return 'PPI::Token::Word';
}
#-----------------------------------------------------------------------------
sub violates {
  my ($obj, $element, $document) = @_;
  return if $element ne 'use';
  my $sibling = $element->snext_sibling() or return;
  if ($sibling->content() eq 'lib') {
    return $obj->violation($DESC, $EXPL, $element);
  }
  return;
}
#-----------------------------------------------------------------------------
1;
