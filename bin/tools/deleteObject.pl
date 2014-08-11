#!/usr/bin/env perl

# Quick script for deleting one or more o2 objects
# Feel free to change and enhance it

die "Usage $0 [-f] objectId [objectId objectId..objectId]\n" unless @ARGV;

use O2::Context;
my $context = O2::Context->new();
die "Could not create O2::Context. Probably need to use o2Shell to set up environment variables\n" unless $context;

my @objectIds = ();
my $force     = undef;
my $canForce  = 1;

foreach my $objectId (@ARGV) {
  if ($objectId eq '-f') {
    $force = 1;
  }
  elsif ( $objectId =~ m/^\d+$/) {
    push @objectIds, $objectId;
  }
  elsif ( $objectId =~ m/^(\d+)\.\.(\d+)$/ && $1 < $2) {
    push @objectIds, ($1 .. $2);
    $canForce = 0;
  }
  else {
    die "Not a valid ID $objectId\n";
  }
}

if ($force && !$canForce) {
  print "\n\n*** Force can not be used while using ranges (..) ***\n\n";
  $force = undef;
}

unless ($force) {
  print "Object(s) for deletion: ",join(", ", @objectIds),"\n\nDelete? (y/N): ";
  require Term::ReadKey;

  my ($ans) = Term::ReadKey::ReadLine();
  exit unless $ans =~ m/y/i;
}

print "Deleting objects:\n";
foreach my $objectId ( @objectIds ) {
  print "  $objectId ";
  my $object = $context->getObjectById( $objectId );
  if ( $object ) {
    if ( $object->can( 'deletePermanently' ) ) {
      $object->deletePermanently();
      print "deleted permanently.";
    }
    else {
      $object->delete();
      print "deleted.";
    }
  }
  else {
    print " not found"
  }
  print "\n";
}
print "Done";
