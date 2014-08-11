use strict;
use warnings;

use O2::Util::ScriptEnvironment;
O2::Util::ScriptEnvironment->runOnlyOnce();

my @tableNames = qw(
  O2_OBJ_ADMINUSER
  O2_OBJ_ARTICLE O2_OBJ_ARTICLETEXTS
  O2_OBJ_CATEGORY O2_OBJ_CATEGORY_CLASSES O2_OBJ_CATEGORY_KEYWORDS O2_OBJ_CATEGORY_TEMPLATES
  O2_OBJ_COMMENT
  O2_OBJ_DATEPERIOD
  O2_OBJ_DESKTOP O2_OBJ_DESKTOP_ITEM O2_OBJ_DESKTOP_SHORTCUT O2_OBJ_DESKTOP_WIDGET
  O2_OBJ_DIRECTORY O2_OBJ_DIRECTORY_FILE
  O2_OBJ_DRAFT
  O2_OBJ_FEED_RSS O2_OBJ_FEED_WEATHER_YR
  O2_OBJ_FLASH
  O2_OBJ_FRONTPAGE
  O2_OBJ_IMAGE_GALLERY
  O2_OBJ_INSTALLATION
  O2_OBJ_MENU O2_OBJ_MENU_ITEM
  O2_OBJ_MESSAGE
  O2_OBJ_MULTIMEDIA_AUDIO O2_OBJ_MULTIMEDIA_ENCODEJOB O2_OBJ_MULTIMEDIA_VIDEO
  O2_OBJ_PAGE O2_OBJ_PAGE_SLOT O2_OBJ_PAGE_SLOTOVERRIDE O2_OBJ_PAGE_STANDARDDIRECTPUBLISH
  O2_OBJ_SITE O2_OBJ_SITE_SITEMAP
  O2_OBJ_STATISTICS_GOOGLEANALYTICS
  O2_OBJ_SURVEY_POLL O2_OBJ_SURVEY_POLL_VOTE
  O2_OBJ_TEMPLATE O2_OBJ_TEMPLATE_DIRECTORY O2_OBJ_TEMPLATE_GRID O2_OBJ_TEMPLATE_INCLUDE O2_OBJ_TEMPLATE_OBJECT O2_OBJ_TEMPLATE_PAGE O2_OBJ_TEMPLATE_SLOT O2_OBJ_TEMPLATE_SLOTOVERRIDE
  O2_OBJ_TERRITORY O2_OBJ_TERRITORY_CONTINENT O2_OBJ_TERRITORY_COUNTRY O2_OBJ_TERRITORY_COUNTY O2_OBJ_TERRITORY_MUNICIPALITY O2_OBJ_TERRITORY_POSTALPLACE O2_OBJ_TERRITORY_SUBREGION
    O2_OBJ_TERRITORY_WORLD O2_OBJ_TERRITORY_YRPLACE
  O2_OBJ_TEXTSNIPPET
  O2_OBJ_TRASHCAN O2_OBJ_TRASHCAN_CONTENT
  O2_OBJ_URL
  O2_OBJ_VIDEO
  O2_OBJ_WEBCATEGORY
  O2_WIDGET_NOTES
);

my @classNames = qw(
  O2::Obj::AdminUser
  O2::Obj::Article
  O2::Obj::Category O2::Obj::Category::Classes O2::Obj::Category::Keywords O2::Obj::Category::Templates
  O2::Obj::Comment
  O2::Obj::DatePeriod
  O2::Obj::Desktop O2::Obj::Desktop::Item O2::Obj::Desktop::Shortcut O2::Obj::Desktop::Widget
  O2::Obj::Directory O2::Obj::Directory::File
  O2::Obj::Draft
  O2::Obj::Feed::Rss O2::Obj::Feed::Weather::Yr
  O2::Obj::Flash
  O2::Obj::Frontpage
  O2::Obj::Image::Gallery
  O2::Obj::Installation
  O2::Obj::Menu
  O2::Obj::Message
  O2::Obj::MultiMedia::Audio O2::Obj::MultiMedia::EncodeJob O2::Obj::MultiMedia::Video
  O2::Obj::Page
  O2::Obj::Site O2::Obj::Site::Sitemap
  O2::Obj::Statistics::GoogleAnalytics
  O2::Obj::Survey::Poll O2::Obj::Survey::Poll::Vote
  O2::Obj::Template O2::Obj::Template::Directory O2::Obj::Template::Grid O2::Obj::Template::Include O2::Obj::Template::Object O2::Obj::Template::Page O2::Obj::Template::Slot O2::Obj::Template::SlotOverride
  O2::Obj::Territory O2::Obj::Territory::Continent O2::Obj::Territory::Country O2::Obj::Territory::County O2::Obj::Territory::Municipality O2::Obj::Territory::PostalPlace O2::Obj::Territory::SubRegion
    O2::Obj::Territory::World O2::Obj::Territory::YrPlace
  O2::Obj::TextSnippet
  O2::Obj::Trashcan
  O2::Obj::Url
  O2::Obj::Video
  O2::Obj::WebCategory
);

