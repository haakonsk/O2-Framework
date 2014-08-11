package O2::Mgr::FileManager;
 
use strict;

use base 'O2::Mgr::ObjectManager';

use O2 qw($context);
use O2::Obj::File;

#-------------------------------------------------------------------------------
sub initModel {
  my ($obj, $model) = @_;
  $obj->SUPER::initModel($model);
  $model->registerFields(
    'O2::Obj::File',
    # Your class definition goes here:
    #-----------------------------------------------------------------------------
    title       => { type => 'varchar', multilingual => 1                              },
    fileFormat  => { type => 'varchar', length => 32, notNull => 1, defaultValue => '' },
    description => { type => 'text',    multilingual => 1                              },
    isOnline    => { type => 'bit',     defaultValue => 1                              },
    #-----------------------------------------------------------------------------
  );
}
#-------------------------------------------------------------------------------
sub save {
  my ($obj, $object) = @_;
  my $isUpdate = $object->getId() > 0;
  $obj->SUPER::save($object);
  
  if ($object->hasUnsavedContent()) {
    die "Can't save file '" . $object->getMetaName() . "' without fileformat" unless $object->getFileFormat();
    $context->getSingleton('O2::File')->writeFile( $object->getCreatedFilePath(), $object->getUnsavedContentRef() );
    $object->clearUnsavedContent();
  }
  $obj->_saveListFields( $object, $obj->getModel(), $isUpdate );
  
  if ($context->cmsIsEnabled()) {
    eval {
      require O2CMS::Search::ObjectIndexer;
      my $indexer = O2CMS::Search::ObjectIndexer->new();
      $indexer->addOrUpdateObject($object);
    };
    if ($@) {
      my $errorMsg = $@;
      warning "Could not index file " . $object->getMetaName() . ": $errorMsg";
    }
  }
  
  # make sure 
  $obj->_renameIfDeleted($object);
  
  # if online status has changed we need to copy the file to approriate place
  if ( defined ($object->{_oldIsOnlineStatus})  &&  $object->isOnline() != $object->{_oldIsOnlineStatus}) {
    $obj->_moveToRepository($object);
  }
}
#---------------------------------------------------------------------------------------------------
sub _saveListFields {
  my ($obj, $object, $model, $isUpdate) = @_;
  
  # Do not try to run the SUPER _saveListFields unless the file has an existing file path
  return unless -e $object->getFilePath();
  $obj->SUPER::_saveListFields($object, $model, $isUpdate);
}
#---------------------------------------------------------------------------------------------------
# rename directory where file lies to directoryName.deleted if object is deleted. rename back if file becomes "alive" again
sub _renameIfDeleted {
  my ($obj, $object) = @_;
  my $dir = $object->getFileDirectory();
  my $deleteDir = "$dir.deleted";
  my $console = $context->getConsole();
  
  if ( !$object->isDeleted() && !-e $deleteDir ) {
    # If the object is not yet deleted but the source (deleteDir) does not exists,
    # we have to try to reverse the isOnline to get the correct destination path.
    $object->setIsOnline( !$object->isOnline() );
    $deleteDir = $object->getFileDirectory() . '.deleted';
    $object->setIsOnline( !$object->isOnline() );
  }
  
  my $fileMgr = $context->getSingleton('O2::File');
  if ( $object->isDeleted() ) {
    $object->setIsOnline(0);
    return if -e $deleteDir; # directory already moved to .deleted
    
    if (-e $dir) {
      $fileMgr->move($dir, $deleteDir);
    }
    else {
      warning "$dir doesn't exist";
    }
  }
  else {
    return if -e $dir; # directory already has normal name
    $fileMgr->move($deleteDir, $dir) if -e $deleteDir;
  }
}
#-------------------------------------------------------------------------------
sub _moveToRepository {
  my ($obj, $object) = @_;
  
  my $newStatus = $object->isOnline();
  $object->setIsOnline( $object->{_oldIsOnlineStatus} );
  my $srcDirectory = $object->getFileDirectory();
  
  $object->setIsOnline($newStatus);
  my $targetDirectory = $object->getFileDirectory();
  
  if ($object->isDeleted()) {
    $srcDirectory    .= '.deleted';
    $targetDirectory .= '.deleted';
  }
  else {
    ($srcDirectory, $targetDirectory) = ($targetDirectory, $srcDirectory);
    $object->setIsOnline(1);
  }
  
  if (!-e $srcDirectory && $object->isTrashed()) {
    warning "$srcDirectory doesn't exist"; # Don't die when moving things to trash
    return 0;
  }
  
  my $fileMgr = $context->getSingleton('O2::File');
  if (!-d $targetDirectory) {
    eval {
      $fileMgr->mkPath($targetDirectory);
    };
    warning $@ if $@;
  }
  $fileMgr->move($srcDirectory, $targetDirectory);
  
  return 1;
}
#-------------------------------------------------------------------------------
sub getFileFormatByContentType {
  my ($obj, $contentType) = @_;
  die "getFileFormatByContentType is not implemented";
}
#-------------------------------------------------------------------------------
sub newFileFromCgiFile {
  my ($obj, $cgiFile) = @_;
  my $file = $obj->newObject();
  $file->setContentFromPath( $cgiFile->getTmpFile() );
  my ($fileNameExt) = $cgiFile->getFileName() =~ m/.+\.(\w+)/xms;
  $file->setFileFormat( $fileNameExt            );
  $file->setMetaName (  $cgiFile->getFileName() );
  return $file;
}
#-------------------------------------------------------------------------------
# remove object from database + remove file
sub deleteObjectPermanentlyById {
  my ($obj, $objectId) = @_;
  
  # Delete file
  my $path    = $context->getObjectById($objectId)->getFilePath();
  my $fileMgr = $context->getSingleton('O2::File');
  $fileMgr->rmFile($path);
  $fileMgr->rmEmptyDirs($path);
  
  $obj->SUPER::deleteObjectPermanentlyById($objectId);
}
#-------------------------------------------------------------------------------
1;
