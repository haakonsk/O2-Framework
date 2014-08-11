use strict;

use O2::Util::SetApacheEnv;

use O2 qw($context);

$| = 1;

print "Cache method: " . (ref $context->getMemcached()) . "\n";
print "Flushing cache....";
$context->getMemcached()->flushCacheSQL();
print "Done!\n";
