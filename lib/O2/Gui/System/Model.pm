package O2::Gui::System::Model;

use strict;

use base 'O2::Gui';

use O2 qw($context $cgi);
use O2::Util::List qw(upush);

#-----------------------------------------------------------------------------
sub init {
  my ($obj) = @_;
  $obj->display('init.html');
}
#-----------------------------------------------------------------------------
sub showClasses {
  my ($obj) = @_;
  $context->getSingleton('O2::Util::ClassDocumentation')->generate();
  $obj->display(
    'showClasses.html',
    objectClasses => { $context->getSingleton('O2::Util::ObjectIntrospect')->getAllObjectClasses() },
  );
}
#-----------------------------------------------------------------------------
sub showClass {
  my ($obj, $template) = @_;
  my $model = $obj->_getModel();

  my $introspector = $context->getSingleton('O2::Util::ObjectIntrospect');
  $introspector->setClass( $model->getClassName() );
  my @subClasses     = $model->getClassName() eq 'O2::Obj::Object'  ?  ()  :  $introspector->getSubClasses();
  my %nativeFields   = map  { $_->getName() => 1 }  $model->getFieldsByClassName( $obj->getParam('package') );
  my %metaFields     = map  { $_->getName() => 1 }  $model->getFieldsByClassName('O2::Obj::Object');
  my @allFields      = $model->getFields();
  my @inheritedFields;
  foreach my $field (@allFields) {
    push @inheritedFields, $field if !$nativeFields{ $field->getName() }  &&  !$metaFields{ $field->getName() };
  }

  $introspector->setClass('O2::Obj::Object');
  my %o2ObjObjectMethods  =  map { $_ => 1 }  $introspector->getPublicNativeMethods();
  $introspector->setClass( $model->getClassName() );

  my %overriddenMethods               =  map   { $_ => 1                                             }  $introspector->getPublicOverriddenMethods();
  my @inheritedMethods                =  grep  { !$o2ObjObjectMethods{$_} && !$overriddenMethods{$_} }  $introspector->getPublicInheritedMethods();
  my @nativePublicUnoverriddenMethods =  grep  { !$overriddenMethods{$_}                             }  $introspector->getPublicNativeMethods();
  my @o2ObjObjectMethods;
  foreach my $methodName (keys %o2ObjObjectMethods) {
    push @o2ObjObjectMethods, $methodName if !$overriddenMethods{$methodName};
  }

  require O2::Obj::Object::Model::Field;
  my $newField = O2::Obj::Object::Model::Field->new(model => $model);

  my $dbIntrospect = $context->getSingleton('O2::DB::Util::Introspect');
  my $tableName = $obj->_classNameToTableName( $obj->getParam('package') );
  my $table = $dbIntrospect->getTable($tableName);

  my $classComment = $model->getClassComment() || 'No comment';
  $classComment    =~ s{ \n+ \z }{}xms;
  $classComment    =~ s{ \n }{<br>\n&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;}xmsg;

  $template ||= 'showClass.html';

  $obj->display(
    $template,
    model               => $model,
    nativeFields        => [  $model->getFieldsByClassName( $obj->getParam('package') )  ],
    inheritedFields     => \@inheritedFields,
    subClasses          => \@subClasses,
    publicNativeMethods => \@nativePublicUnoverriddenMethods,
    inheritedMethods    => \@inheritedMethods,
    overriddenMethods   => [ keys %overriddenMethods ],
    o2ObjObjectMethods  => \@o2ObjObjectMethods,
    table               => $table,
    newField            => $newField,
    classComment        => $classComment,
    gui                 => $obj,
  );
}
#-----------------------------------------------------------------------------
sub _classNameToTableName {
  my ($obj, $className) = @_;
  my $tableName = uc $className;
  $tableName    =~ s{ :: }{_}xmsg;
  return $tableName;
}
#-----------------------------------------------------------------------------
sub saveComment {
  my ($obj) = @_;
  $obj->_getModel()->setAndSaveClassComment( $obj->getParam('comment') );
  $obj->_redirectToShowClass('Comment changed');
}
#-----------------------------------------------------------------------------
sub saveBaseClass {
  my ($obj, $model) = @_;
  my $noRedirect = $model ? 1 : 0;
  my $errorMsg = $obj->_getSuperClassErrorMsg( $obj->getParam('baseClass') );
  $obj->_redirectToShowClass("Couldn't save base class: $errorMsg", 'error') if $errorMsg;

  $model ||= $obj->_getModel();
  $model->setSuperClassName( $obj->getParam('baseClass') );
  $model->save();
  $obj->_redirectToShowClass('Base class saved') unless $noRedirect;
}
#-----------------------------------------------------------------------------
sub saveField { # Both modify and add
  my ($obj) = @_;
  my $model = $obj->_getModel();

  my %availableTypes = map { $_ => 1 } $model->getAvailableFieldTypes();
  if (!$availableTypes{ $obj->getParam('type') }  &&  $obj->getParam('type') !~ m{ :: }xms) {
    $obj->_redirectToShowClass("Couldn't save field '" . $obj->getParam('name') . "': Field type must be chosen from the drop down menu or else it must be a class name", 'error');
  }

  my $originalName = $obj->getParam('originalName') || $obj->getParam('name');
  my $field = eval { $model->getFieldByName($originalName); };

  my $validValues = $obj->getParam('validValues');
  $validValues    = '' unless defined $validValues;
  my @validValues = split /,\s*/, $validValues;
  @validValues = map { $_ =~ s{ \n }{}xmsg; $_ } @validValues; # Remove new-lines

  my $methodName = $obj->getParam('originalName') ? 'modifyField' : 'addField';
  $model->$methodName(
    $originalName,
    {
      name         => $obj->getParam('name'),
      type         => $obj->getParam('type'),
      length       => $obj->getParam('length'),
      listType     => $obj->getParam('listType'),
      notNull      => $obj->getParam('notNull'),
      multilingual => $obj->getParam('isMultilingual'),
      defaultValue => $obj->getParam('defaultValue'),
      validValues  => \@validValues,
      comment      => $obj->getParam('comment'),
    }
  );
  $model->save();
  $obj->_redirectToShowClass("Field '" . $obj->getParam('name') . "' saved");
}
#-----------------------------------------------------------------------------
sub saveClassName {
  my ($obj) = @_;
  my $oldClassName = $obj->getParam('package');
  my $newClassName = $obj->getParam('newClassName');
  $obj->_redirectToShowClass('No change in class name', 'warning') if $oldClassName eq $newClassName;
  $obj->_getModel()->renameClass($newClassName);
  $cgi->setParam( 'package', $obj->getParam('newClassName') );
  $obj->_redirectToShowClass("Renamed $oldClassName to $newClassName");
}
#-----------------------------------------------------------------------------
sub saveNewClass {
  my ($obj) = @_;
  my $className = $obj->getParam('name');

  # Validate class name
  $obj->_redirectToShowClass("Couldn't create class '$className': Doesn't contain the string '::Obj::'", 'error') if $className !~ m{ ::Obj:: }xms;
  
  my $object = eval { $context->getSingleton($className); };
  $obj->_redirectToShowClass("Couldn't create class '$className': Already exists", 'error') if $object;

  my $modelMgr = $context->getSingleton('O2::Mgr::Object::ModelManager');
  my $model = $modelMgr->newObjectByClassName($className);
  $model->save();

  $obj->saveBaseClass($model) if $obj->getParam('useGivenBaseClass');

  $cgi->setParam('package', $className);
  $obj->_redirectToShowClass("Class '$className' created");
}
#-----------------------------------------------------------------------------
# Not quite delete.. Have to inherit from O2::Obj::Object.
sub deleteBaseClass {
  my ($obj) = @_;
  my $model = $obj->_getModel();
  $model->setSuperClassName('O2::Obj::Object');
  $model->save();
  $obj->_redirectToShowClass('Base class reset to O2::Obj::Object');
}
#-----------------------------------------------------------------------------
sub deleteClass {
  my ($obj) = @_;
  my $className = $obj->getParam('package');
  $obj->_getModel()->deleteClass( $obj->getParam('deleteDbTable'), $obj->getParam('deleteObjects') );
  $cgi->setParam('package', 'O2::Obj::Object');
  $obj->_redirectToShowClass("$className deleted");
}
#-----------------------------------------------------------------------------
sub deleteField {
  my ($obj) = @_;
  my $model = $obj->_getModel();
  $model->deleteField( $obj->getParam('fieldName') );
  $model->save();
  $obj->_redirectToShowClass("Field '" . $obj->getParam('fieldName') . "' deleted");
}
#-----------------------------------------------------------------------------
sub getFieldTypeAndLength {
  my ($obj, $field) = @_;
  my $typeAndLength = $field->getType();
  $typeAndLength   .= '(' . $field->getLength() . ')' if $field->getLength();
  return $typeAndLength;
}
#-----------------------------------------------------------------------------
sub showRegisterClassForm {
  my ($obj) = @_;
  my $className = $obj->getParam('package');
  my $model = $obj->_getModel();

  my $introspector = $context->getSingleton('O2::Util::ObjectIntrospect');
  $introspector->setClass('O2CMS::Obj::Category');
  my @categories = $introspector->getSubClassesRecursive();

  require O2::Model::Target::RegisterClass;
  my $registerClassGenerator = O2::Model::Target::RegisterClass->new();

  my $class = $context->getSingleton('O2::Mgr::ClassManager')->getObjectByClassName($className);
  my $defaultEditTemplate = $class->getDefaultEditTemplate();

  if (my $superClassName = $registerClassGenerator->getUnregisteredSuperClassName($model)) {
    return $obj->display(
      'showRegisterClassForm.html',
      superClassName          => $superClassName,
      superClassNotRegistered => 1,
      categories              => \@categories,
      defaultEditTemplate     => $defaultEditTemplate,
    );
  }
  $obj->display(
    'showRegisterClassForm.html',
    class               => $class,
    categories          => \@categories,
    defaultEditTemplate => $defaultEditTemplate,
  );
}
#-----------------------------------------------------------------------------
sub registerClass {
  my ($obj) = @_;
  eval {
    $context->getSingleton('O2::Model::Target::RegisterClass')->generate( $obj->_getModel(), $obj->getParams() );
  };
  my $errorMsg = $@;
  
  my $classMgr = $context->getSingleton('O2::Mgr::ClassManager');
  $classMgr->loadClasses();
  $obj->display(
    'registerClass.html',
    errorMsg => $errorMsg,
    class    => $classMgr->getObjectByClassName( $obj->getParam('package') ),
  );
}
#-----------------------------------------------------------------------------
sub showIconUploadForm {
  my ($obj) = @_;
  
  my $size = 48;
  my $fileMgr = $context->getSingleton('O2::File');
  my $iconMgr = $context->getSingleton('O2::Image::IconManager');
  my @icons;
  my @iconFileNames = $fileMgr->scanDirRecursive( 'o2://' . $iconMgr->getRelativeIconDir(), "*$size*", scanAllO2Dirs => 1 );
  
  foreach my $path (@iconFileNames) {
    next if $path =~ m{ icon-missing }xmsi;
    
    my $name = $path;
    $name    =~ s{ \A .* /           }{}xms;
    $name    =~ s{ -$size [.] \w+ \z }{}xms;
    
    push @icons, {
      name => $name,
      url  => "/images/icons/o2default/$path",
      path => $fileMgr->resolvePath($path),
    };
  }
  
  $obj->display(
    'showIconUploadForm.html',
    icons     => \@icons,
    size      => $size,
    isO2Class => $obj->getParam('package') =~ m{ \A O2(?:CMS)?:: }xms ? 1 : 0,
  );
}
#-----------------------------------------------------------------------------
sub _uploadIcon {
  my ($obj) = @_;
  my %q = $obj->getParams();
  die "No files uploaded" if !$q{icon16} && !$q{icon24} && !$q{icon32} && !$q{icon48} && !$q{icon64} && !$q{icon128};
  
  my $fileMgr = $context->getSingleton( 'O2::File'               );
  my $iconMgr = $context->getSingleton( 'O2::Image::IconManager' );
  
  my $className = $q{package} or die 'package parameter missing';
  my $iconDir   = $q{iconDir} or die 'iconDir parameter missing';
  $iconDir     .= '/' . $iconMgr->getRelativeIconDir( $obj->getParam('package') );
  
  # Delete icons in the directory we're uploading to
  $fileMgr->rmFile( $iconDir, '-rf'   ) if -d $iconDir;
  $fileMgr->mkPath( $iconDir, oct 775 );
  
  my $previousFile;
  foreach my $size (128, 64, 48, 32, 24, 16) {
    my $file = $q{"icon$size"} || $previousFile or next;
    $previousFile = $file;
    
    my $extension = 'png';
    my $fileName = $iconMgr->getIconFileName($className, $size, $extension);
    
    require O2::Image::Image;
    my $content = join '', $file->getFileContent();
    my $image = O2::Image::Image->newFromImageContent($content, $extension);
    $image->resizeNoAspectRatio($size, $size) if $image->getWidth() != $size || $image->getHeight() != $size;
    $image->write("$iconDir/$fileName");
  }
  $cgi->addHeader('Cache-Control', 'no-cache, must-revalidate');
  $obj->display(
    'updateIcon.html',
    newIconUrls => [ $obj->_getIconUrls($iconDir, $className) ],
  );
}
#-----------------------------------------------------------------------------
sub updateIcon {
  my ($obj) = @_;
  
  return $obj->_uploadIcon() if $obj->getParam('uploadOrSelect') eq 'upload';
  
  my $iconMgr = $context->getSingleton( 'O2::Image::IconManager' );
  my $fileMgr = $context->getSingleton( 'O2::File'               );
  
  my $selectedIconPath = $obj->getParam('icon');
  my ($oldIconDir)     = $selectedIconPath =~ m{ \A (.*) / }xms;
  my $className        = $obj->getParam('package');
  my $newIconDir       = $obj->getParam('iconDir') . '/' . $iconMgr->getRelativeIconDir( $obj->getParam('package') );
  
  $fileMgr->mkPath($newIconDir);
  foreach my $oldFile ($fileMgr->scanDir($oldIconDir, '\d')) {
    my ($size, $extension) = $oldFile =~ m{ - (\d+) [.] (\w+) \z }xms;
    my $newFile = $iconMgr->getIconFileName($className, $size, $extension);
    $fileMgr->cpFile("$oldIconDir/$oldFile", "$newIconDir/$newFile");
  }
  
  $cgi->addHeader('Cache-Control', 'no-cache, must-revalidate');
  $obj->display(
    'updateIcon.html',
    newIconUrls => [ $obj->_getIconUrls($newIconDir, $className) ],
  );
}
#-----------------------------------------------------------------------------
sub _getIconUrls {
  my ($obj, $dir, $className) = @_;
  my $iconMgr = $context->getSingleton( 'O2::Image::IconManager' );
  my $fileMgr = $context->getSingleton( 'O2::File'               );
  my @iconFiles = $fileMgr->scanDir($dir, '\d');
  my @newIconUrls = map {
    my ($size) = $_ =~ m{ -(\d+) [.] \w+ \z }xms;
    $iconMgr->getIconUrl($className, $size);
  } @iconFiles;
  @newIconUrls = sort {
    my ($size1) = $a =~ m{ -(\d+) [.] \w+ \z }xms;
    my ($size2) = $b =~ m{ -(\d+) [.] \w+ \z }xms;
    $size2 <=> $size1;
  } @newIconUrls;
  return @newIconUrls;
}
#-----------------------------------------------------------------------------
sub showManageIndexForm {
  my ($obj) = @_;
  my $tableName = $obj->_classNameToTableName( $obj->getParam('package') );
  my $table = $context->getSingleton('O2::DB::Util::Introspect')->getTable($tableName);
  $obj->display(
    'showManageIndexForm.html',
    indexes => [ $table->getIndexes() ],
    columns => [ $table->getColumns() ],
  );
}
#-----------------------------------------------------------------------------
sub saveIndex {
  my ($obj) = @_;

  my $newIndexName = $obj->getParam('indexName');
  my $oldIndexName = $obj->getParam('originalIndexName');
  my $tableName = $obj->_classNameToTableName( $obj->getParam('package') );

  my @columns    = $obj->getParam('columns');
  my $isUnique   = $obj->getParam('isUnique') || 0;
  my $methodName = $oldIndexName ? 'changeIndex' : 'addIndex';

  my $table     = $context->getSingleton('O2::DB::Util::Introspect')->getTable($tableName);
  my $schemaMgr = $context->getSingleton('O2::DB::Util::SchemaManager');
  if ($oldIndexName && $oldIndexName ne $newIndexName) {
    $schemaMgr->dropIndex($tableName, $oldIndexName);
    $methodName = 'addIndex';
  }
  $schemaMgr->$methodName($tableName, $newIndexName, \@columns, $isUnique);

  my $indexHash  = {
    name     => $newIndexName,
    columns  => \@columns,
    isUnique => $isUnique,
  };
  require O2::Obj::Object::Model::InitModelCode;
  my $initModelCodeObject = O2::Obj::Object::Model::InitModelCode->new( $obj->_getModel() );
  if (!$oldIndexName) {
    $initModelCodeObject->addIndex($indexHash);
  }
  else {
    $initModelCodeObject->modifyIndex($oldIndexName, $indexHash);
  }
  $initModelCodeObject->writeCodeToFile();

  $obj->showManageIndexForm();
}
#-----------------------------------------------------------------------------
sub deleteIndex {
  my ($obj) = @_;
  my $tableName = $obj->_classNameToTableName( $obj->getParam('package') );
  my $indexName = $obj->getParam('indexName');

  require O2::Obj::Object::Model::InitModelCode;
  my $initModelCodeObject = O2::Obj::Object::Model::InitModelCode->new( $obj->_getModel() );
  $initModelCodeObject->deleteIndex($indexName);
  $initModelCodeObject->writeCodeToFile();

  my $table     = $context->getSingleton('O2::DB::Util::Introspect')->getTable($tableName);
  my $schemaMgr = $context->getSingleton('O2::DB::Util::SchemaManager');
  $schemaMgr->dropIndex($tableName, $indexName);

  $obj->showManageIndexForm();
}
#-----------------------------------------------------------------------------
sub _getModel {
  my ($obj, $mgrClass) = @_;
  $mgrClass ||= $context->getUniversalMgr()->_guessManagerClassName( $obj->getParam('package') );
  my $mgr = $context->getSingleton($mgrClass);
  return $mgr->getModel();
}
#-----------------------------------------------------------------------------
sub _redirectToShowClass {
  my ($obj, $msg, $msgType) = @_;
  $msgType ||= 'info';
  my $params = 'package=' . $obj->getParam('package');
  $params   .= "&msg=$msg&msgType=$msgType" if $msg;
  $cgi->redirect(
    setMethod => 'showClass',
    setParams => $params,
  );
}
#-----------------------------------------------------------------------------
sub _getSuperClassErrorMsg {
  my ($obj, $superClass) = @_;
  my $superMgrClass = $context->getUniversalMgr()->_guessManagerClassName($superClass);
  my $mgr;
  eval {
    $mgr = $context->getSingleton($superMgrClass);
  };
  return "Couldn't instantiate $superMgrClass"                  if $@;
  return "$superClass doesn't inherit from O2::Obj::Object" unless $mgr->isa('O2::Mgr::ObjectManager');
  return '';
}
#-----------------------------------------------------------------------------
1;
