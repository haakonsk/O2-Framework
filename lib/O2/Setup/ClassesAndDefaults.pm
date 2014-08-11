package O2::Setup::ClassesAndDefaults;

use strict;

use base 'O2::Setup';

use O2 qw($context);

#---------------------------------------------------------------------
sub install {
  my ($obj) = @_;
  $obj->registerClasses();
  return 1;
}
#---------------------------------------------------------------------
sub registerClasses {
  my ($obj) = @_;
  
  print "  Registering classes\n" if $obj->verbose();
  
  my $setupConf = $obj->getSetupConf();
  my $filePath  = $obj->_getClassEntriesFilePath($setupConf);
  
  my $classEntries = eval $context->getSingleton('O2::File')->getFile($filePath);
  die "Couldn't find class entries file ($filePath): $@" if $@;

  require O2::Util::AccessorMapper;
  my $accessorMapper = O2::Util::AccessorMapper->new();
  my $classMgr       = $context->getSingleton('O2::Mgr::ClassManager');
  
  foreach my $classEntry (@{$classEntries}) {
    print "  Registering $classEntry->{className}\n" if $obj->debug();
    my $class = $classMgr->getObjectByClassName( $classEntry->{className} ) || $classMgr->newObject();
    
    my @superClassNames = $classMgr->getSuperClassNamesByClassName( $classEntry->{className} );
    @superClassNames    = grep { $_ !~ m{ ::Role:: }xms } @superClassNames;
    if (scalar(@superClassNames) > 1) {
      print "  WARNING: $classEntry->{className} has more than 1 super-class: " . join (', ', @superClassNames) . ". I'm using " . $superClassNames[0] if $obj->debug();
    }
    my $superClassName = $superClassNames[0];
    if ($superClassName) {
      print "    SuperClassName is $superClassName.\n" if $obj->debug();
      my $superClass = $classMgr->getObjectByClassName($superClassName);
      $class->setMetaParentId( $superClass->getId() ) if $superClass;
    }
    else {
      $class->setMetaParentId( $setupConf->{objectIds}->{classesId} );
    }
    
    $class->setMetaName( $classEntry->{className} );
    $accessorMapper->setAccessors( $class, %{$classEntry} );
    
    $class->save();
    print '  ClassId ' . $class->getId() . ', parentId: ' . $class->getMetaParentId() . "\n" if $obj->debug();
  }
}
#---------------------------------------------------------------------
sub _getClassEntriesFilePath {
  my ($obj, $setupConf) = @_;
  return "$setupConf->{o2FwRoot}/src/classDefinitions/O2-Obj-Class-entries.plds";
}
#---------------------------------------------------------------------
1;
