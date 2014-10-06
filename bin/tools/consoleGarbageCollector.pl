use strict;

use O2::Context;
my $context = O2::Context->new();

$context->getConsole()->deleteOldEntries();
