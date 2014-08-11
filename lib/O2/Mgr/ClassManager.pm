package O2::Mgr::ClassManager;

# Handles persistence and instatiation for O2::OBJ::Class objects
#
# Since we need to store all the classes in a file, anyway, this class doesn't have a corresponding database table. We're just using the file.
# This means we don't have to sync the database from the file.

use strict;

use base 'O2::Mgr::ContainerManager';

use O2 qw($context $db);
use O2::Util::List qw(upush contains);
use O2::Obj::Class;

#-----------------------------------------------------------------------------
sub new {
  my ($pkg, %init) = @_;
  my $obj = $pkg->SUPER::new(%init);
  $obj->loadClasses();
  return $obj;
}
#-----------------------------------------------------------------------------
sub loadClasses {
  my ($obj) = @_;
  $obj->{allClasses} = [];
  my $fileMgr = $context->getSingleton('O2::File');
  my @files = $fileMgr->resolveExistingPaths('o2://src/classDefinitions/O2-Obj-Class-entries.plds');
  foreach my $filePath (@files) {
    push @{ $obj->{allClasses} }, @{ eval $fileMgr->getFile($filePath) };
  }
}
#-----------------------------------------------------------------------------
sub initModel {
  my ($obj, $model) = @_;
  return;
}
#-----------------------------------------------------------------------------
sub save {
  my ($obj, $object) = @_;
  # Update src/classDefinitions/O2-Obj-Class-entries.plds in a way that doesn't mess up the formatting.
  my $fileMgr = $context->getSingleton('O2::File');
  my $classEntriesFilePath = $obj->getClassEntriesFilePath( $object->getClassName() );
  my $fileContent = -f $classEntriesFilePath  ?  $fileMgr->getFile($classEntriesFilePath)  :  '';

  my $classEntries = eval $fileMgr->getFile($classEntriesFilePath);

  my ($foundEntry, $needsSaving) = (0, 0);
  my $currentEntry;
  foreach my $entry ( @{$classEntries} ) {
    if ($entry->{className} eq $object->getClassName()) {
      require Data::Dumper;
      if (   ($entry->{editUrl}      || '')                                     ne ($object->getEditUrl()      || '')
          || ($entry->{newUrl}       || '')                                     ne ($object->getNewUrl()       || '')
          || ($entry->{editTemplate} || '')                                     ne ($object->getEditTemplate() || '')
          ||  $entry->{isCreatableInO2cms}                                      != $object->isCreatableInO2cms()
          || Data::Dumper::Dumper( eval $entry->{canBeCreatedUnderCategories} ) ne Data::Dumper::Dumper( [ $object->getCanBeCreatedUnderCategories() ] )
        ) {
        $needsSaving = 1;
      }
      $foundEntry = 1;
      $currentEntry = $entry;
      last;
    }
  }
  my $serializedCategories = join "', '", $object->getCanBeCreatedUnderCategories();
  $serializedCategories    = "'$serializedCategories'" if $serializedCategories;
  my $entryString = "  {
    className                   => '" . ($object->getClassName()    || '') . "',
    newUrl                      => '" . ($object->getNewUrl()       || '') . "',
    editUrl                     => '" . ($object->getEditUrl()      || '') . "',
    editTemplate                => '" . ($object->getEditTemplate() || '') . "',
    isCreatableInO2cms          => "  . $object->isCreatableInO2cms()      . ",
    canBeCreatedUnderCategories => [$serializedCategories],
  },";
  $entryString =~ s{ \'\' }{undef}xmsg;
  if (!$foundEntry) {
    if (!$fileContent) {
      $fileContent = "[\n$entryString\n];\n";
    }
    else {
      $fileContent =~ s{  (\},)  \s* (\];) \s* \z }{$1\n$entryString\n$2\n}xms; # Add at end of file
    }
  }
  elsif ($needsSaving) {
    my $className = $object->getClassName();
    $fileContent =~ s{ ^ \s* \{ [^\}]+ className \s* => \s* '$className'  [^\}]+  \}, }{$entryString}xms;
  }

  if (!$foundEntry || $needsSaving) {
    if (! -f $classEntriesFilePath) {
      my ($dir) = $classEntriesFilePath =~ m{ \A (.*) / [^/]+ }xms;
      $fileMgr->mkPath($dir, oct 775);
    }
    $fileMgr->writeFile($classEntriesFilePath, $fileContent);
    chmod oct (775), $classEntriesFilePath;
  }
  $obj->loadClasses();
}
#-----------------------------------------------------------------------------
sub getObjectById {
  my ($obj, $objectId) = @_;
  die 'getObjectById not available for O2::Obj::Class';
}
#-----------------------------------------------------------------------------
# returns class object based on the class it represents
sub getObjectByClassName {
  my ($obj, $className) = @_;
  my $classInfo = $obj->classSearch('className', $className);
  my $object = $obj->newObject();
  $object->setClassName($className);
  $object->init( %{$classInfo} );
  return $object;
}
#-----------------------------------------------------------------------------
# return name of all registered classes
sub getClassNames {
  my ($obj) = @_;
  my @classNames = map  { $_->{className} }  @{ $obj->{allClasses} };
  return sort @classNames;
}
#-----------------------------------------------------------------------------
# look for physical .pm files and report objects not registered as O2::Obj::Class objects
# $prefix is package prefix. i.e. 'O2::Obj'
sub getUnregisteredClasses {
  my ($obj, $prefix) = @_;
  my @classes;
  
  my $fileMgr = $context->getSingleton('O2::File');
  my $prefixDir = join '/', split /::/, $prefix;
  my %seenModules;
  foreach my $incDir (@INC) {
    my $path = "$incDir/$prefixDir";
    my @modules = $fileMgr->find($path, ".pm\$");
    foreach my $module (@modules) {
      next if exists $seenModules{$module};
      $seenModules{$module} = 1;
      # convert path to classname
      $module =~ s{ \Q$incDir/\E }{}xms;
      $module =~ s{ \.pm \z      }{}xms;
      $module =~ s{ \/           }{::}xmsg;

      next if $obj->getObjectByClassName($module); # ignore already registered
      # find manager name
      my $managerModule = $module;
      $managerModule =~ s{ ::Obj:: (.*) }{::Mgr::$1Manager}xms;

      # make sure it's a O2::Mgr::ObjectManager subclass
      next unless eval "require $managerModule";
      my $mgr = $context->getSingleton($managerModule);
      next if !$mgr || !$mgr->isa('O2::Obj::ObjectManager');
      next if exists $seenModules{$module};
      $seenModules{$module} = 1;
      push @classes, {
        class   => $module,
        manager => $managerModule,
      };
    }
  }
  return @classes;
}
#-----------------------------------------------------------------------------
# lookup superclasses in .pm file
sub getSuperClassNamesByClassName {
  my ($obj, $className) = @_;
  eval "require $className";
  return if $@;
  
  my @baseClasses;
  eval "\@baseClasses = \@${className}::ISA";
  return if $@;
  
  return @baseClasses;
}
#-----------------------------------------------------------------------------
# Lists all classes that inherit from the specified class, directly or indirectly
sub getSubClasses {
  my ($obj, $className) = @_;
  my $class = $obj->getObjectByClassName($className);
  return unless $class;

  my @subClasses;
  my $introspector = $context->getSingleton('O2::Util::ObjectIntrospect');
  $introspector->setClass($className);
  foreach my $subClassName ($introspector->getSubClasses()) {
    push @subClasses, $obj->getObjectByClassName($subClassName);
    push @subClasses, $obj->getSubClasses($subClassName);
  }
  return @subClasses;
}
#-----------------------------------------------------------------------------
# Returns a list of the class names that the specified container can create new objects of
sub getCanContainClasses {
  my ($obj, $container) = @_;
  my $universalMgr = $context->getSingleton('O2::Mgr::UniversalManager');
  my @classNames = map  { $_->{className} }  $obj->classSearch('isCreatableInO2cms', 1);
  foreach my $classInfo (@{ $obj->{allClasses} }) {
    upush @classNames, $classInfo->{className} if contains @{ $classInfo->{canBeCreatedUnderCategories} }, ref $container;
  }
  my @canContainClasses;
  foreach my $className (@classNames) {
    my $class = eval { $universalMgr->newObjectByClassName($className) };
    next if $@;
    if ($container->canAddObject(undef, $class)) {
      push @canContainClasses, {
        metaName  => $obj->_getMetaNameByClassName($className),
        className => $className,
      };
    }
  }
  return @canContainClasses;
}
#-----------------------------------------------------------------------------
sub getEditTemplateByClassName {
  my ($obj, $className) = @_;
  my $classInfo = $obj->classSearch('className', $className);
  return $classInfo ? $classInfo->{editTemplate} : '';
}
#-----------------------------------------------------------------------------
sub getEditTemplateByObjectId {
  my ($obj, $objectId) = @_;
  my $templateName = $obj->getEditTemplateByClassName( $obj->getClassNameByObjectId($objectId) );
  die "Can't find template for objectId $objectId" unless $templateName;
  return $templateName;
}
#-----------------------------------------------------------------------------
sub getManagerClassByObjectId {
  my ($obj, $objectId) = @_;
  return $obj->getManagerClassByClassName( $obj->getClassNameByObjectId($objectId) );
}
#-----------------------------------------------------------------------------
sub getManagerClassByClassName {
  my ($obj, $className) = @_;
  return $context->getUniversalMgr()->objectClassNameToManagerClassName($className);
}
#-----------------------------------------------------------------------------
sub getClassNameByObjectId {
  my ($obj, $objectId) = @_;
  return $db->fetch("select className from O2_OBJ_OBJECT where objectId = ?", $objectId);
}
#-----------------------------------------------------------------------------
sub classSearch {
  my ($obj, $key, $value) = @_;
  my @classInfos;
  foreach my $classInfo (@{ $obj->{allClasses} }) {
    if ($classInfo->{$key} eq $value) {
      push @classInfos, $classInfo;
      last unless wantarray;
    }
  }
  return @classInfos if wantarray;
  return @classInfos ? $classInfos[0] : undef;
}
#-----------------------------------------------------------------------------
sub getClassEntriesFilePath {
  my ($obj, $className) = @_;
  return $context->getEnv('O2ROOT')    . '/src/classDefinitions/O2-Obj-Class-entries.plds' if $className =~ m{ \A O2::    }xms;
  return $context->getEnv('O2CMSROOT') . '/src/classDefinitions/O2-Obj-Class-entries.plds' if $className =~ m{ \A O2CMS:: }xms;
  if (my ($pluginName) = $className =~ m{ \A O2Plugin:: (\w+) :: }xms) {
    return $context->getPlugin($pluginName)->{root} . '/src/classDefinitions/O2-Obj-Class-entries.plds';
  }
  return $context->getEnv('O2CUSTOMERROOT') . '/src/classDefinitions/O2-Obj-Class-entries.plds';
}
#-----------------------------------------------------------------------------
sub _getMetaNameByClassName {
  my ($obj, $className) = @_;
  my $metaName = $context->getLang()->getString("o2.className.$className");
  if ($metaName =~ m{ < }xms) { # catch missing translation
    ($metaName) = $className =~ m{ :: (\w+) \z }xms; # use last part of package name instead
  }
  return $metaName;
}
#-----------------------------------------------------------------------------
1;
