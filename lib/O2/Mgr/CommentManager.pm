package O2::Mgr::CommentManager;

use strict;

use base 'O2::Mgr::ObjectManager';

use O2::Obj::Comment;

#-----------------------------------------------------------------------------
sub initModel {
  my ($obj, $model) = @_;
  $obj->SUPER::initModel($model);
  $model->registerFields(
    'O2::Obj::Comment',
    # Your class definition goes here:
    #-----------------------------------------------------------------------------
    name    => { type => 'varchar', notNull => '1' },
    email   => { type => 'varchar'                 },
    webSite => { type => 'varchar'                 },
    title   => { type => 'varchar'                 },
    comment => { type => 'text', notNull => '1'    },
    #-----------------------------------------------------------------------------
  );
}
#-----------------------------------------------------------------------------
# Only returns top level comments. You can call getChildren on the comments to get the replies.
sub getCommentsFor {
  my ($obj, $objectId) = @_;
  return $obj->objectSearch(
    metaParentId => $objectId,
  );
}
#-----------------------------------------------------------------------------
1;
