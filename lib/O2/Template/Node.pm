package O2::Template::Node;

use strict;

#-----------------------------------------------------------------------------
sub new {
  my ($package, $value) = @_;
  my $obj = bless {
    children   => [],
    parent     => undef,
    value      => $value,
  }, $package;
  return $obj;
}
#-----------------------------------------------------------------------------
sub getChildren {
  my ($obj) = @_;
  my @children;
  my @_children = @{ $obj->{children} };
  foreach my $child (@_children) {
    if (ref($child) eq 'O2::Template::Node::Anonymous') {
      push @children, $child->getChildren();
    }
    else {
      push @children, $child;
    }
  }
  return @children;
}
#-----------------------------------------------------------------------------
sub addChild {
  my ($obj, $node) = @_;
  push @{$obj->{children}}, $node;
  $node->setParent( $obj );
  return;
}
#-----------------------------------------------------------------------------
sub hasParent {
  my ($obj) = @_;
  return ref($obj) ne 'O2::Template::Node::Root';
}
#-----------------------------------------------------------------------------
sub getParent {
  my ($obj) = @_;
  return $obj->{parent}  if  ref( $obj->{parent} ) ne 'O2::Template::Node::Anonymous';
  return $obj->{parent}->getParent();
}
#-----------------------------------------------------------------------------
sub setParent {
  my ($obj, $node) = @_;
  $obj->{parent} = $node;
  return;
}
#-----------------------------------------------------------------------------
sub getPreviousSibling {
  my ($obj) = @_;
  return if ref($obj) eq 'O2::Template::Node::Root'; # Root has no siblings
  my @siblings = $obj->getParent()->getChildren();
  my $prev;
  foreach my $node (@siblings) {
    return $prev if $node eq $obj;
    $prev = $node;
  }
  return;
}
#-----------------------------------------------------------------------------
sub getValue {
  my ($obj) = @_;
  return $obj->{value};
}
#-----------------------------------------------------------------------------
sub setValue {
  my ($obj, $value) = @_;
  $obj->{value} = $value;
  return;
}
#-----------------------------------------------------------------------------
sub appendValue {
  my ($obj, $value) = @_;
  if ($obj->{value}) {
    $obj->{value} .= $value;
  }
  else {
    $obj->{value} = $value;
  }
  return;
}
#-----------------------------------------------------------------------------
sub getNextSibling {
  my ($obj) = @_;
  return if ref($obj) eq 'O2::Template::Node::Root'; # Root has no siblings
  my @siblings = $obj->getParent()->getChildren();
  my $current;
  foreach my $node (@siblings) {
    return $node if $current;
    $current = $node if $node eq $obj;
  }
  return;
}
#-----------------------------------------------------------------------------
sub getNextSignificantSibling {
  my ($obj) = @_;
  my $sibling = $obj->getNextSibling();
  while ($sibling) {
    return $sibling if $sibling->isSignificant();
    $sibling = $sibling->getNextSibling();
  }
  return;
}
#-----------------------------------------------------------------------------
sub getPreviousSignificantSibling {
  my ($obj) = @_;
  my $sibling = $obj->getPreviousSibling();
  while ($sibling) {
    return $sibling if $sibling->isSignificant();
    $sibling = $sibling->getPreviousSibling();
  }
  return;
}
#-----------------------------------------------------------------------------
sub getLocation {
  my ($obj) = @_;
  return ($obj->{line}, $obj->{column});
}
#-----------------------------------------------------------------------------
sub setLocation {
  my ($obj, $line, $column) = @_;
  $obj->{line}   = $line;
  $obj->{column} = $column;
  return 1;
}
#-----------------------------------------------------------------------------
sub toString {
  my ($obj, $indent) = @_;
  $indent ||= '';
  my $value = $obj->getValue();
  $value    =~ s{ \n }{\\n}xmsg;
  my $str = $indent .  ref($obj) . " $value\n";
  foreach my $child ($obj->getChildren()) {
    $str .= $child->toString("  $indent");
  }
  return $str;
}
#-----------------------------------------------------------------------------
sub isSignificant {
  return 1;
}
#-----------------------------------------------------------------------------
sub isWithinComment {
  my ($obj) = @_;
  my $node = $obj;
  while ($node->hasParent()) {
    my $parent = $node->getParent();
    return 1 if ref($parent) eq 'O2::Template::Node::O2Tag' && $parent->getTagName() eq 'comment';
    $node = $parent;
  }
  return 0;
}
#-----------------------------------------------------------------------------

1;
