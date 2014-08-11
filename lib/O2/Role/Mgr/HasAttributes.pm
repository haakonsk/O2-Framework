package O2::Role::Mgr::HasAttributes;

use strict;

use O2 qw($db);

#-----------------------------------------------------------------------------
sub saveAttributes {
  my ($obj, $dbTable, $objectIdColumn, $objectId, %attributes) = @_;
  
  $db->startTransaction();
  
  my $deleteSth = $db->prepare("delete from $dbTable where $objectIdColumn = ?");
  $deleteSth->execute($objectId);
  foreach my $name (keys %attributes) {
    next unless $name;
    my $value = $attributes{$name};
    $db->insert(
      $dbTable,
      $objectIdColumn => $objectId,
      name            => $name,
      value           => $value,
    );
  }
  
  $db->endTransaction();
}
#-----------------------------------------------------------------------------

1;
