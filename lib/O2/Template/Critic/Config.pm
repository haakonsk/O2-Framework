package O2::Template::Critic::Config;

use strict;

use O2 qw($context);

#-----------------------------------------------------------------------------
sub new {
  my ($package, $configFile) = @_;
  my $obj = bless {
    severity          => undef,
    updatedSeverities => {}, # Per policy
    disabledPolicies  => {},
  }, $package;

  my @lines = $context->getSingleton('O2::File')->getFile($configFile);
  my $currentPolicy;
  foreach my $line (@lines) {
    if (my ($severity) = $line =~ m{ \A \s* severity \s* = \s* (\d) \s* \z }xms) {
      if ($currentPolicy) {
        $obj->{updatedSeverities}->{$currentPolicy} = $severity;
      }
      else {
        $obj->{severity} = $severity;
      }
    }
    elsif (my ($disableIt, $policy) = $line =~ m{ \A \s* \[ (-?) ([^\]]+) \] \s* \z }xms) {
      $currentPolicy = $policy;
      $obj->{disabledPolicies}->{$policy} = 1 if $disableIt;
    }
  }
  return $obj;
}
#-----------------------------------------------------------------------------
sub getSeverity {
  my ($obj) = @_;
  return $obj->{severity};
}
#-----------------------------------------------------------------------------
sub policyIsDiabled {
  my ($obj, $policyObject) = @_;
  my ($policyName) = ref ($policyObject) =~ m{ :: ([^:]+) \z }xms;
  return $obj->{disabledPolicies}->{$policyName} ? 1 : 0;
}
#-----------------------------------------------------------------------------
sub getSeverityByPolicy {
  my ($obj, $policyObject) = @_;
  my ($policyName) = ref ($policyObject) =~ m{ :: ([^:]+) \z }xms;
  return $obj->{updatedSeverities}->{$policyName};
}
#-----------------------------------------------------------------------------
1;
