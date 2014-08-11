package O2::Template::Critic;

use strict;

use Module::Pluggable
  sub_name    => 'policies', # So we can find all policies with the "policies" method
  search_path => ['O2::Template::Critic::Policy'],
  instantiate => 'new';

#-----------------------------------------------------------------------------
sub new {
  my ($package, %params) = @_;
  my $obj = bless {}, $package;
  require O2::Template::TreeParser;
  $obj->{parser} = O2::Template::TreeParser->new();
  require O2::Template::Critic::Config;
  $obj->{config} = O2::Template::Critic::Config->new( $params{profile} );
  $obj->{minSeverity} = $params{severity} || $obj->getConfig()->getSeverity();
  return $obj;
}
#-----------------------------------------------------------------------------
sub critique {
  my ($obj, $file) = @_;
  my $tree = $obj->{parser}->templateToNodeTree($file);
#  print $tree->toString();
  my @violations = $obj->_runPolicyTests($tree, $tree);
#  use Data::Dumper; print Dumper(\%nodeTypeToPolicy);
  return @violations;
}
#-----------------------------------------------------------------------------
sub _getNodeTypeToPolicy {
  my ($obj) = @_;
  if (!$obj->{nodeTypeToPolicy}) {
    my @policies = $obj->policies();
    my %nodeTypeToPolicy;
    foreach my $policy (@policies) {
      next if        $obj->getConfig()->policyIsDiabled(     $policy );
      my $severity = $obj->getConfig()->getSeverityByPolicy( $policy ) || $policy->getDefaultSeverity();
      $policy->setSeverity($severity);
      my @appliesTo = $policy->appliesTo();
      foreach my $nodeType (@appliesTo) {
        $nodeType = "O2::Template::$nodeType";
        push @{ $nodeTypeToPolicy{$nodeType} }, $policy;
      }
    }
    $obj->{nodeTypeToPolicy} = \%nodeTypeToPolicy;
  }
  return $obj->{nodeTypeToPolicy};
}
#-----------------------------------------------------------------------------
sub _runPolicyTests {
  my ($obj, $currentNode, $tree) = @_;
  return if $currentNode->isWithinComment();
  my $nodeTypeToPolicy = $obj->_getNodeTypeToPolicy();
  my @violations;
  if ( my $policies = $nodeTypeToPolicy->{ ref $currentNode } ) {
    foreach my $policy (@{$policies}) {
      next if $policy->getSeverity() < $obj->{minSeverity};
      my $violations = $policy->violates($currentNode, $tree);
      if ($violations && ref($violations) eq 'ARRAY') {
        foreach my $violation (@{ $violations }) {
          $violation->setSeverity( $policy->getSeverity() );
          push @violations, $violation;
        }
      }
      elsif ($violations) {
        my $violation = $violations;
        die ref($policy) . ' returned object of other type than O2::Template::Critic::Violation (' . ref($violation) . ')' if ref($violation) ne 'O2::Template::Critic::Violation';
        if ($violation) {
          $violation->setSeverity( $policy->getSeverity() );
          push @violations, $violation;
        }
      }
    }
  }
  foreach my $node ( $currentNode->getChildren() ) {
    push @violations, $obj->_runPolicyTests($node, $tree, $nodeTypeToPolicy);
  }
  foreach my $violation (@violations) {
    die ref $violation if ref($violation) ne 'O2::Template::Critic::Violation';
  }
  return @violations;
}
#-----------------------------------------------------------------------------
sub getConfig {
  my ($obj) = @_;
  return $obj->{config};
}
#-----------------------------------------------------------------------------

1;
