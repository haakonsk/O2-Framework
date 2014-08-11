package O2::Obj::File;

# Class representing a file.
# Need content and fileformat to be able to save (setContentFromPath() will also set fileformat based on file exstension)

use strict;

use base 'O2::Obj::Object';

use O2 qw($context $config);

#-------------------------------------------------------------------------------
sub new {
  my ($pkg, %init) = @_;
  my $obj = $pkg->SUPER::new(%init);
  $obj->{_oldIsOnlineStatus} = undef; # this to be able to detect changes on isOnline status. so we can copy the file fra public/private repository
  $obj->{fileMgr}            = $context->getSingleton('O2::File');
  $obj->{unsavedContent}     = undef;
  return $obj;
}
#-------------------------------------------------------------------------------
sub canMove {
  my ($obj, $fromContainer, $toContainer) = @_;
  return 1;
}
#-------------------------------------------------------------------------------
sub getUsedLocales {
  my ($obj) = @_;
  return $obj->getAvailableLocales();
}
#-------------------------------------------------------------------------------
sub setContent {
  my ($obj, $content) = @_;
  die '$content may be an empty string, but not undefined' unless defined $content;
  $obj->{unsavedContent} = {
    type    => 'string',
    content => $content,
  };
}
#-------------------------------------------------------------------------------
sub setContentFromPath {
  my ($obj, $pathToContent) = @_;
  my ($ext) = $pathToContent =~ m|\.(\w+)$|;
  $obj->setFileFormat($ext);
  $obj->{unsavedContent} = {
    type => 'file',
    path => $pathToContent,
  };
}
#-------------------------------------------------------------------------------
sub setContentFromUrl {
  my ($obj, $url) = @_;
  require LWP::UserAgent;
  my $userAgent = LWP::UserAgent->new();
  my $response  = $userAgent->get($url);
  die "Error getting content from url: $url" unless $response->is_success();
  
  $obj->{unsavedContent} = {
    type    => 'string',
    content => $response->content(),
  };
}
#-------------------------------------------------------------------------------
# returns a scalarref to the content, or undef if no content set.
sub getContentRef {
  my ($obj) = @_;
  return $obj->getUnsavedContentRef()                       if $obj->hasUnsavedContent();
  return $obj->{fileMgr}->getFileRef( $obj->getFilePath() ) if $obj->getId() > 0;
  return; # no content
}
#-------------------------------------------------------------------------------
# returns true if object has filecontent not yet written to filesystem
sub hasUnsavedContent {
  my ($obj) = @_;
  return $obj->{unsavedContent} ? 1 : 0;
}
#-------------------------------------------------------------------------------
# mark unsaved content as saved
sub clearUnsavedContent {
  my ($obj) = @_;
  $obj->{unsavedContent} = undef;
}
#-------------------------------------------------------------------------------
# returns scalarref to content not yet saved, or undef if not set or already saved.
sub getUnsavedContentRef {
  my ($obj) = @_;
  my $content = $obj->{unsavedContent};
  return unless defined $content;
  return \$content->{content}                            if $content->{type} eq 'string';
  return $obj->{fileMgr}->getFileRef( $content->{path} ) if $content->{type} eq 'file';
  die "Illegal unsaved type: '$content->{type}'";
}
#-------------------------------------------------------------------------------
# returns filesystem path to file
sub getFilePath {
  my ($obj) = @_;
  return $obj->_getLocation( $obj->_getBasePath(), 0 );
}
#-------------------------------------------------------------------------------
# returns filesystem directory where file lies
sub getFileDirectory {
  my ($obj) = @_;
  my $dir = $obj->_getLocation( $obj->_getBasePath(), 0 );
  $dir    =~ s{ / [^/]+? \z }{}xms;
  return $dir;
}
#-------------------------------------------------------------------------------
# returns web location of file
sub getFileUrl {
  my ($obj) = @_;
  return $obj->_getLocation( $config->get('file.baseUrl'), 0 );
}
#-------------------------------------------------------------------------------
# like getFilePath but will also create missing directories
sub getCreatedFilePath {
  my ($obj) = @_;
  return $obj->_getLocation( $obj->_getBasePath(), 1 );
}
#-------------------------------------------------------------------------------
sub _getBasePath {
  my ($obj) = @_;
  return $config->get('file.basePath') if $obj->isOnline();
  return $config->get('file.baseOfflinePath');
}
#-------------------------------------------------------------------------------
# returns file size in bytes
sub getFileSize {
  my ($obj) = @_;
  return -s $obj->getFilePath();
}
#-------------------------------------------------------------------------------
sub _getLocation {
  my ($obj, $base, $mkDirs) = @_;
  die "Missing image id" unless $obj->getId();
  
  my $location = $obj->{fileMgr}->distributePath(
    rootDir  => $base,
    id       => $obj->getId(),
    fileName => $obj->getId() . '.' . $obj->getFileFormat(),
    levels   => 5,
    mkDirs   => $mkDirs,
  );
  return $location;
}
#-------------------------------------------------------------------------------
sub isDeletable {
  return 1;
}
#-------------------------------------------------------------------------------
sub getContentPlds { # Usually inherited
  my ($obj) = @_;
  my $parent = $obj->SUPER::getContentPlds();
  return {
    %{$parent}, ## no critic(ValuesAndExpressions::ProhibitCommaSeparatedStatements)
    _oldIsOnlineStatus => $obj->{_oldIsOnlineStatus},
  };
}
#-------------------------------------------------------------------------------
sub setContentPlds { # Usually inherited
  my ($obj, $plds) = @_;
  $obj->{_oldIsOnlineStatus} = delete $plds->{_oldIsOnlineStatus};
  if (!$obj->SUPER::setContentPlds($plds) || !$obj->verifyContentPlds($plds)) {
    die "ContentPLDS could not be verified: $@";
  }
  return 1;
}
#-------------------------------------------------------------------------------
sub isSerializable {
  return 1;
}
#-------------------------------------------------------------------------------
sub setIsOnline {
  my ($obj, $value) = @_;
  $obj->{_oldIsOnlineStatus} = $obj->isOnline() unless defined $obj->{_oldIsOnlineStatus};
  $obj->setModelValue('isOnline', $value ? 1 : 0);
}
#-------------------------------------------------------------------------------
sub delete { ## no critic(Subroutines::ProhibitBuiltinHomonyms)
  my ($obj) = @_;
  
  # Make sure the object has some unsavedContent after delete, so a subsequent save will recreate the file:
  $obj->setContent( ${ $obj->getContentRef() } ) unless $obj->hasUnsavedContent();
  
  $obj->SUPER::delete();
}
#-------------------------------------------------------------------------------
1;
