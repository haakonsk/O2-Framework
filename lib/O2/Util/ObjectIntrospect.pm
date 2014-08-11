package O2::Util::ObjectIntrospect;

use strict;

use O2 qw($context $cgi);
use O2::Util::List qw(upush);

#-----------------------------------------------------------------------------
sub new {
  my ($package, %params) = @_;
  my $className = delete $params{className};
  my $obj = bless {
    classes => undef,
    %params,
  }, $package;
  $obj->setClass($className) if $className;
  return $obj;
}
#-----------------------------------------------------------------------------
sub setClass {
  my ($obj, $class) = @_;
  $obj->{class} = $class;
}
#-----------------------------------------------------------------------------
# Native methods first, then inherited
sub getAvailableMethods {
  my ($obj) = @_;
  my @inheritedMethods = $obj->getInheritedMethods();
  my %nativeMethods    = map { $_ => 1 } $obj->getNativeMethods();
  my @methods = keys %nativeMethods;
  foreach my $method (@inheritedMethods) {
    upush @methods, $method unless $nativeMethods{$method};
  }
  return @methods;
}
#-----------------------------------------------------------------------------
sub getPublicNativeMethods {
  my ($obj) = @_;
  my @methods = keys %{$obj->_getClassInfo()->{methods}};
  @methods    = grep { $_ !~ m{ \A _ }xms } @methods;
  return sort @methods;
}
#-----------------------------------------------------------------------------
sub getPrivateNativeMethods {
  my ($obj) = @_;
  my @methods = keys %{$obj->_getClassInfo()->{methods}};
  @methods    = grep { $_ =~ m{ \A _ }xms } @methods;
  return sort @methods;
}
#-----------------------------------------------------------------------------
sub getNativeMethods {
  my ($obj, $class) = @_;
  $class ||= $obj->{class};
  return sort keys %{$obj->_getClasses()->{$class}->{methods}};
}
#-----------------------------------------------------------------------------
sub getInheritedMethods {
  my ($obj) = @_;
  $obj->{seenInheritedClasses} = {};
  $obj->{seenInheritedClasses}->{ $obj->{class} } = 1;
  return unless $obj->_getClassInfo()->{inherits};
  my @methods;
  foreach my $_class (keys %{$obj->_getClassInfo()->{inherits}}) {
    upush @methods, $obj->_getInheritedMethods($_class);
  }
  return sort @methods;
}
#-----------------------------------------------------------------------------
sub _getInheritedMethods {
  my ($obj, $class) = @_;
  $obj->{seenInheritedClasses}->{$class} = 1;
  my @methods;
  if ($obj->_getClassInfo()->{inherits}) {
    foreach my $_class (keys %{$obj->_getClasses()->{$class}->{inherits}}) {
      next if $obj->{seenInheritedClasses}->{$_class};
      upush @methods, $obj->_getInheritedMethods($_class);
    }
  }
  upush @methods, $obj->getNativeMethods($class);
  return @methods;
}
#-----------------------------------------------------------------------------
sub getPublicInheritedMethods {
  my ($obj) = @_;
  return   grep   {  $_ !~ m{ \A _ }xms  &&  $_ ne uc($_)  }   $obj->getInheritedMethods();
}
#-----------------------------------------------------------------------------
sub getPublicOverriddenMethods {
  my ($obj) = @_;
  return   grep   {  $_ !~ m{ \A _ }xms  &&  $_ ne uc($_)  }   $obj->getOverriddenMethods();
}
#-----------------------------------------------------------------------------
sub getOverriddenMethods {
  my ($obj) = @_;
  my @nativeMethods    = $obj->getNativeMethods();
  my %inheritedMethods = map { $_ => 1 } $obj->getInheritedMethods();
  my @methods;
  foreach my $method (@nativeMethods) {
    upush @methods, $method if $inheritedMethods{$method};
  }
  return @methods;
}
#-----------------------------------------------------------------------------
sub hasNativeMethod {
  my ($obj, $methodName) = @_;
  foreach my $method ($obj->getNativeMethods()) {
    return 1 if $methodName eq $method;
  }
  return 0;
}
#-----------------------------------------------------------------------------
sub getUsedClasses {
  my ($obj) = @_;
  my $classInfo = $obj->_getClassInfo();
  return () unless $classInfo;
  return @{ $classInfo->{uses} };
}
#-----------------------------------------------------------------------------
sub inheritsFrom {
  my ($obj, $className) = @_;
  my %inheritedClasses = map { $_ => 1 } $obj->getInheritedClasses();
  return exists $inheritedClasses{$className};
}
#-----------------------------------------------------------------------------
sub getInheritedClasses {
  my ($obj) = @_;
  return $obj->_getInheritedClasses();
}
#-----------------------------------------------------------------------------
sub _getInheritedClasses {
  my ($obj, $className) = @_;
  my $classInfo = $obj->_getClassInfo($className);
  return () unless $classInfo;
  my @classes;
  if ($classInfo->{inherits}) {
    foreach my $class (keys %{ $classInfo->{inherits} }) {
      next if $obj->{seenInheritedClasses}->{$class};
      upush @classes, $class;
      upush @classes, $obj->_getInheritedClasses($class);
    }
  }
  return @classes;
}
#-----------------------------------------------------------------------------
sub getSubClasses {
  my ($obj) = @_;
  my @subClasses;
  my $classes = $obj->_getClasses();
  foreach my $class (keys %{ $classes }) {
    next if $class !~ m{ ::Obj:: }xms;
    foreach my $inheritedClass (keys %{ $classes->{$class}->{inherits} }) {
      push @subClasses, $class if $inheritedClass eq $obj->{class};
    }
  }
  return @subClasses;
}
#-----------------------------------------------------------------------------
sub getSubClassesRecursive {
  my ($obj) = @_;
  my @subClasses;
  my $currentClass = $obj->{class};
  foreach my $class ($obj->getSubClasses()) {
    push @subClasses, $class;
    $obj->setClass($class);
    push @subClasses, $obj->getSubClassesRecursive();
  }
  $obj->setClass($currentClass); # Reset class
  return @subClasses;
}
#-----------------------------------------------------------------------------
sub getAllObjectClasses {
  my ($obj) = @_;
  
  my $fileMgr = $context->getSingleton('O2::File');
  
  my @dirs  = $fileMgr->scanDir( $context->getCustomerPath() . '/lib' );
  push @dirs, $fileMgr->scanDir( $context->getCmsPath()      . '/lib' );
  push @dirs, $fileMgr->scanDir( $context->getFwPath()       . '/lib' );
  @dirs = grep { $_ =~ m{ \A \w+ \z }xms } @dirs;
  push @dirs, map  { $_ =~ s{ \A .* /lib/O2Plugin/ }{}xms; $_ =~ m{ \A \w+ \z }xms ? "O2Plugin/$_" : () }  $fileMgr->scanDir( 'o2://lib/O2Plugin', undef, scanAllO2Dirs => 1 );
  my %dirs = map { $_ => 1 } @dirs;
  my @packagePrefixes = keys %dirs;
  
  my %files;
  foreach my $root ($context->getRootPaths()) {
    foreach my $packagePrefix (@packagePrefixes) {
      my $dir = "$root/lib/$packagePrefix/Obj";
      next unless -e $dir;
      
      my $prefix = "${packagePrefix}::Obj";
      $prefix    =~ s{ / }{::}xmsg;
      my @files = $fileMgr->scanDirRecursive($dir, '.pm$');
      foreach my $file (@files) {
        my $packagePostfix = $file;
        $packagePostfix    =~ s{/}{::}xmsg;
        $packagePostfix    =~ s{ [.] pm \z }{}xms;
        my $package = "${prefix}::$packagePostfix";
        my $mgrPackage = $context->getUniversalMgr()->_guessManagerClassName($package);
        eval {
          $files{$package} = "$dir/$file" if $context->getSingleton($mgrPackage)->can('getModel');
        };
        my $errorMsg = $@;
        if ($errorMsg && $errorMsg !~ m{Could not require '(.+?)': Can't locate \1 in \@INC}ms) {
          $context->getConsole()->logError( "Couldn't load $mgrPackage ($file): $errorMsg", stackTrace => $cgi->{_stackTrace} );
        }
      }
    }
  }
  return %files;
}
#-----------------------------------------------------------------------------
sub _getClassInfo {
  my ($obj, $className) = @_;
  $className ||= $obj->{class};
  return $obj->_getClasses()->{$className};
}
#-----------------------------------------------------------------------------
sub _getClasses {
  my ($obj) = @_;
  if (!$obj->{classes}) {
    my $data = $context->getSingleton('O2::Data');
    $obj->{classes} = $data->load( $context->getEnv('O2CUSTOMERROOT') . '/src/autodocumentation/classes.plds' );
  }
  return $obj->{classes};
}
#-----------------------------------------------------------------------------
1;
