package O2::Obj::Keyword;

use strict;

use base 'O2::Obj::Object';
use base 'O2::Role::Obj::ChildLister';

#--------------------------------------------------------------------------------
sub isDeletable {
  return 1;
}
#--------------------------------------------------------------------------------
# returns true if you may add $object to this container
sub canAddObject {
  my ($obj, $fromContainer, $object) = @_;
  $object->isa('O2::Obj::Keyword'); # can only contain other keywords
}
#--------------------------------------------------------------------------------
# returns true if you may remove $object from this container
sub canRemoveObject {
  my ($obj, $toContainer, $object) = @_;
  return 1;
}
#--------------------------------------------------------------------------------
# returns true if you may move this object to $toContainer
sub canMove {
  my ($obj, $fromContainer, $toContainer) = @_;
  return $toContainer->isa('O2::Obj::Keyword') || $toContainer->isa('O2CMS::Obj::Trashcan');
}
#--------------------------------------------------------------------------------
sub getParentKeywords {
  my ($obj) = @_;
  
  my @path;
  my $object = $obj;
  while ( $object->getMetaParentId() ) {
    $object = $object->getParent();
    last unless $object->isa('O2::Obj::Keyword');
    push @path, $object;
  }
  return reverse @path;
}
#--------------------------------------------------------------------------------
sub getFullName {
  my ($obj) = @_;
  return join '/', map { $_->getMetaName() } $obj->getParentKeywords(), $obj;
}
#--------------------------------------------------------------------------------
1;
