use strict;

use O2::Util::ScriptEnvironment;
O2::Util::ScriptEnvironment->runOnlyOnce();

use O2 qw($context $db);

my @ids = $db->selectColumn("select objectId from O2_OBJ_OBJECT_QUERY where orderBy = 'rand()'");
$db->do("update O2_OBJ_OBJECT_QUERY set orderBy = '_random' where orderBy = 'rand()'");

my $cacher = $context->getMemcached();
foreach my $id (@ids) {
  $cacher->deleteObjectById($id);
}

my @rows = $db->fetchAll("select objectId, orderBy from O2_OBJ_OBJECT_QUERY where orderBy like 'createTime%'");
foreach my $row (@rows) {
  my $id      = $row->{objectId};
  my $orderBy = $row->{orderBy};
  $orderBy    =~ s{ \A createTime }{metaCreateTime}xms;
  $db->do("update O2_OBJ_OBJECT_QUERY set orderBy = ? where objectId = ?", $orderBy, $id);
  $cacher->deleteObjectById($id);
}
