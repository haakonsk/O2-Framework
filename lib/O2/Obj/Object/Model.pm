package O2::Obj::Object::Model;

use strict;

use O2 qw($context $db);

#-----------------------------------------------------------------------------
sub new {
  my ($pkg, %init) = @_;
  return bless {
    fields            => {},
    addedFields       => [],
    modifiedFields    => [],
    deletedFields     => {},
    renamedFields     => {},
    objectSourceCode  => '',
    managerSourceCode => '',
    classNames        => [],
  }, $pkg;
}
#-----------------------------------------------------------------------------
sub isMultilingual {
  my ($obj) = @_;
  return $obj->getMultilingualFields() ? 1 : 0;
}
#-----------------------------------------------------------------------------
sub setClassName {
  my ($obj, $className) = @_;
  $obj->{className}        = $className;
  $obj->{managerClassName} = undef; # Clear cache
}
#-----------------------------------------------------------------------------
sub getClassName {
  my ($obj) = @_;
  return $obj->{className};
}
#-----------------------------------------------------------------------------
sub setManagerClassName {
  my ($obj, $managerClassName) = @_;
  $obj->{managerClassName} = $managerClassName;
}
#-----------------------------------------------------------------------------
sub getManagerClassName {
  my ($obj) = @_;
  return $obj->{managerClassName} ||= $context->getUniversalMgr()->objectClassNameToManagerClassName( $obj->getClassName() );
}
#-----------------------------------------------------------------------------
sub getManager {
  my ($obj) = @_;
  return $context->getSingleton( $obj->getManagerClassName() );
}
#-----------------------------------------------------------------------------
sub setSuperClassName {
  my ($obj, $superClassName) = @_;
  $obj->{superClassName} = $superClassName;
  $obj->setManagerSuperClassName( $context->getUniversalMgr()->objectClassNameToManagerClassName($superClassName) );
}
#-----------------------------------------------------------------------------
sub getSuperClassName {
  my ($obj) = @_;
  return $obj->{superClassName} || 'O2::Obj::Object';
}
#-----------------------------------------------------------------------------
sub setManagerSuperClassName {
  my ($obj, $managerSuperClassName) = @_;
  $obj->{managerSuperClassName} = $managerSuperClassName;
}
#-----------------------------------------------------------------------------
sub getManagerSuperClassName {
  my ($obj) = @_;
  return $obj->{managerSuperClassName} ||= $context->getUniversalMgr()->objectClassNameToManagerClassName( $obj->getSuperClassName() );
}
#-----------------------------------------------------------------------------
# add fields to model
sub registerFields {
  my ($obj, $className, %fields) = @_;
  push  @{ $obj->{classNames} },  $className;

  require Class::ISA;
  my @superClasses = Class::ISA::super_path($className);
  $obj->setSuperClassName( $superClasses[0] ) if @superClasses;

  foreach my $fieldName (keys %fields) {
#    print "Register model field $className: $fieldName [$fields{$fieldName}->{listType}]\n";
    my $field = $obj->{fields}->{$fieldName} = $obj->_createField( $className, $fieldName, $fields{$fieldName} );
    $obj->{fieldsByClassName}->{$className}->{$fieldName} = $field;
  }
}
#-----------------------------------------------------------------------------
sub registerIndexes {
  my ($obj, $className, @indexHashes) = @_;
  my @indexes;
  require O2::DB::Util::Introspect::Index;
  foreach my $indexHash (@indexHashes) {
    push @indexes, O2::DB::Util::Introspect::Index->new(
      indexName   => $indexHash->{name},
      type        => 'BTREE',
      columnNames => $indexHash->{columns},
      isUnique    => $indexHash->{isUnique},
    );
  }
  $obj->{indexes}->{$className} = \@indexes;
}
#-----------------------------------------------------------------------------
sub getIndexes {
  my ($obj, $className) = @_;
  return @{ $obj->{indexes}->{$className} || [] };
}
#-----------------------------------------------------------------------------
sub _createField {
  my ($obj, $className, $fieldName, $fieldInfo) = @_;
  $fieldInfo->{listType}  = 'none' unless $fieldInfo->{listType};
  $fieldInfo->{className} = $className;
  $fieldInfo->{name}      = $fieldName;
  require O2::Obj::Object::Model::Field;
  return O2::Obj::Object::Model::Field->new( field => $fieldInfo, model => $obj );
}
#-----------------------------------------------------------------------------
# return all fields, including fields from superclasses
sub getFields {
  my ($obj) = @_;
  return values %{ $obj->{fields} };
}
#-----------------------------------------------------------------------------
sub getFieldByName {
  my ($obj, $fieldName) = @_;
  $fieldName = 'id' if $fieldName eq 'objectId';
  my $field = $obj->{fields}->{$fieldName};
  die "Field name '$fieldName' not defined in model for " . $obj->getClassName() unless $field;
  return $field;
}
#-----------------------------------------------------------------------------
sub hasField {
  my ($obj, $fieldName) = @_;
  return $obj->{fields}->{$fieldName} ? 1 : 0;
}
#-----------------------------------------------------------------------------
sub hasOwnField {
  my ($obj, $fieldName) = @_;
  return $obj->{fieldsByClassName}->{ $obj->getClassName() }->{$fieldName} ? 1 : 0;
}
#-----------------------------------------------------------------------------
# return fields used in the class given as parameter
sub getFieldsByClassName {
  my ($obj, $className) = @_;
  return () unless $className;
  
  my @fields;
  foreach my $field (values %{ $obj->{fields} }) {
    push @fields, $field if $field->getClassName() eq $className;
  }
  return @fields;
}
#-----------------------------------------------------------------------------
sub getAvailableFieldTypes {
  my ($obj, $fieldName) = @_;
  my @types = qw(bit int float double epoch date object char varchar text mediumtext longtext);
  if ($fieldName) {
    my $field = $obj->getFieldByName($fieldName);
    unshift @types, $field->getType() if $field->getType() =~ m{ :: }xms;
  }
  return wantarray ? @types : \@types;
}
#-----------------------------------------------------------------------------
sub getAvailableListTypes {
  my ($obj) = @_;
  return qw(array hash);
}
#-----------------------------------------------------------------------------
sub addField {
  my ($obj, $fieldName, $fieldInfo) = @_;
  my $field = $obj->_createField( $obj->getClassName(), $fieldName, $fieldInfo );
  $obj->{fields}->{$fieldName} = $field;
  push @{ $obj->{addedFields} }, $fieldName;
  $obj->_getInitModelCodeObject()->addField($field);
}
#-----------------------------------------------------------------------------
sub modifyField {
  my ($obj, $originalFieldName, $fieldInfo) = @_;
  my $field = $obj->_createField( $obj->getClassName(), $fieldInfo->{name}, $fieldInfo );
  $obj->{fields}->{$originalFieldName}        = $field;
  $obj->{renamedFields}->{$originalFieldName} = $fieldInfo->{name} if $originalFieldName ne $fieldInfo->{name};
  push @{ $obj->{modifiedFields} }, $originalFieldName;
  $obj->_getInitModelCodeObject()->modifyField($originalFieldName, $field);
}
#-----------------------------------------------------------------------------
sub deleteField {
  my ($obj, $fieldName) = @_;
  my $field = $obj->{fields}->{$fieldName};
  my $className = $obj->getClassName();
  if ($field->isListField()) {
    require O2::Setup::ScriptGenerator;
    my $script = O2::Setup::ScriptGenerator->newSetupScriptForClass(
      $className,
      runOnlyOnce => 1,
    );
    my $listTableName = $field->getListTableName();
    my $sqlReadyFieldName = $db->glob2like( $field->getName() );
    $script->addCodeLine( qq{my \@objectIds = \$db->selectColumn("select objectId from O2_OBJ_OBJECT where className = '$className'");} );
    $script->addCodeLine(  q[foreach my $id (@objectIds) {]                                                                             );
    $script->addCodeLine( qq{  \$db->do("delete from $listTableName where objectId = ? and name like '$sqlReadyFieldName.%'", \$id);}   );
    $script->addCodeLine( qq[}]                                                                                                         );
    $script->writeScriptFile();
    $script->run();
  }
  delete $obj->{fields}->{$fieldName};
  $obj->{deletedFields}->{$fieldName} = 1;
  $obj->_getInitModelCodeObject()->deleteField($fieldName);
}
#-----------------------------------------------------------------------------
sub deleteClass {
  my ($obj, $deleteDbTable, $deleteDbObjects) = @_;
  my $className = $obj->getClassName();
  my $tableName = $obj->getTableName();

  # Create and run upgrade script
  if ($deleteDbTable || $deleteDbObjects) {
    require O2::Setup::ScriptGenerator;
    my $script = O2::Setup::ScriptGenerator->newSetupScriptForClass(
      $className,
      runOnlyOnce => 1,
    );
    if ($deleteDbObjects) {
      $script->addCodeLine( qq{my \@objectIds = \$db->selectColumn("select objectId from O2_OBJ_OBJECT where className = '$className'");} );
      $script->addCodeLine(  q[foreach my $id (@objectIds) {]                                                                             );
      $script->addCodeLine(  q{  my $object = $context->getObjectById($id) || $context->getUniversalMgr()->getTrashedObjectById($id);}    );
      $script->addCodeLine(  q{  $object->deletePermanently();}                                                                           );
      $script->addCodeLine(  q[}]                                                                                                         );
    }
    if ($deleteDbTable) {
      $script->addCodeLine(  q{my $schemaMgr    = $context->getSingleton('O2::DB::Util::SchemaManager');} );
      $script->addCodeLine(  q{my $dbIntrospect = $context->getSingleton('O2::DB::Util::Introspect');}    );
      $script->addCodeLine( qq[if (\$dbIntrospect->tableExists('$tableName')) {]                          );
      $script->addCodeLine( qq{  \$schemaMgr->dropTable('$tableName');}                                   );
      $script->addCodeLine(  q[}]                                                                         );
    }
    $script->writeScriptFile();
    $script->run();
  }

  # Delete object and manager files
  my $objectFileName  = $obj->_classNameToPath( $className                  );
  my $managerFileName = $obj->_classNameToPath( $obj->getManagerClassName() );
  my $fileMgr = $context->getSingleton('O2::File');
  $fileMgr->rmFile( $objectFileName  );
  $fileMgr->rmFile( $managerFileName );

  # Delete test script
  my $testScriptPath = $obj->_getTestScriptPath();
  $fileMgr->rmFile($testScriptPath) if -f $testScriptPath;
}
#-----------------------------------------------------------------------------
sub renameClass {
  my ($obj, $newClassName) = @_;
  my $oldClassName        = $obj->getClassName();
  my $oldManagerClassName = $obj->getManagerClassName();
  my $oldTableName        = $obj->getTableName();
  my $oldTestScriptPath   = $obj->_getTestScriptPath();
  $obj->setClassName($newClassName);
  my $newManagerClassName = $obj->getManagerClassName();
  my $newTableName        = $obj->getTableName();
  my $newTestScriptPath   = $obj->_getTestScriptPath();

  # Rename and update object and manager files
  $obj->_createMissingFiles();
  my %replacements = (
    $oldClassName        => $newClassName,
    $oldManagerClassName => $newManagerClassName,
  );
  $obj->_renameAndUpdateFile( $obj->_classNameToPath($oldClassName),        $obj->_classNameToPath($newClassName),        %replacements );
  $obj->_renameAndUpdateFile( $obj->_classNameToPath($oldManagerClassName), $obj->_classNameToPath($newManagerClassName), %replacements );

  # Create and run upgrade script for the database changes
  require O2::Setup::ScriptGenerator;
  my $script = O2::Setup::ScriptGenerator->newSetupScriptForClass(
    $newClassName,
    runOnlyOnce    => 1,
    beforeDbUpdate => 1,
  );
  $script->addCodeLine(  q{my $schemaMgr    = $context->getSingleton('O2::DB::Util::SchemaManager');}                          );
  $script->addCodeLine(  q{my $dbIntrospect = $context->getSingleton('O2::DB::Util::Introspect');}                             );
  $script->addCodeLine( qq{if (\$dbIntrospect->tableExists('$oldTableName')) \{}                                               );
  $script->addCodeLine( qq{  \$schemaMgr->renameTable('$oldTableName', '$newTableName');}                                      );
  $script->addCodeLine(  q{\}}                                                                                                 );
  $script->addCodeLine( qq{\$db->do("update O2_OBJ_OBJECT set className = '$newClassName' where className = '$oldClassName'")} );
  $script->writeScriptFile();
  $script->run();

  # Rename and update test script
  $obj->_renameAndUpdateFile($oldTestScriptPath, $newTestScriptPath, %replacements) if -f $oldTestScriptPath;
}
#-----------------------------------------------------------------------------
sub _renameAndUpdateFile {
  my ($obj, $oldFileName, $newFileName, %replacements) = @_;
  my $fileMgr = $context->getSingleton('O2::File');
  my $fileContent = $fileMgr->getFile($oldFileName);
  foreach my $oldString (keys %replacements) {
    $fileContent =~ s{ \Q$oldString\E }{$replacements{$oldString}}xmsg;
  }
  $fileMgr->writeFile($newFileName, $fileContent);
  $fileMgr->rmFile($oldFileName);
}
#-----------------------------------------------------------------------------
sub save {
  my ($obj) = @_;
  $obj->_createMissingFiles();
  $obj->_updateBaseClass();
  $obj->_updateInitModel();
  $obj->_saveObjectSourceCode();
  $obj->_saveManagerSourceCode();
  $obj->_updateDataBase();
  $obj->_updateTestScript();
  $obj->{addedFields}    = [];
  $obj->{modifiedFields} = [];
  $obj->{deletedFields}  = {};
  $obj->{renamedFields}  = {};
}
#-----------------------------------------------------------------------------
sub _createMissingFiles {
  my ($obj) = @_;
  my $objectPath  = eval { $obj->_classNameToPath( $obj->getClassName()        ) };
  my $managerPath = eval { $obj->_classNameToPath( $obj->getManagerClassName() ) };
  return if $objectPath && $managerPath;
  
  require O2::Model::Target::Skeleton;
  my $currentRoot  =  $obj->getClassName() =~ m{ \A O2:: }xms  ?  $context->getEnv('O2ROOT')  :  $context->getEnv('O2CUSTOMERROOT');
  my $skeletonGenerator = O2::Model::Target::Skeleton->new();
  $skeletonGenerator->setArg('currentRoot', $currentRoot);
  return $skeletonGenerator->generate( $obj, beQuiet => 1                         )     if !$objectPath && !$managerPath;
  return $skeletonGenerator->generate( $obj, beQuiet => 1, dontCreateManager => 1 ) unless  $objectPath;
  return $skeletonGenerator->generate( $obj, beQuiet => 1, dontCreateObject  => 1 ) unless  $managerPath;
}
#-----------------------------------------------------------------------------
sub _updateBaseClass {
  my ($obj) = @_;
  my $objectSourceCode  = $obj->_getObjectSourceCode();
  my $managerSourceCode = $obj->_getManagerSourceCode();
  my ($oldObjectUseBaseLine)  = $objectSourceCode  =~ m{ ^ ([\t ]* use \s+ base \s+ [\"\'] \w+::Obj::.+? [\"\'] \s* ;) }xms;
  my ($oldManagerUseBaseLine) = $managerSourceCode =~ m{ ^ ([\t ]* use \s+ base \s+ [\"\'] \w+::Mgr::.+? [\"\'] \s* ;) }xms;
  $objectSourceCode  =~ s{ \Q$oldObjectUseBaseLine\E  }{ "use base '" . $obj->getSuperClassName()        . "';" }xmse;
  $managerSourceCode =~ s{ \Q$oldManagerUseBaseLine\E }{ "use base '" . $obj->getManagerSuperClassName() . "';" }xmse;
  $obj->_setObjectSourceCode(  $objectSourceCode  );
  $obj->_setManagerSourceCode( $managerSourceCode );
}
#-----------------------------------------------------------------------------
sub _modelIsChanged {
  my ($obj) = @_;
  return  @{ $obj->{addedFields} }  ||  @{ $obj->{modifiedFields} }  ||  %{ $obj->{deletedFields} }  ||  %{ $obj->{renamedFields} };
}
#-----------------------------------------------------------------------------
sub _updateInitModel {
  my ($obj) = @_;
  $obj->_getInitModelCodeObject()->writeCodeToFile() if $obj->_modelIsChanged();
}
#-----------------------------------------------------------------------------
sub _saveObjectSourceCode {
  my ($obj) = @_;
  my $code = $obj->_getObjectSourceCode();
  my $filePath = $obj->_classNameToPath( $obj->getClassName() );
  my $fileMgr = $context->getSingleton('O2::File');
  return if $code eq $fileMgr->getFile($filePath);
  
  $fileMgr->writeFile($filePath, $code);
  eval $code; # To make sure the object is represented correctly in memory
}
#-----------------------------------------------------------------------------
sub _saveManagerSourceCode {
  my ($obj) = @_;
  my $code = $obj->_getManagerSourceCode();
  my $filePath = $obj->_classNameToPath( $obj->getManagerClassName() );
  my $fileMgr = $context->getSingleton('O2::File');
  return if $code eq $fileMgr->getFile($filePath);
  
  $fileMgr->writeFile($filePath, $code);
  eval $code; # To make sure the manager is represented correctly in memory
}
#-----------------------------------------------------------------------------
sub _updateDataBase {
  my ($obj) = @_;
  return unless $obj->_modelIsChanged();
  
  my $tableName = $obj->getTableName();
  my $className = $obj->getClassName();

  # Handle renamed fields: Update database and generate upgrade-script
  require O2::Setup::ScriptGenerator;
  my $script = O2::Setup::ScriptGenerator->newSetupScriptForClass(
    $className,
    runOnlyOnce    => 1,
    beforeDbUpdate => 1,
  );
  my ($doWriteFile, $isFirstListField, $isFirstNormalField) = (0, 1, 1);
  foreach my $originalFieldName (keys %{ $obj->{renamedFields} }) {
    my $field = $obj->getFieldByName($originalFieldName);
    next if !$field || $field->isMetaField();
    
    my $newFieldName = $obj->{renamedFields}->{$originalFieldName};
    if ($field->isListField()) {
      # Give new value to "name" fields in list table (f ex O2_OBJ_OBJECT_VARCHAR) for objects of this class. Generate upgrade script for it, too.
      my $listTableName = $field->getListTableName();
      my $sqlReadyOriginalFieldName = $db->glob2like($originalFieldName);
      $script->addCodeLine( qq{my \@objectIds = \$db->selectColumn("select objectId from O2_OBJ_OBJECT where className = '$className'");}    ) if $isFirstListField;
      $script->addCodeLine(  q[foreach my $id (@objectIds) {]                                                                                ) if $isFirstListField;
      $script->addCodeLine( qq{  my \@names = \$db->selectColumn("select name from $listTableName where objectId = ? and name like '$sqlReadyOriginalFieldName.%'", \$id);} );
      $script->addCodeLine(  q[  foreach my $name (@names) {]                                                                                );
      $script->addCodeLine(  q{    my $newName = $name;}                                                                                     );
      $script->addCodeLine( qq{    \$newName    =~ s{ \\A \\Q$originalFieldName\\E [.] }{$newFieldName.}xms;}                                );
      $script->addCodeLine( qq{    \$db->do("update $listTableName set name = ? where objectId = ? and name = ?", \$newName, \$id, \$name);} );
      $script->addCodeLine( qq[  }]                                                                                                          );
      $script->addCodeLine( qq[}]                                                                                                            ) if $isFirstListField;
      $isFirstListField = 0;
    }
    else {
      $script->addCodeLine( qq{my \$table = \$context->getSingleton('O2::DB::Util::Introspect')->getTable('$tableName');} ) if $isFirstNormalField;
      $script->addCodeLine( qq[if (\$table->hasColumn('$originalFieldName')) {]                                           );
      $script->addCodeLine(  q{  my $schemaMgr = $context->getSingleton('O2::DB::Util::SchemaManager');}                  );
      $script->addCodeLine( qq{  \$schemaMgr->renameColumn('$tableName', '$originalFieldName', '$newFieldName');}         );
      $script->addCodeLine(  q[}]                                                                                         );
      $isFirstNormalField = 0;
    }
    $doWriteFile = 1;
  }
  if ($doWriteFile) {
    $script->writeScriptFile();
    $script->run();
  }

  $context->getSingleton('O2::DB::Util::SchemaManager')->updateTableForClass( $className, okToDrop => 1 );
}
#-----------------------------------------------------------------------------
sub _updateTestScript {
  my ($obj) = @_;
  require O2::Model::Target::Test;
  my $testGenerator  = O2::Model::Target::Test->new();
  my $testScriptPath = $obj->_getTestScriptPath($testGenerator);
  my $fileGenerator  = $context->getSingleton('O2::Util::FileGenerator');
  if ( !-e $testScriptPath  ||  $fileGenerator->fileIsAutoGenerated($testScriptPath) ) {
    $fileGenerator->writeFile( $testScriptPath, $testGenerator->generateTestScript($obj) );
  }
}
#-----------------------------------------------------------------------------
sub _getTestScriptPath {
  my ($obj, $testGenerator) = @_;
  if (!$testGenerator) {
    require O2::Model::Target::Test;
    $testGenerator = O2::Model::Target::Test->new();
  }
  my $currentRoot = $obj->getClassName() =~ m{ \A O2:: }xms  ?  $context->getEnv('O2ROOT')  :  $context->getEnv('O2CUSTOMERROOT');
  $testGenerator->setArg('currentRoot', $currentRoot);
  return $testGenerator->getTestScriptPath($obj);
}
#-----------------------------------------------------------------------------
sub _getInitModelCodeObject {
  my ($obj) = @_;
  return $obj->{initModelCodeObject} if $obj->{initModelCodeObject};
  require O2::Obj::Object::Model::InitModelCode;
  return $obj->{initModelCodeObject} = O2::Obj::Object::Model::InitModelCode->new($obj);
}
#-----------------------------------------------------------------------------
sub _getInitModelCode {
  my ($obj) = @_;
  my $code = $obj->getCodeForManagerMethod('initModel');
  return $code if $code;
  die "No initModel code";
}
#-----------------------------------------------------------------------------
sub getCodeForManagerMethod {
  my ($obj, $methodName) = @_;
  return $obj->_getCodeForMethod('mgr', $methodName);
}
#-----------------------------------------------------------------------------
sub getCodeForObjectMethod {
  my ($obj, $methodName) = @_;
  return $obj->_getCodeForMethod('obj', $methodName);
}
#-----------------------------------------------------------------------------
sub _getCodeForClassName {
  my ($obj, $className) = @_;
  my $filePath = $obj->_classNameToPath($className);
  return $context->getSingleton('O2::File')->getFile($filePath);
}
#-----------------------------------------------------------------------------
sub _getObjectSourceCode {
  my ($obj) = @_;
  return $obj->{objectSourceCode} ||= $obj->_getCodeForClassName( $obj->getClassName() );
}
#-----------------------------------------------------------------------------
sub _setObjectSourceCode {
  my ($obj, $code) = @_;
  $obj->{objectSourceCode} = $code;
}
#-----------------------------------------------------------------------------
sub _getManagerSourceCode {
  my ($obj) = @_;
  return $obj->{managerSourceCode} ||= $obj->_getCodeForClassName( $obj->getManagerClassName() );
}
#-----------------------------------------------------------------------------
sub _setManagerSourceCode {
  my ($obj, $code) = @_;
  $obj->{managerSourceCode} = $code;
}
#-----------------------------------------------------------------------------
sub _getCodeForMethod {
  my ($obj, $objOrMgr, $methodName) = @_;
  my $_methodName = $objOrMgr eq 'obj' ? '_getObjectSourceCode' : '_getManagerSourceCode';
  my $code = $obj->$_methodName();
  my ($methodCode) = $code =~ m{   (  ^ sub \s+ $methodName \s+ \{ .*? ^ \}  )   }xms; # XXX Must improve this!
  return $methodCode;
}
#-----------------------------------------------------------------------------
sub _classNameToPath { # XXX Should move this to O2::Util somewhere, perhaps..
  my ($obj, $className) = @_;
  $className =~ s{ :: }{/}xmsg;
  foreach my $root ($context->getRootPaths()) {
    my $path = "$root/lib/$className.pm";
    return $path if -f $path;
  }
  die "Didn't find path to $className";
}
#-----------------------------------------------------------------------------
sub importFieldComments {
  my ($obj, $className) = @_;
  my %fieldInfo = $obj->_getInitModelCodeObject()->getFields();
  foreach my $field ( $obj->getFieldsByClassName($className) ) {
    $field->setComment(  $fieldInfo{ $field->getName() }->{comment}  );
  }
}
#-----------------------------------------------------------------------------
sub deletePermanently {
  my ($obj) = @_;
  my $fileMgr = $context->getSingleton('O2::File');
  $fileMgr->rmFile(  $obj->_classNameToPath( $obj->getClassName()        )  );
  $fileMgr->rmFile(  $obj->_classNameToPath( $obj->getManagerClassName() )  );
  my $tableName = $obj->getTableName();
  my $dbIntrospect = $context->getSingleton('O2::DB::Util::Introspect');
  my $schemaMgr    = $context->getSingleton('O2::DB::Util::SchemaManager');
  $schemaMgr->dropTable($tableName) if $dbIntrospect->tableExists($tableName);
}
#-----------------------------------------------------------------------------
sub getInheritedFields {
  my ($obj) = @_;
  my @fields;
  foreach my $field (values %{ $obj->{fields} }) {
    push @fields, $field if $field->getClassName() ne $obj->getClassName();
  }
  return @fields;
}
#-----------------------------------------------------------------------------
# return fields that are present in this class' database table
sub getTableFieldsByClassName {
  my ($obj, $className) = @_;
  return  grep  { $_->isTableField() }  $obj->getFieldsByClassName($className);
}
#-----------------------------------------------------------------------------
# return fields that are stored as lists
sub getListFields {
  my ($obj) = @_;
  return  grep  { $_->isListField() }  $obj->getFields();
}
#-----------------------------------------------------------------------------
# return fields that are multilingual
sub getMultilingualFields {
  my ($obj) = @_;

  my @fields;
  foreach my $field ($obj->getFields()) {
    push @fields, $field if $field->getMultilingual();
  }
  return @fields;
}
#-----------------------------------------------------------------------------
sub getTableName {
  my ($obj) = @_;
  my $tableName = uc $obj->getClassName();
  $tableName    =~ s{ :: }{_}xmsg;
  return $tableName;
}
#-----------------------------------------------------------------------------
# return names of all classes involved in this model
sub getClassNames {
  my ($obj) = @_;
  return @{ $obj->{classNames} };
}
#-----------------------------------------------------------------------------
sub asString {
  my ($obj) = @_;
  my $str = '';
  foreach my $field ($obj->getFields()) {
    $str .= ', ' if $str;
    $str .= $field->getName() . '[' . $field->getType();
    $str .= ",multilingual" if $field->isMultilingual();
    $str .= "]";
  }
  return $obj->getClassName()." ($str)";
}
#-----------------------------------------------------------------------------
sub setAndSaveClassComment {
  my ($obj, $comment) = @_;
  $comment =~ s{\r}{}xmsg;
  my @lines    = $obj->_getCodeForClassName( $obj->getClassName() );
  my @newLines = ('package ' . $obj->getClassName() . ";\n");
  while (@lines) {
    my $line = shift @lines;
    $line =~ s{ \A \s* package .* ; \s*}{}xms;
    if ( $line !~ m{ \A \s* \# }xms  &&  $line !~ m{ \A \s* \z }xms ) {
      unshift @lines, $line;
      last;
    }
  }
  push @newLines, "\n";
  foreach my $line (split /\n/, $comment) {
    $line  = "# $line";
    $line  =~ s{ \s+ \z }{}xms;
    $line .= "\n";
    push @newLines, $line;
  }
  push @newLines, "\n";
  @lines = (@newLines, @lines);
  my $code     = join '', @lines;
  my $filePath = $obj->_classNameToPath( $obj->getClassName() );
  $context->getSingleton('O2::File')->writeFile($filePath, $code);
}
#-----------------------------------------------------------------------------
sub getClassComment {
  my ($obj) = @_;
  my $classComment = '';
  foreach my $line ($obj->_getCodeForClassName( $obj->getClassName() )) {
    $line =~ s{ \A \s* package .* ; \s* }{}xms;
    last if $line !~ m{ \A \s* \# }xms && $line !~ m{ \A \s* \z }xms;
    my ($comment) = $line =~ m{ \A \s* \# \s? (.+) \z }xms;
    $classComment .= $comment if $comment;
  }
  return $classComment;
}
#-----------------------------------------------------------------------------
1;
