package O2::Gui::System::Documentation::Taglibs;

use strict;

use base 'O2::Gui';

use O2 qw($context $cgi);

#--------------------------------------------------------------------------------------------------
sub needsAuthentication {
  return 0;
}
#--------------------------------------------------------------------------------------------------
sub init {
  my ($obj) = @_;
  my $firstModule = [ $obj->_getModules() ]->[0];
  $cgi->redirect(
    setMethod => 'showDocumentation',
    setParams => "module=$firstModule",
  );
}
#--------------------------------------------------------------------------------------------------
sub showDocumentation {
  my ($obj) = @_;
  my $moduleDir = $obj->getParam('module') or die 'Missing module';
  $moduleDir    =~ s{-}{/}xmsg;
  $moduleDir    = "var/doc/tutorials/taglib/$moduleDir";
  
  my ($tag, $baseDir, @tags) = ('', '');
  foreach my $rootDir ($context->getRootPaths()) {
    $baseDir  = "$rootDir/$moduleDir";
    next unless -d $baseDir;
    
    my @docFiles = $context->getSingleton('O2::File')->scanDir($baseDir, '.html$');
    next unless @docFiles;
    
    @tags = sort map { substr $_, 0, -5 } @docFiles;
    $tag  = $obj->getParam('tag') || $tags[0];
    last if @tags;
  }

  $obj->display(
    'showDocumentation.html',
    module   => $obj->getParam('module'),
    tags     => \@tags,
    tag      => $tag,
    filePath => "$baseDir/$tag.html",
    modules  => [ $obj->_getModules() ],
  );
}
#--------------------------------------------------------------------------------------------------
sub _getModules {
  my ($obj) = @_;
  my %taglibs = %{ $obj->getContext()->getConfig->get('template.taglibs') };
  return sort keys %taglibs;
}
#--------------------------------------------------------------------------------------------------
sub tagSearch {
  my ($obj) = @_;

  require O2::Util::ExternalModule;
  O2::Util::ExternalModule->require('String::Compare');

  my $searchQuery = lc $obj->getParam('searchQuery');
  my $modules = $obj->_getAllModulesWithTags();

  my %similarTags; # module::tagname => similarityPercentage

  foreach my $module (keys %{$modules}) {
    foreach my $originalTagname (@{ $modules->{$module}->{tags} }) {
      my $tagname = lc $originalTagname;
      my $similarTagsKey = $module . "::" . $originalTagname;
      $similarTagsKey    =~ s{ / }{::}xmsg;
      my $similarityPercentage = 100 * String::Compare::compare($searchQuery, $tagname);
      next if $similarityPercentage < 50;
      
      $similarityPercentage = substr $similarityPercentage, 0, 4;
      $similarTags{$similarTagsKey} = $similarityPercentage;
    }
  }
  my %sortedSimilarTags;
  my @sortedKeys = sort   { $similarTags{$b} <=> $similarTags{$a} }   keys %similarTags;
  my (@sortedValues, @modules, @tagNames);
  foreach my $key (@sortedKeys) {
    push @sortedValues, $similarTags{$key};
    my ($module, $tagname) = $key =~ m{ \A (.+) :: ([^:]+) \z }xms;
    $module  =~ s{::}{-}xmsg;
    push @modules,  $module;
    push @tagNames, $tagname;
  }
  
  my @similarTags = %similarTags;
  if (@tagNames == 1 && $similarTags[1] == 100) { # One tag and 100% match
    $cgi->redirect(
      setMethod => 'showDocumentation',
      setParams => "module=$modules[0]&tag=$tagNames[0]",
    );
  }
  
  $obj->display(
    'tagSearch.html',
    sortedTags                 => \@sortedKeys,
    sortedSimilarityPercentage => \@sortedValues,
    sortedModules              => \@modules,
    sortedTagNames             => \@tagNames,
  );
}
#--------------------------------------------------------------------------------------------------
sub _getAllModulesWithTags {
  my ($obj) = @_;
  
  my $modules = {};
  
  foreach my $rootDir ($context->getRootPaths()) {
    my $baseDir = "$rootDir/var/doc/tutorials/taglib";
    next unless -e $baseDir;
    
    my @tagFiles = $context->getSingleton('O2::File')->find($baseDir, "[.]html\$");
    foreach my $file (@tagFiles) {
      next unless $file =~ m{ taglib  / (.+) / (.+) [.]html  \z }xms;
      my $module  = $1;
      my $tagname = $2;
      if (!defined $modules->{$module}) {
        $modules->{$module}         = {};
        $modules->{$module}->{tags} = [];
      }
      push @{ $modules->{$module}->{tags} }, $tagname;
    }
  }
  
  return $modules;
}
#--------------------------------------------------------------------------------------------------
1;
