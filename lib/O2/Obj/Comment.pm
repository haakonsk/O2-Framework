package O2::Obj::Comment;

# A top level comment has the object the comment is about as its parent. Lower level comments have another comment as parent.

use strict;

use base 'O2::Obj::Object';

use O2 qw($context);
use URI::Escape qw(uri_escape);
use Digest::MD5 qw(md5_hex);

#-----------------------------------------------------------------------------
sub isRevisionable {
  return 0;
}
#-----------------------------------------------------------------------------
sub getChildren {
  my ($obj) = @_;
  return $obj->getManager()->objectSearch(
    metaParentId => $obj->getId(),
  );
}
#-----------------------------------------------------------------------------
sub getFormattedComment {
  my ($obj) = @_;
  my $comment = $obj->getComment();
  $comment =~ s{ \n \n+ }{<br><br>}xmsg;
  $comment =~ s{ \n     }{<br>}xmsg;
  $comment =~ s{ (https?:// .+?) (?: \s | \z ) }{<a href="$1" target="_blank">$1</a>}xmsg;
  return $comment;
}
#-----------------------------------------------------------------------------
sub getWebSite {
  my ($obj) = @_;
  my $webSite = $obj->getModelValue('webSite');
  $webSite = "http://$webSite" if $webSite && $webSite !~ m{ \A https?:// }xms;
  return $webSite;
}
#-----------------------------------------------------------------------------
sub getGravatarUrl { # Globally recognized avatar: http://en.gravatar.com/
  my ($obj, $size, $defaultImageUrl) = @_;
  $size            ||= 40;
  $defaultImageUrl ||= 'http://' . $context->getHostname() . '/images/comments/defaultGravatar.jpg';
  my $emailHash              = md5_hex( lc $obj->getEmail() );
  my $escapedDefaultImageUrl = uri_escape($defaultImageUrl);
  return "http://www.gravatar.com/avatar/$emailHash?d=$escapedDefaultImageUrl&s=$size";
}
#-----------------------------------------------------------------------------
sub getCommentedOnObject {
  my ($obj) = @_;
  my $object = $obj;
  while (my $parent = $object->getParent()) {
    return $parent if !$parent->isa('O2::Obj::Comment');
    $object = $parent;
  }
  die "Didn't find the object that this comment refers to";
}
#-----------------------------------------------------------------------------
1;
