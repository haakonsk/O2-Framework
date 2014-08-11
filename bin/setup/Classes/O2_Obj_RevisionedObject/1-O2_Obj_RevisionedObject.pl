use strict;
use warnings;

use O2::Util::ScriptEnvironment;
O2::Util::ScriptEnvironment->runOnlyOnce();

use O2 qw($context);
use O2::Script::Common;

my @classNames = qw(
  O2::Obj::AdminUser
  O2::Obj::Article
  O2::Obj::Category O2::Obj::Category::Classes O2::Obj::Category::Keywords O2::Obj::Category::Templates
  O2::Obj::Comment
  O2::Obj::DatePeriod
  O2::Obj::Desktop O2::Obj::Desktop::Item O2::Obj::Desktop::Shortcut O2::Obj::Desktop::Widget
  O2::Obj::Directory O2::Obj::Directory::File
  O2::Obj::Draft
  O2::Obj::Event O2::Obj::EventListener
  O2::Obj::Feed::Rss O2::Obj::Feed::Weather::Yr
  O2::Obj::Flash
  O2::Obj::Frontpage
  O2::Obj::Image::Gallery
  O2::Obj::Installation
  O2::Obj::Member
  O2::Obj::Menu
  O2::Obj::Message
  O2::Obj::MultiMedia::Audio O2::Obj::MultiMedia::EncodeJob O2::Obj::MultiMedia::Video
  O2::Obj::Page
  O2::Obj::Person
  O2::Obj::PropertyDefinition
  O2::Obj::Site O2::Obj::Site::Sitemap
  O2::Obj::Statistics::GoogleAnalytics
  O2::Obj::Survey::Poll O2::Obj::Survey::Poll::Vote
  O2::Obj::Template O2::Obj::Template::Directory O2::Obj::Template::Grid O2::Obj::Template::Include O2::Obj::Template::Object O2::Obj::Template::Page O2::Obj::Template::Slot O2::Obj::Template::SlotOverride
  O2::Obj::Territory O2::Obj::Territory::Continent O2::Obj::Territory::Country O2::Obj::Territory::County O2::Obj::Territory::Municipality O2::Obj::Territory::PostalPlace O2::Obj::Territory::Subregion
    O2::Obj::Territory::World O2::Obj::Territory::YrPlace
  O2::Obj::TextSnippet
  O2::Obj::Trashcan
  O2::Obj::Url
  O2::Obj::Video
  O2::Obj::WebCategory
);

my @revisionIds = $context->getSingleton('O2::Mgr::RevisionedObjectManager')->objectIdSearch();
foreach my $id (@revisionIds) {
  my $revision = $context->getObjectById($id);
  my $serializedObject = $revision->getSerializedObject();
  foreach my $className (@classNames) {
    my $newClassName = $className;
    $newClassName    =~ s{ \A O2:: }{O2CMS::}xms;
    $serializedObject =~ s{ \Q$className\E }{$newClassName}xmsg;
  }
  $revision->setMetaChangeTime( $revision->getMetaChangeTime(), dontOverwriteOnSave => 1 );
  $revision->setSerializedObject($serializedObject);
  $revision->save();
}
