#!/usr/bin/env perl

die "Usage: $0 objectId\n" unless $ARGV[0];

use O2::Context;
my $ctx = O2::Context->new();

my $object = $ctx->getObjectById( $ARGV[0] );

die "Object cannot be seriazlized" unless $object->isSerializable();

my $serializedObj = $object->getObjectPlds();

print "This is a/n ".ref $object," object with ID $ARGV[0]\n";
print "=" x 70, "\n";

#use Data::Dumper;
#print Dumper( $serializedObj );

for my $heading ( qw/data meta/ ) {
    print $heading,"\n";
    print "-" x 70, "\n";
    foreach my $key ( keys %{$serializedObj->{$heading}} )  {
        printf "%-25s : %s\n", $key, $serializedObj->{$heading}->{$key};
    }
    print "\n";
}
