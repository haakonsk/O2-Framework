package O2::Template::Critic::Violation;

use strict;

#-----------------------------------------------------------------------------
sub new {
  my ($package, $description, $explanation, $element, $line, $column) = @_;
  my $obj = bless {
    description => $description,
    explanation => $explanation,
    element     => $element,
    policy      => caller (1) || undef,
  }, $package;
  $obj->{line}   = $line;
  $obj->{column} = $column;
  return $obj;
}
#-----------------------------------------------------------------------------
sub toString {
  my ($obj) = @_;
  my $policy = $obj->getPolicy();
  $policy    =~ s{ \A O2::Template::Critic::Policy:: }{}xms;
  my ($line, $column);
  if ($obj->{line}) {
    $line = "at line $obj->{line}, column $obj->{column}";
  }
  else {
    ($line, $column) = $obj->{element}->getLocation();
    $line = "at line $line";
  }
  return "[$policy] $obj->{description}, $line. (Severity $obj->{severity})";
}
#-----------------------------------------------------------------------------
sub getDescription {
  my ($obj) = @_;
  return $obj->{description};
}
#-----------------------------------------------------------------------------
sub getExplanation {
  my ($obj) = @_;
  return $obj->{explanation};
}
#-----------------------------------------------------------------------------
sub getLocation {
  my ($obj) = @_;
  return ($obj->{line}, $obj->{column}) if $obj->{line};
  return $obj->{element}->getLocation();
}
#-----------------------------------------------------------------------------
sub getLine {
  my ($obj) = @_;
  my ($line, $column) = $obj->getLocation();
  return $line;
}
#-----------------------------------------------------------------------------
sub getColumn {
  my ($obj) = @_;
  my ($line, $column) = $obj->getLocation();
  return $column;
}
#-----------------------------------------------------------------------------
sub setSeverity {
  my ($obj, $severity) = @_;
  $obj->{severity} = $severity;
}
#-----------------------------------------------------------------------------
sub getSeverity {
  my ($obj) = @_;
  return $obj->{severity};
}
#-----------------------------------------------------------------------------
sub sortBySeverity {
  my (@violations) = @_;
  return sort { $a->getSeverity() <=> $b->getSeverity() || $a->getLine() <=> $b->getLine() } @violations;
}
#-----------------------------------------------------------------------------
sub sortByLocation {
  my (@violations) = @_;
  return sort { $a->getLine() <=> $b->getLine() || $a->getColumn() <=> $b->getColumn() } @violations;
}
#-----------------------------------------------------------------------------
sub getPolicy {
  my ($obj) = @_;
  return $obj->{policy};
}
#-----------------------------------------------------------------------------
1;