use O2 qw($context $db);

my $schemaMgr    = $context->getSingleton('O2::DB::Util::SchemaManager');
my $dbIntrospect = $context->getSingleton('O2::DB::Util::Introspect');

warn "Going through tables";
foreach my $tableName (@tableNames) {
  if ($dbIntrospect->tableExists($tableName)) {
    my $newTableName = $tableName;
    $newTableName    =~ s{ \A O2_ }{O2CMS_}xms;
    $schemaMgr->renameTable($tableName, $newTableName);
  }
}

warn "Going through classes";
foreach my $className (@classNames) {
  my $newClassName = $className;
  $newClassName    =~ s{ \A O2:: }{O2CMS::}xmsg;
  $db->sql("update O2_OBJ_OBJECT set className = ? where className = ?", $newClassName, $className);
}

warn "Renaming classes in O2CMS_OBJ_TEMPLATE_DIRECTORY";
my @templateClasses = $db->selectColumn('select distinct(templateClass) from O2CMS_OBJ_TEMPLATE_DIRECTORY');
foreach my $class (@templateClasses) {
  my $newClass = $class;
  $newClass    =~ s{ \A O2:: }{O2CMS::}xms;
  $db->sql('update O2CMS_OBJ_TEMPLATE_DIRECTORY set templateClass = ? where templateClass = ?', $newClass, $class);
}

warn "Renaming classes for field usableClasses in O2CMS::Obj::Template::Object";
foreach my $class (@classNames) {
  my $newClass = $class;
  $newClass    =~ s{ \A O2:: }{O2CMS::}xms;
  $db->sql("update O2_OBJ_OBJECT_VARCHAR set value = ? where name like 'usableClasses.0%' and value = ?", $newClass, $class);
}

warn "Updating property name in O2_OBJ_OBJECT_PROPERTY";
foreach my $class (@classNames) {
  my $newClass = $class;
  $newClass    =~ s{ \A O2:: }{O2CMS::}xms;
  my @rows = $db->fetchAll("select objectId, name from O2_OBJ_OBJECT_PROPERTY where name like ?", "%.$class");
  foreach my $row (@rows) {
    my $name = $row->{name};
    $name    =~ s{ \Q$class\E }{$newClass}xmsg;
    $db->do( "update O2_OBJ_OBJECT_PROPERTY set name = ? where objectId = ? and name = ?", $name, $row->{objectId}, $row->{name} );
  }
}

my $cacher = $context->getMemcached();
if (!$cacher->isa('O2::Cache::Dummy')) {
  warn "Deleting from cache";
  my @ids = $db->selectColumn("select objectId from O2_OBJ_OBJECT where className like 'O2CMS::%'");
  foreach my $id (@ids) {
    $cacher->deleteObjectById($id);
  }
}

# Not actually DB stuff, but... (Caching)
my $pageCache = $context->getSingleton('O2CMS::Publisher::PageCache');
my $fileMgr   = $context->getSingleton('O2::File');
my $cacheRoot = $pageCache->{cachePath};
foreach my $class (@classNames) {
  $class =~ s{ :: }{-}xmsg;
  my $newClass = $class;
  $newClass    =~ s{ \A O2- }{O2CMS-}xms;
  my @files = $fileMgr->scanDirRecursive($cacheRoot, "${class}_*.plds");
  printf "%d cache files for $class will be renamed to $newClass\n", scalar @files if @files > 0;
  foreach my $file (@files) {
    my $path = "$cacheRoot/$file";
    my $newPath = $path;
    $newPath    =~ s{ \Q$class\E }{$newClass}xms;
    $fileMgr->move($path, $newPath);
  }
}
