package O2::Cache::Dummy;

use strict;

use base 'O2::Cache::Base';

#--------------------------------------------------------------------------------------------
sub get                   {}
sub set                   {}
sub delete                {}
sub flushCache            {}
sub getSQL                {}
sub setSQL                {}
sub deleteSQL             {}
sub flushCacheSQL         {}
sub flushCacheSQLForTable {}
sub getCachedSQLs         {}
#--------------------------------------------------------------------------------------------
1;
