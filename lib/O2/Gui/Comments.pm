package O2::Gui::Comments;

use strict;

use base 'O2::Gui';

use O2 qw($context);

#------------------------------------------------------------------
sub init {
  my ($obj) = @_;
  my $object = $obj->getObjectByParam('objectId');
  $obj->display(
    'o2://var/templates/frontend/includes/comments/comments.html',
    comments => [ $object->getComments() ],
  );
}
#------------------------------------------------------------------
sub previewComment {
  my ($obj) = @_;
  $obj->display(
    'previewComment.html',
    comment => $obj->_getCommentObjectFromRequest(),
  );
}
#------------------------------------------------------------------
sub saveComment {
  my ($obj) = @_;
  return $obj->display('changeCommentForm.html') if $obj->getParam('changeComment');
  
  my $objectId = $obj->getParam('objectId');
  my $object   = $context->getObjectById($objectId);
  my $comment  = $obj->_getCommentObjectFromRequest();
  $comment->save();
  return 1;
}
#------------------------------------------------------------------
sub _getCommentObjectFromRequest {
  my ($obj, $objectId) = @_;
  my $commentText = $obj->getParam('comment');
  $commentText    =~ s{&}{&amp;}xmsg;
  $commentText    =~ s{<}{&lt;}xmsg;
  $commentText    =~ s{>}{&gt;}xmsg;
  $commentText    =~ s{ \r\n     }{\n}xmsg;
  $commentText    =~ s{ \r       }{\n}xmsg;
  $commentText    =~ s{ \n \s+ $ }{\n}xmsg;
  $commentText    =~ s{ \n \n+   }{\n\n}xmsg;
  
  $objectId ||= $obj->getParam('objectId');
  my $object  = $context->getObjectById($objectId);
  
  my $comment = $context->getSingleton('O2::Mgr::CommentManager')->newObject();
  $comment->setMetaParentId( $object->getId()          );
  $comment->setMetaName(     "Comment to $objectId"    );
  $comment->setName(         $obj->getParam('name')    );
  $comment->setEmail(        $obj->getParam('email')   );
  $comment->setWebSite(      $obj->getParam('webSite') );
  $comment->setTitle(        $obj->getParam('title')   );
  $comment->setComment(      $commentText              );
  return $comment;
}
#------------------------------------------------------------------
1;
