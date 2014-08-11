package O2::Obj::Class;

use strict;

use base 'O2::Obj::Container';

use O2 qw($context);

#-----------------------------------------------------------------------------
sub new {
  my ($pkg, %init) = @_;
  $init{currentLocale} = undef;
  return bless \%init, $pkg;
}
#-----------------------------------------------------------------------------
sub init {
  my ($obj, %params) = @_;
  foreach my $key (keys %params) {
    $obj->{data}->{$key} = $params{$key};
  }
}
#-----------------------------------------------------------------------------
sub isCachable {
  return 0;
}
#-----------------------------------------------------------------------------
sub setClassName {
  my ($obj, $className) = @_;
  $obj->{data}->{className} = $className;
}
#-----------------------------------------------------------------------------
sub getClassName {
  my ($obj) = @_;
  return $obj->{data}->{className};
}
#-----------------------------------------------------------------------------
sub setEditTemplate {
  my ($obj, $editTemplate) = @_;
  $obj->{data}->{editTemplate} = $editTemplate;
}
#-----------------------------------------------------------------------------
sub getEditTemplate {
  my ($obj) = @_;
  return $obj->{data}->{editTemplate};
}
#-----------------------------------------------------------------------------
sub getDefaultEditTemplate {
  my ($obj) = @_;
  my $editTemplate = $obj->getClassName();
  $editTemplate    =~ s{ :: }{/}xmsg;
  return "$editTemplate/editObject.html";
}
#-----------------------------------------------------------------------------
sub setEditUrl {
  my ($obj, $editUrl) = @_;
  $obj->{data}->{editUrl} = $editUrl;
}
#-----------------------------------------------------------------------------
sub getEditUrl {
  my ($obj) = @_;
  return $obj->{data}->{editUrl};
}
#-----------------------------------------------------------------------------
sub setNewUrl {
  my ($obj, $newUrl) = @_;
  $obj->{data}->{newUrl} = $newUrl;
}
#-----------------------------------------------------------------------------
sub getNewUrl {
  my ($obj) = @_;
  return $obj->{data}->{newUrl};
}
#-----------------------------------------------------------------------------
sub getManagerClass {
  my ($obj) = @_;
  return $context->getUniversalMgr()->objectClassNameToManagerClassName( $obj->getClassName() );
}
#-----------------------------------------------------------------------------
sub setIsCreatableInO2cms {
  my ($obj, $isCreatableInO2cms) = @_;
  $obj->{data}->{isCreatableInO2cms} = $isCreatableInO2cms || 0;
}
#-----------------------------------------------------------------------------
sub isCreatableInO2cms {
  my ($obj) = @_;
  return $obj->{data}->{isCreatableInO2cms};
}
#-----------------------------------------------------------------------------
sub setCanBeCreatedUnderCategories {
  my ($obj, @categories) = @_;
  $obj->{data}->{canBeCreatedUnderCategories} = \@categories;
}
#-----------------------------------------------------------------------------
sub getCanBeCreatedUnderCategories {
  my ($obj) = @_;
  my @classes = $obj->{data}->{canBeCreatedUnderCategories}  ?  @{ $obj->{data}->{canBeCreatedUnderCategories} }  :  ();
  return wantarray ? @classes : \@classes;
}
#-----------------------------------------------------------------------------
sub getChildren {
  my ($obj, $skip, $limit) = @_;
  return $context->getSingleton('O2::Mgr::MetaTreeManager')->getChildren( $obj->getId(), $skip, $limit );
}
#-----------------------------------------------------------------------------
sub canAddObject {
  my ($obj, $fromContainer, $object) = @_;
  return $object->isa('O2::Obj::Class');
}
#-------------------------------------------------------------------------------
sub canMove {
  my ($obj, $fromContainer, $toContainer) = @_;
  return $toContainer->isa('O2::Obj::Class') || $toContainer->isa('O2::Obj::Category::Classes');
}
#-------------------------------------------------------------------------------
sub deletePermanently {
  my ($obj) = @_;
  my $className = $obj->getClassName();
  my $fileMgr = $context->getSingleton('O2::File');
  my $classEntriesFilePath = $obj->getManager()->getClassEntriesFilePath($className);
  my $fileContent = $fileMgr->getFile($classEntriesFilePath);
  $fileContent=~ s{ ^ \s* \{ [^{}]* className \s* => \s* '$className' [^{}]+ \}, \n }{}xms;
  $fileMgr->writeFile($classEntriesFilePath, $fileContent);
}
#-----------------------------------------------------------------------------
1;
