package O2::Obj::Object::Query;

use strict;

use base 'O2::Obj::Object';

use O2 qw($context $db);
use O2::Util::List qw(upush);
use Time::HiRes    qw(gettimeofday);

#-----------------------------------------------------------------------------
sub searchArchiveToo {
  my ($obj) = @_;
  return $obj->getSearchArchiveToo();
}
#-----------------------------------------------------------------------------
sub setOrderBy {
  my ($obj, $value) = @_;
  
  # Validate:
  if ($value ne '_random') {
    my @parts = split /\s*,\s*/, $value;
    foreach my $part (@parts) {
      my ($fieldName, $sortDirection) = $part =~ m{ \A (\w+) (?: \s+ (\w+) )? \z }xms;
      die "Invalid 'orderBy' value ($value)" unless $fieldName;
      die "Invalid sort direction ($sortDirection) in orderBy ($part)" if $sortDirection && $sortDirection !~ m{ \A asc | desc \z }xms;
      eval {
        $obj->_getSearchMgr()->getModel()->getFieldByName($fieldName);
      };
      die "Invalid 'sortBy' value ($value): $@" if $@;
    }
  }
  $obj->setModelValue('orderBy', $value);
}
#-----------------------------------------------------------------------------
sub getOrderBySql {
  my ($obj) = @_;
  my $orderBy = $obj->getModelValue('orderBy');
  return $orderBy unless $orderBy;
  return 'rand()'     if $orderBy eq '_random';
  
  my $orderBySql = '';
  my @parts = split /\s*,\s*/, $orderBy;
  foreach my $part (@parts) {
    my ($fieldName, $sortDirection) = $part =~ m{ \A (\w+) (?: \s+ (\w+) )? \z }xms;
    die "Didn't understand '$part' in 'orderBy' attribute" unless $fieldName;
    
    $sortDirection = '' unless defined $sortDirection;
    my $field = $obj->_getSearchMgr()->getModel()->getFieldByName($fieldName);
    $orderBySql .= $field->getTableName() . '.' . $field->getTableFieldName() . " $sortDirection, ";
  }
  return substr $orderBySql, 0, -2;
}
#-----------------------------------------------------------------------------
sub setClassNameByManagerClassName {
  my ($obj, $mgrClassName) = @_;
  my $className = $context->getUniversalMgr()->managerClassNameToObjectClassName($mgrClassName);
  $obj->setClassName($className);
}
#-----------------------------------------------------------------------------
sub addUnionQuery {
  my ($obj, $query) = @_;
  if ($obj->getUnionQuery()) {
    $obj->getUnionQuery()->addUnionQuery($query);
  }
  else {
    $obj->setUnionQuery($query);
  }
}
#-----------------------------------------------------------------------------
sub newConditionGroup {
  my ($obj) = @_;
  my $conditionGroup = $context->getSingleton('O2::Mgr::Object::Query::ConditionGroupManager')->newObject();
  $conditionGroup->{query} = $obj; # Link back to query object, so we can find the condition group's query object even when the condition group isn't saved
  my @conditionGroups = $obj->getConditionGroups();
  $obj->setConditionGroups(@conditionGroups, $conditionGroup);
  return $conditionGroup;
}
#-----------------------------------------------------------------------------
sub getSql {
  my ($obj, %params) = @_;
  my $whatToSelect = $params{whatToSelect} || 'distinct(O2_OBJ_OBJECT.objectId)';
  my $unionQuery = $obj->getUnionQuery();
  my $orderBySql = $obj->getOrderBySql();
  if ($unionQuery || $params{isUnionQuery}) {
    my $orderByFields = $orderBySql;
    $orderByFields =~ s{ asc | desc }{}xmsg;
    $whatToSelect .= ", $orderByFields" if $orderByFields;
  }
  
  my @usedTables = $obj->getUsedTables();
  my $sql = sprintf "select $whatToSelect from %s where ", join ', ', @usedTables;
  
  # Join on objectId:
  my $joinSql = '';
  for (my $i = 0; $i < @usedTables-1; $i++) {
    $joinSql .= 'and ' if $i > 0;
    $joinSql .= "$usedTables[$i].objectId = $usedTables[$i+1].objectId ";
  }
  $sql .= $joinSql if $joinSql;
  
  my (@placeHolders, @subSqls);
  
  foreach my $conditionGroup ($obj->getConditionGroups()) {
    my ($_sql, @_placeHolders) = $conditionGroup->getSql();
    next unless $_sql;
    
    push @subSqls,      $_sql;
    push @placeHolders, @_placeHolders;
  }
  
  my $joinWith = $obj->getJoinWith();
  my $includeParentheses = $joinSql && @subSqls >= 2 && $joinWith eq 'or';
  $sql .= 'and ' if $joinSql && @subSqls;
  $sql .= '('    if $includeParentheses;
  $sql .= join " $joinWith ", @subSqls;
  $sql .= ')'    if $includeParentheses;
  
  if ($unionQuery) {
    my ($_sql, @_placeHolders) = $unionQuery->getSql(isUnionQuery => 1);
    $orderBySql =~ s{ \w+ [.] }{}xmsg;
    my $alias = $context->getSingleton('O2::Util::Password')->generatePassword(8); # An alias is required in the "union" query
    $sql  = "select objectId from ($sql union $_sql) as $alias";
    $sql .= " order by $orderBySql" if $orderBySql;
    push @placeHolders, @_placeHolders;
  }
  elsif (!$params{isUnionQuery} && $orderBySql) {
    $sql .= " order by $orderBySql";
  }
  
  return ($sql, @placeHolders);
}
#-----------------------------------------------------------------------------
sub getMin {
  my ($obj, $fieldName) = @_;
  die 'getMin: field name is required' unless $fieldName;
  
  my ($sql, @placeHolders) = $obj->getSql( whatToSelect => $obj->_getWhatToSelect('min', $fieldName) );
  warn $sql if $obj->getDebug();
  
  my $t0 = gettimeofday();
  my $min = $db->fetch($sql, @placeHolders);
  my $dt = gettimeofday() - $t0;
  warn "Min is $min. It took $dt seconds" if $obj->getDebug();
  
  return $min;
}
#-----------------------------------------------------------------------------
sub getMax {
  my ($obj, $fieldName) = @_;
  die 'getMax: field name is required' unless $fieldName;
  
  my ($sql, @placeHolders) = $obj->getSql( whatToSelect => $obj->_getWhatToSelect('max', $fieldName) );
  warn $sql if $obj->getDebug();
  
  my $t0 = gettimeofday();
  my $max = $db->fetch($sql, @placeHolders);
  my $dt = gettimeofday() - $t0;
  warn "Max is $max. It took $dt seconds" if $obj->getDebug();
  
  return $max;
}
#-----------------------------------------------------------------------------
sub getCount {
  my ($obj) = @_;
  my ($sql, @placeHolders) = $obj->getSql(whatToSelect => 'count(*)');
  warn $sql if $obj->getDebug();
  
  my $t0 = gettimeofday();
  my $count = $db->fetch($sql, @placeHolders);
  my $dt = gettimeofday() - $t0;
  warn "Count is $count. It took $dt seconds" if $obj->getDebug();
  
  return $count;
}
#-----------------------------------------------------------------------------
sub _getWhatToSelect {
  my ($obj, $type, $fieldName) = @_;
  my $field = $obj->_getSearchMgr()->getModel()->getFieldByName($fieldName);
  $obj->addUsedTables( $field->getTableName() );
  return $type . '(' . $field->getTableName() . '.' . $field->getTableFieldName() . ')';
}
#-----------------------------------------------------------------------------
sub getDistinct {
  my ($obj, $fieldName) = @_;
  my ($sql, @placeHolders) = $obj->getSql( whatToSelect => $obj->_getWhatToSelect('distinct', $fieldName) );
  warn $sql if $obj->getDebug();
  
  my $t0 = gettimeofday();
  my @values = $db->selectColumn($sql, @placeHolders);
  my $dt = gettimeofday() - $t0;
  warn scalar (@values) . " results. It took $dt seconds" if $obj->getDebug();
  
  return @values;
}
#-----------------------------------------------------------------------------
sub getDistinctSql {
  my ($obj, $fieldName) = @_;
  my $field = $obj->_getSearchMgr()->getModel()->getFieldByName($fieldName);
  return $obj->getSql( whatToSelect => 'distinct(' . $field->getTableName() . '.' . $field->getTableFieldName() . ')' );
}
#-----------------------------------------------------------------------------
sub addUsedTables {
  my ($obj, @tableNames) = @_;
  my @usedTables = @{ $obj->{usedTables} || [] };
  upush @usedTables, @tableNames;
  $obj->{usedTables} = \@usedTables;
}
#-----------------------------------------------------------------------------
sub getUsedTables {
  my ($obj) = @_;
  my $tableName  = $obj->getManager()->_classNameToTableName( $obj->getClassName() );
  my @tableNames = @{ $obj->{usedTables} || [] };
  upush @tableNames, $tableName;
  foreach my $conditionGroup ($obj->getConditionGroups()) {
    upush @tableNames, $conditionGroup->getUsedTables();
  }
  return @tableNames;
}
#-----------------------------------------------------------------------------
sub getObjectIds {
  my ($obj, %params) = @_;
  my ($sql, @placeHolders) = $obj->getSql();
  if ($params{useArchiveDbh}) {
    warn "Using archive database for the next query" if $obj->getDebug();
    $context->useArchiveDbh();
  }
  warn $db->_expandPH($sql, @placeHolders) if $obj->getDebug();
  my $t0 = gettimeofday();
  my @objectIds = $db->selectColumn($sql, @placeHolders);
  my $dt = gettimeofday() - $t0;
  warn "It took $dt seconds. " . scalar(@objectIds) . ' results' if $obj->getDebug();
  
  @objectIds = $obj->_filterObjectIds(\@objectIds);
  
  $obj->_setTotalNumSearchResults( scalar @objectIds );
  my $skip  = $obj->getSkip();
  my $limit = $obj->getLimit();
  splice @objectIds, 0, $skip if $skip;
  splice @objectIds, $limit   if $limit && @objectIds > $limit;
  if ($obj->searchArchiveToo() && !$params{useArchiveDbh}) {
    my @moreObjectIds = $obj->getObjectIds(useArchiveDbh => 1);
    push @objectIds, @moreObjectIds;
  }
  return wantarray ? @objectIds : \@objectIds;
}
#-----------------------------------------------------------------------------
sub getObjects {
  my ($obj) = @_;
  my @objectIds = $obj->getObjectIds();
  my @objects;
  foreach my $id (@objectIds) {
    my $object = $context->getObjectById($id) || $context->getUniversalMgr()->getTrashedObjectById($id);
    push @objects, $object if $object;
  }
  return wantarray ? @objects : \@objects;
}
#-----------------------------------------------------------------------------
sub getTotalNumSearchResults { # Can be called after objectSearch or objectIdSearch
  my ($obj) = @_;
  return $obj->{objectSearchTotalNumResults};
}
#-----------------------------------------------------------------------------
sub _setTotalNumSearchResults {
  my ($obj, $numResults) = @_;
  $obj->{objectSearchTotalNumResults} = $numResults;
}
#-----------------------------------------------------------------------------
sub _filterObjectIds {
  my ($obj, $objectIds) = @_;
  my @objectIds = @{$objectIds};
  
  if (my $condition = $obj->getInFolderCondition()) {
    warn "Filtering search results with -ancestorId" if $obj->getDebug();
    my $t0 = gettimeofday();
    my $operator = $condition->getOperator();
    if ($operator ne '=' && $operator ne '!=' && $operator ne 'in' && $operator ne 'not in') {
      die "Invalid operator $operator for -ancestorId";
    }
    
    my (@validIds, @invalidIds);
    my @conditionValues = $condition->can('getValue') ? ($condition->getValue()) : $condition->getValues();
    foreach my $id (@objectIds) {
    CONDITION_VALUE:
      foreach my $conditionValue (@conditionValues) {
        if ($operator eq '=' || $operator eq 'in') {
          if ($obj->_idHasOtherIdAsAncestor($id, $conditionValue)) {
            push @validIds, $id;
            last CONDITION_VALUE;
          }
        }
        elsif ($operator eq '!=') {
          if (!$obj->_idHasOtherIdAsAncestor($id, $conditionValue)) {
            push @validIds, $id;
            last CONDITION_VALUE;
          }
        }
        elsif ($operator eq 'not in') {
          if ($obj->_idHasOtherIdAsAncestor($id, $conditionValue)) {
            push @invalidIds, $id;
            last CONDITION_VALUE;
          }
        }
      }
    }
    
    if ($operator eq 'not in') {
      my %ids = map { $_ => 1 } @objectIds;
      foreach my $id (@invalidIds) {
        delete $ids{$id};
      }
      @validIds = keys %ids;
    }
    
    my $dt = gettimeofday() - $t0;
    my $numRemoved = @{$objectIds} - @validIds;
    @{$objectIds} = @validIds;
    warn "Filtering took $dt seconds. Filtered away $numRemoved IDs, " . scalar (@validIds) . ' results left' if $obj->getDebug();
  }
  return @{$objectIds};
}
#-----------------------------------------------------------------------------
sub _idHasOtherIdAsAncestor {
  my ($obj, $id, $otherId) = @_;
  $obj->{parentIds} ||= {};
  my $parentId = $obj->{parentIds}->{$id} = exists $obj->{parentIds}->{$id} ? $obj->{parentIds}->{$id} : $db->fetch("select parentId from O2_OBJ_OBJECT where objectId = ?", $id);
  return 1 if $parentId == $otherId;
  while ($parentId) {
    my $newParentId = exists $obj->{parentIds}->{$parentId} ? $obj->{parentIds}->{$parentId} : $db->fetch("select parentId from O2_OBJ_OBJECT where objectId = ?", $parentId);
    return 1 if $newParentId && $newParentId == $otherId;
    $obj->{parentIds}->{$parentId} ||= $newParentId;
    $parentId = $newParentId;
  }
  return 0;
}
#-----------------------------------------------------------------------------
sub deletePermanently {
  my ($obj) = @_;
  foreach my $conditionGroup ($obj->getConditionGroups()) {
    $conditionGroup->deletePermanently();
  }
  $obj->SUPER::deletePermanently();
}
#-----------------------------------------------------------------------------
sub delete {
  my ($obj) = @_;
  foreach my $conditionGroup ($obj->getConditionGroups()) {
    $conditionGroup->delete();
  }
  $obj->SUPER::delete();
}
#-----------------------------------------------------------------------------
sub isEmpty {
  my ($obj) = @_;
  my @conditionGroups = $obj->getConditionGroups();
  return 0 if @conditionGroups;
  return $obj->getInFolderCondition() ? 0 : 1;
}
#-----------------------------------------------------------------------------
sub getManagerClassName {
  my ($obj) = @_;
  return $context->getUniversalMgr()->objectClassNameToManagerClassName( $obj->getClassName() );
}
#-----------------------------------------------------------------------------
sub _getSearchMgr {
  my ($obj) = @_;
  my $mgrClass = $context->getUniversalMgr()->objectClassNameToManagerClassName( $obj->getClassName() );
  return $context->getSingleton($mgrClass);
}
#-----------------------------------------------------------------------------
1;
