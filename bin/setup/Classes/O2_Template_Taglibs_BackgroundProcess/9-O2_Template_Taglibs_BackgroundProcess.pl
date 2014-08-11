use strict;

use O2::Util::ScriptEnvironment;
O2::Util::ScriptEnvironment->runOnlyOnce();

use O2 qw($context $db);

my $introspect = $context->getSingleton('O2::DB::Util::Introspect');
if (!$introspect->tableExists('O2_BACKGROUND_PROCESS')) {
  $db->sql(
    "CREATE TABLE IF NOT EXISTS O2_BACKGROUND_PROCESS (
      randomId varchar(10),
      pid int(11) NOT NULL,
      command varchar(1000) NOT NULL,
      counter int(11) NOT NULL,
      max int(11) NOT NULL,
      exclusive int NOT NULL,
      startTime int NOT NULL,
      PRIMARY KEY (randomId),
      INDEX (pid),
      INDEX (startTime)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8 DEFAULT COLLATE=utf8_danish_ci"
  );
}
