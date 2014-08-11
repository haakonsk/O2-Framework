package O2::Mgr::KeywordManager;

use strict;

use base 'O2::Mgr::ObjectManager';

use O2 qw($context $db);
use O2::Obj::Keyword;

#--------------------------------------------------------------------------------
# Returns object from database if keyword exists, otherwise new object
sub newObjectByName {
  my ($obj, $keywordName) = @_;
  my ($keyword) = $obj->getObjectsByNameMatch($keywordName);
  if (!$keyword) {
    $keyword = $obj->newObject();
    $keyword->setMetaName($keywordName);
  }
  return $keyword;
}
#--------------------------------------------------------------------------------
# Returns IDs of objects tagged with keyword(s)
sub getTaggedObjectIdsByKeywordIds {
  my ($obj, @keywordIds) = @_;
  return $obj->_getTaggedObjectIdsByKeywordIds('and', @keywordIds);
}
#--------------------------------------------------------------------------------
sub _getTaggedObjectIdsByKeywordIds {
  my ($obj, $joinOperator, @keywordIds) = @_;
  
  if (@keywordIds == 1) {
    return $db->fetch( "select objectId from O2_OBJ_OBJECT_OBJECT where value = ? and name like 'keywordIds.\%'", $keywordIds[0] );
  }
  else {
    my $sql = 'select t0.objectId from ';
    $sql .= join ',', map "O2_OBJ_OBJECT_OBJECT t$_", 0..$#keywordIds;
    $sql .= ' where ';
    $sql .= join ' and ', map "t0.objectId=t$_.objectId", 1..$#keywordIds;
    $sql .= ' and ';
    $sql .= '('.join(" $joinOperator ", map "t$_.value=?", 0..$#keywordIds).')';
    $sql .= ' and ';
    $sql .= join ' and ', map "t$_.name like 'keywordIds.%'", 0..$#keywordIds;
    return $db->fetch($sql, @keywordIds);
  }
}
#--------------------------------------------------------------------------------
# Returns objects tagged with keyword
sub getTaggedObjectsByKeywordIds {
  my ($obj, @keywordIds) = @_;
  return $context->getObjectsByIds( $obj->getTaggedObjectIdsByKeywordIds(@keywordIds) );
}
#--------------------------------------------------------------------------------
# Returns objects tagged with keyword, or one of keywords children
sub getTaggedObjectsByRecursiveKeywordIds {
  my ($obj, @keywordIds) = @_;
  my $metaTreeMgr = $context->getSingleton('O2::Mgr::MetaTreeManager');
  push @keywordIds, map  { $metaTreeMgr->getChildIdsRecursive($_) }  @keywordIds;
  return $obj->_getTaggedObjectIdsByKeywordIds('or', @keywordIds);
}
#--------------------------------------------------------------------------------
# Returns keyword with name $name
sub getObjectsByNameMatch {
  my ($obj, $nameMatch) = @_;
  $nameMatch =~ s{ \* }{%}xms;
  return $obj->objectSearch(
    metaName => { like => $nameMatch },
  );
}
#--------------------------------------------------------------------------------
sub getFolderKeywords {
  my ($obj) = @_;
  my @objectIds = $db->selectColumn('select objectId from O2_OBJ_KEYWORD where isFolder = 1');
  return $obj->getObjectsByIds(@objectIds);
}
#--------------------------------------------------------------------------------
sub initModel {
  my ($obj, $model) = @_;
  $obj->SUPER::initModel($model);
  $model->registerFields(
    'O2::Obj::Keyword',
    isFolder => { type => 'bit', defaultValue => '0' },
  );
}
#--------------------------------------------------------------------------------
sub getKeywordWithChilds {
  my ($obj) = @_;
  my @rows = $db->fetchAll("select objectId, parentId from O2_OBJ_OBJECT where className like 'O2::Obj::Keyword' and status not in ('trashed', 'trashedAncestor', 'deleted')");
  my %tree;
  foreach my $row (@rows) {
    $tree{ $row->{parentId} }++;
  }
  my @parentKeywords = sort { $a <=> $b } keys %tree;
  my @objects = $context->getObjectsByIds(@parentKeywords);
  return wantarray ? @objects : \@objects;
}
#--------------------------------------------------------------------------------
sub save {
  my ($obj, $object) = @_;
  if (!($object->getMetaParentId() > 0) && $context->cmsIsEnabled()) {
    my ($keywordCategory) = $context->getSingleton('O2CMS::Mgr::Category::KeywordsManager')->objectSearch(-limit => 1);
    $object->setMetaParentId( $keywordCategory->getId() ) if $keywordCategory;
  }
  $obj->SUPER::save($object);
}
#--------------------------------------------------------------------------------
1;
