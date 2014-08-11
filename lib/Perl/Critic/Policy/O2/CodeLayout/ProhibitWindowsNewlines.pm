package Perl::Critic::Policy::O2::CodeLayout::ProhibitWindowsNewlines;

use strict;
use Readonly;

use Perl::Critic::Utils qw{ :severities :classification :ppi };
use base 'Perl::Critic::Policy';

Readonly::Scalar my $DESC => 'Windows newlines found';
Readonly::Scalar my $EXPL => 'Use unix newlines instead of windows newlines';

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
  return 'PPI::Document';
}
#-----------------------------------------------------------------------------
sub violates {
  my ($obj, $element, $document) = @_;
  if ($document->ppi_document() =~ m{\r}ms) {
    return $obj->violation($DESC, $EXPL, $element);
  }
  return;
}
#-----------------------------------------------------------------------------

1;
