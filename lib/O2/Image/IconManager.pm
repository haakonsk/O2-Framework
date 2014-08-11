package O2::Image::IconManager;

# Utility manager for O2 icons. From now on everything in O2 should have icons
# - classes
# - applications
# - actions (e.g. edit, save)

use strict;

use constant DEBUG => 0;
use O2 qw($context $config);

#--------------------------------------------------------------------
sub new {
  my ($pkg, %init) = @_;
  $init{theme}            ||= 'o2default'; # latent theme support
  $init{defaultExt}       ||= 'png';
  $init{relativeIconPath} ||= "var/www/images/icons/$init{theme}";
  $init{iconUrl}          ||= $config->get('o2.siteRootUrl')  . "/images/icons/$init{theme}";
  return bless \%init, $pkg;
}
#--------------------------------------------------------------------
sub addNewIcon {}
#--------------------------------------------------------------------
sub updateIcon {}
#--------------------------------------------------------------------
sub getIconPath {
  my ($obj, $classOrAction, $size) = @_;
  my $iconPath = $obj->_formatAbsolutePath($classOrAction);
  return "$iconPath-$size.$obj->{defaultExt}";
}
#--------------------------------------------------------------------
sub getIconUrl {
  my ($obj, $classOrAction, $size) = @_;
  $size ||= 16; # to be backward comp
  my $relPathToIcon = $obj->_formatRelativePath($classOrAction);
  return "$obj->{iconUrl}/$relPathToIcon-$size.$obj->{defaultExt}";
}
#--------------------------------------------------------------------
sub getRelativeIconDir {
  my ($obj, $classOrAction) = @_;
  my $dir = "var/www/images/icons/$obj->{theme}";
  return $dir unless $classOrAction;
  
  return "$dir/" . join ('/', split /::/, $classOrAction) if $classOrAction =~ m{ :: }xms;
  return "$dir/" . join ('/', split /-/,  $classOrAction) if $classOrAction =~ m{ -  }xms;
}
#--------------------------------------------------------------------
sub getIconFileName {
  my ($obj, $classOrAction, $size, $extension) = @_;
  die 'classOrAction attribute missing' unless $classOrAction;
  
  $size      ||= 16;
  $extension ||= $obj->{defaultExt};
  return join ('-', split /::/, $classOrAction) . "-$size.$extension";
}
#--------------------------------------------------------------------
sub _formatAbsolutePath {
  my ($obj, $classOrAction) = @_;
  my ($relativePath, $basePath) = $obj->_formatRelativePath($classOrAction);
  return "$basePath/$obj->{relativeIconPath}/$relativePath";
}
#--------------------------------------------------------------------
sub _formatRelativePath {
  my ($obj, $classOrAction) = @_;
  my @dirs
    = $classOrAction =~ m{ \A \w+ :: }xmsi
    ? split /::/, $classOrAction # guessing it to be a className
    : split /-/,  $classOrAction # assuming this to be an action e.g. action-edit
    ;
  
  my $iconPath = join '/', @dirs;
  my $iconName = join '-', @dirs;
  return "$iconPath/$iconName" unless wantarray;
  
  my $baseDir = '';
  foreach my $root ($context->getRootPaths()) {
    if (-e "$root/$obj->{relativeIconPath}/" . join '/', @dirs) {
      $baseDir = $root;
      last;
    }
  }
  return ("$iconPath/$iconName", $baseDir);
}
#--------------------------------------------------------------------
1;
