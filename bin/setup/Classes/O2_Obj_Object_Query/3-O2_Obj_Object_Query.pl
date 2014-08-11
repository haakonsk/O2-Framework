use strict;

use O2::Util::ScriptEnvironment;
O2::Util::ScriptEnvironment->runOnlyOnce();

use O2 qw($context $db);

exit unless $context->getSingleton('O2::DB::Util::Introspect')->tableExists('O2_OBJ_METAQUERY');

my @rows = $db->fetchAll(
  "select o.objectId, parentId, name, createTime, o.status as oStatus, q.status as qStatus, ownerId from O2_OBJ_METAQUERY q, O2_OBJ_OBJECT o where q.objectId = o.objectId and o.status in ('trashed', 'deleted')",
);

my $queryMgr     = $context->getSingleton('O2::Mgr::Object::QueryManager');
my $objectMgr    = $context->getSingleton('O2::Mgr::ObjectManager');
my $universalMgr = $context->getSingleton('O2::Mgr::UniversalManager');

foreach my $row (@rows) {
  my $id = $row->{objectId};
  
  my $query = eval {
    $context->getObjectById($id) || $universalMgr->getTrashedObjectById($id);
  };
  next if $query && $query->isa('O2::Obj::Object::Query');
  
  my $queryStatus = $row->{oStatus} eq 'trashed' || $row->{oStatus} eq 'deleted'  ?  $row->{oStatus}  :  $row->{qStatus};
  
  my @criterionRows = $db->fetchAll("select * from O2_OBJ_METAQUERY_CRITERIA where objectId = ?", $id);
  my %searchParams;
  foreach my $criterionRow (@criterionRows) {
    %searchParams = updateSearchParams( $criterionRow->{type}, $criterionRow->{value}, %searchParams );
  }
  my $query = $queryMgr->newObjectBySearchParams($objectMgr, %searchParams);
  $query->setMetaParentId(   $row->{parentId}   );
  $query->setMetaName(       $row->{name}       );
  $query->setMetaCreateTime( $row->{createTime} );
  $query->setMetaStatus(     $queryStatus       );
  $query->setMetaOwnerId(    $row->{ownerId}    );
  $query->setId(             $id                ); # Reuse the ID, so we don't have to fix slot IDs
  $query->save();
}
$db->do("rename table O2_OBJ_METAQUERY          to O2_OBJ_METAQUERY_BACKUP");
$db->do("rename table O2_OBJ_METAQUERY_CRITERIA to O2_OBJ_METAQUERY_CRITERIA_BACKUP");

sub updateSearchParams {
  my ($type, $value, %searchParams) = @_;
  $value =~ s{ \* }{%}xmsg    if $type eq 'namePartialMatch' || $type =~ m{ Like \z }xms;
  $value = '%' . $value . '%' if $type eq 'namePartialMatch';
  
  my $key = $type;
  $key = 'metaName'       if $type eq 'namePartialMatch' || $type eq 'nameLike';
  $key = 'metaClassName'  if $type eq 'classNameLike';
  $key = 'metaClassName'  if $type eq 'notClassName';
  $key = 'metaParentId'   if $type eq 'parentId';
  $key = 'metaParentId'   if $type eq 'notParentId';
  $key = 'metaStatus'     if $type eq 'status';
  $key = 'metaStatus'     if $type eq 'notStatus';
  $key = 'metaClassName'  if $type eq 'className';
  $key = '-ancestorId'    if $type eq 'parentIdRecursive';
  $key = 'metaOwnerId'    if $type eq 'ownerId';
  $key = 'metaOwnerId'    if $type eq 'notOwnerId';
  $key = 'metaCreateTime' if $type eq 'createdNewer';
  $key = 'metaCreateTime' if $type eq 'createdOlder';
  $key = 'metaChangeTime' if $type eq 'changedNewer';
  $key = 'metaChangeTime' if $type eq 'changedOlder';
  $key = '-limit'         if $type eq 'maxRows';
  
  push @{ $searchParams{$key}->{ in      } },      $value  if $type =~ m{ \A (?: objectId | parentId | status | className | parentIdRecursive | ownerId ) \z }xms;
  push @{ $searchParams{$key}->{ likeAny } },      $value  if $type =~ m{ \A (?: namePartialMatch | nameLike | classNameLike                            ) \z }xms;
  push @{ $searchParams{$key}->{ notIn   } },      $value  if $type =~ m{ \A (?: notClassName | notParentId | notStatus | notOwnerId                    ) \z }xms;
          $searchParams{$key}->{ ge      } = "time-$value" if $type eq 'createdNewer';
          $searchParams{$key}->{ le      } = "time-$value" if $type eq 'createdOlder';
          $searchParams{$key}->{ ge      } = "time-$value" if $type eq 'changedNewer';
          $searchParams{$key}->{ le      } = "time-$value" if $type eq 'changedOlder';
          $searchParams{$key}              =       $value  if $type eq 'orderBy';
          $searchParams{$key}              =       $value  if $type eq 'maxRows';
  
  return %searchParams;
}
