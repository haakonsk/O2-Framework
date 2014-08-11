use strict;

use O2::Script::Common;

use O2::Context;
my $context = O2::Context->new();

my $id = $ARGV[0];
if (!$id || $id != int $id) {
  print "Usage: $0 <id>\n";
  exit;
}

my $object = $context->getObjectById($id);
if (!$object) {
  print "Didn't find object with ID $id\n";
  exit;
}
print $object->toString();
