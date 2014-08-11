#!/usr/bin/env perl

use strict;
use warnings;

if ($ARGV{-objectid} !~ m/^\d+$/ || $ARGV{-help} || $ARGV{help} || $ARGV{-h} || $ARGV{h}) {
  print "Usage: $0 --objectid xxxx [--name 'abc']\n";
  exit;
}

use O2::Util::Args::Simple;

use O2 qw($context);

my $object = $context->getObjectById( $ARGV{-objectid} );

if ( $object && $object->isa('O2::Obj::Object') ) {
  print "Object '", $object->getMetaName(), "' (", $object->getId(), ") is now copied to '";
  $object->setId(undef);
  my $newName = $ARGV{-newname} || '(Copy of) '.$object->getMetaName();
  $object->setMetaName($newName);
  $object->save();
  print $object->getMetaName(), "' (", $object->getId(), ")\n";
}
else {
  print "* Could not find object with ID $ARGV{-objectid}\n";
}
