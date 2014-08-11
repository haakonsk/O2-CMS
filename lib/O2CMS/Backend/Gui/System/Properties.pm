package O2CMS::Backend::Gui::System::Properties;

# This is the new properties dialog for O2 Objects
# Planned features is:
#  - Publishing stuff
#  - Status stuff
#  - Simple task like change name etc?
#------------------------------------------------------------

use strict;

use base 'O2CMS::Backend::Gui';

use O2 qw($context $config);

#---------------------------------------------------------------------------------
sub init { 
  my ($obj, %params) = @_;

  my $object = $obj->_getObject();

  my %users = map { $_->getId() => $_->getMetaName() } $obj->_getUsers();

  my $propertyMgr = $context->getSingleton('O2::Mgr::PropertyManager');

  my $allowIndexingProperty = $propertyMgr->getProperty( $object->getId(), 'allowIndexing' );
  my $allowIndexingValue
    = $allowIndexingProperty && $allowIndexingProperty->isInherited()       ? 'inherit'
    : $allowIndexingProperty && $allowIndexingProperty->getValue() eq 'yes' ? 'yes'
    :                                                                         'no';

  my $directoryEncodingValue = $object->isa('O2CMS::Obj::Directory') ? $object->getDirectoryEncoding() : undef;

  my $localesProperty = $propertyMgr->getProperty( $object->getId(), 'availableLocales' );
  my @availableLocales;
  my $availableLocalesCondition = 'inherited';
  if ($localesProperty && $localesProperty->isInherited()) {
    @availableLocales = split /,/, $localesProperty->getValue();
  }
  elsif ($localesProperty) {
    @availableLocales = split /,/, $localesProperty->getValue();
    $availableLocalesCondition = 'direct';
  }
  else {
    my $availableLocales = $config->get('o2.locales');
    @availableLocales    = ref $availableLocales eq 'ARRAY' ? @{ $availableLocales } : $availableLocales;
  }

  my %localeLanguageNames = (
    da_DK => 'Dansk',
    de_DE => 'Deutch',
    en_US => 'English',
    es_ES => 'Español',
    fr_FR => 'Français',
    nb_NO => 'Norsk bokmål',
    ny_NO => 'Norsk nynorsk',
    pt_PT => 'Português',
    sv_SE => 'Svenska',
  );
  my @systemWideLocales = @availableLocales;
  foreach my $locale (keys %localeLanguageNames) {
    my $found;
    foreach my $hasLocale (@availableLocales) {
      $found++ if $locale eq $hasLocale;
    }
    push @systemWideLocales, $locale unless $found;
  }

  $obj->display(
    'mainTemplate.html',
    object                    => $object,
    ownerName                 => $users{ $object->getMetaOwnerId() },
    reloadTree                => $params{reloadTree} || 0,
    allowIndexingValue        => $allowIndexingValue,
    directoryEncodingValue    => $directoryEncodingValue,
    availableLocalesCondition => $availableLocalesCondition,
    availableLocales          => '['. join (',', map {"'$_'"} @availableLocales) . ']',
    systemWideLocales         => \@systemWideLocales,
    localeLanguageNames       => \%localeLanguageNames,
  );
}
#---------------------------------------------------------------------------------
sub updateLocales {
  my ($obj) = @_;
  my $object = $obj->_getObject();

  if ( $obj->getParam('availableLocalesCondition') eq 'direct' ) { # Note! Because the toggle-function (toggleLocales) runs before page load, this is inverted
    $object->deletePropertyValue('availableLocales');
  }
  else {
    my $locales = join ',', $obj->getParam('selectedLocales');
    $object->setPropertyValue('availableLocales', $locales);
  }

  $obj->init();
}
#---------------------------------------------------------------------------------
sub updateObjectProperties {
  my ($obj) = @_;
  my $object = $obj->_getObject();
  $object->setMetaName( $obj->getParam('name') );
  
  my $allowIndexingValue = $obj->getParam('allowIndexing');
  if ($allowIndexingValue eq 'inherit') { 
    $object->deletePropertyValue('allowIndexing');
  }
  else {
    $object->setPropertyValue( 'allowIndexing' => $allowIndexingValue );
  }

  if ($obj->getParam('directoryEncoding')) {
    my $directoryEncodingValue = $obj->getParam('directoryEncoding');
    if ($directoryEncodingValue eq 'inherit') {
      $object->deletePropertyValue('directoryEncoding');
    }
    else {
      $object->setPropertyValue('directoryEncoding', $directoryEncodingValue);
    }
  }

  foreach my $locale ($object->getAvailableLocales()) {
    $object->setCurrentLocale($locale);
    $object->setTitle( $obj->getParam("$locale.title") ) if $obj->getParam("$locale.title");
  }

  $object->save();
  $obj->init(reloadTree => 1);
}
#---------------------------------------------------------------------------------
sub _getObject {
  my ($obj, $deleteCacheFileIfUninstantiatable) = @_;
  my $objectId = $obj->getParam('objectId');
  die 'No object ID is given' if $objectId !~ m{ \A \d+ \z }xms;
  my $object;
  eval {
    $object = $context->getObjectById($objectId);
  };
  die "Couldn't instantiate object with ID $objectId: $@" if !$object && !$deleteCacheFileIfUninstantiatable;
  $obj->_deleteCacheFileForObjectId($objectId)            if !$object;
  return $object;
}
#---------------------------------------------------------------------------------
sub _deleteCacheFileForObjectId {
  my ($obj, $objectId) = @_;
  return $context->getSingleton('O2CMS::Publisher::PageCache')->delCacheById($objectId);
}
#---------------------------------------------------------------------------------
sub _getUsers {
  my ($obj) = @_;
  my @users = $context->getSingleton('O2CMS::Mgr::AdminUserManager')->getUsers();
  return sort { $a->getMetaName() cmp $b->getMetaName() } @users;
}
#---------------------------------------------------------------------------------
# Cache logic start
#
# How it should work:
# You have a few options, you can:
# - turn caching of object pages on and off
# - turn frontpage caching on and off
# - regenerate cache for object pages
# - regenerate frontpage cache
#
# When regenerating object page/frontpage cache, then cached files for objects that have been trashed/deleted should be removed.
#
# When caching is turned off, cached files should be removed entirely.
#
# When caching is turned on, cached files (if any) should be regenerated.
#
# The reason why we're regenerating cache instead of deleting is to avoid calling index.cgi more than once when there's been a change.
# Obviously, we can't limit how many times index.cgi is called when caching is turned on (unless we're going to cache every frontpage
# at the time caching is turned on). But that shouldn't be a problem, because caching used to be turned off, so we're not getting into
# a worse situation than what we had before turning cache on.
#---------------------------------------------------------------------------------
sub cacheAdministration {
  my ($obj) = @_;
  my $site = $obj->_getObject();
  die "Not a site object" unless $site->isa('O2CMS::Obj::Site');
  
  my $pageCache = $context->getSingleton('O2CMS::Publisher::PageCache');
  $obj->display(
    'cacheAdministration.html',
    object                  => $site,
    allowObjectPageCaching  => $pageCache->objectHtmlCacheIsEnabledForSite($site) ? 'yes' : 'no',
    allowFrontpageCaching   => $pageCache->frontpageCacheIsEnabledForSite($site)  ? 'yes' : 'no',
    totalObjectPagesInCache => scalar $pageCache->getCachedObjectIds($site),
    totalFrontpagesInCache  => scalar $pageCache->getCachedFrontpageIds($site),
  );
}
#---------------------------------------------------------------------------------
sub saveCacheOption {
  my ($obj) = @_;
  my $site = $obj->_getObject();
  return unless $site->isa('O2CMS::Obj::Site');
  
  my $option = $obj->getParam('optionName');
  my $value  = $obj->getParam('optionValue');

  return 0 if $value !~ m/^(yes|no)$/i;

  my $pageCache = $context->getSingleton('O2CMS::Publisher::PageCache');
  my @objectIdsToDelete; # if caching was on and now we turn it of

  my $finalMsgKey;
  if ($option eq 'allowObjectPageCaching') {
    if ($value eq 'yes') {
      $pageCache->enableObjectHtmlCacheForSite($site);
      $finalMsgKey = 'msgOptionSavedAndTurnedOn';
    }
    else {
      $pageCache->disableObjectHtmlCacheForSite($site);
      @objectIdsToDelete = $pageCache->getCachedObjectIds($site);
      $finalMsgKey = 'msgObjectHtmlCacheIsDeleted';
    }
  }
  elsif ($option eq 'allowFrontpageCaching') {
    if ($value eq 'yes') {
      $pageCache->enableFrontpageCacheForSite($site);
      $finalMsgKey = 'msgOptionSavedAndTurnedOn';
    }
    else {
      $pageCache->disableFrontpageCacheForSite($site);
      @objectIdsToDelete = $pageCache->getCachedFrontpageIds($site);
      $finalMsgKey = 'msgFrontpageCacheIsDeleted';
    }
  }
  else {
    return 0;
  }

  my $message
    = $value eq 'yes'    ? $obj->getString('o2.propertiesDialog.cache.msgOptionSavedAndTurnedOn')
    : @objectIdsToDelete ? $obj->getString('o2.propertiesDialog.cache.msgOptionSavedAndTurnedOffAndNeedToDeleteItems', totalItems => scalar @objectIdsToDelete)
    :                      $obj->getString('o2.propertiesDialog.cache.msgOptionSavedAndTurnedOff');
  
  return {
    message           => $message,
    finalMessage      => $obj->getString("o2.propertiesDialog.cache.$finalMsgKey"),
    objectIdsToDelete => \@objectIdsToDelete,
  };
}
#---------------------------------------------------------------------------------
sub startRegeneratingFrontpageCache {
  my ($obj) = @_;
  my $site = $obj->_getObject();
  die "Not a site object" unless $site->isa('O2CMS::Obj::Site');
  
  return {
    message               =>   $obj->getString('o2.propertiesDialog.cache.msgDeletingFrontpageCache'),
    finalMessage          =>   $obj->getString('o2.propertiesDialog.cache.msgFrontpageCacheIsRegenerated'),
    objectIdsToRegenerate => [ $context->getSingleton('O2CMS::Publisher::PageCache')->getCachedFrontpageIds($site) ],
  };
}
#---------------------------------------------------------------------------------
sub startRegeneratingObjectHtmlCache {
  my ($obj) = @_;
  my $site = $obj->_getObject();
  die "Not a site object" unless $site->isa('O2CMS::Obj::Site');
  
  return {
    message               =>   $obj->getString('o2.propertiesDialog.cache.msgDeletingObjectHtmlCache'),
    finalMessage          =>   $obj->getString('o2.propertiesDialog.cache.msgObjectHtmlCacheIsRegenerated'),
    objectIdsToRegenerate => [ $context->getSingleton('O2CMS::Publisher::PageCache')->getCachedObjectIds($site) ],
  };
}
#---------------------------------------------------------------------------------
sub ajaxDeleteCachedObjectId {
  my ($obj) = @_;
  my $object = $obj->_getObject(1);
  return 1 unless $object;

  my $pageCache = $context->getSingleton('O2CMS::Publisher::PageCache');
  $object->setPageCachable('inherit') if $object->can('setPageCachable');

  return 1 if $pageCache->delCached($object);
  return $obj->ajaxError( "Couldn't delete cached object: " . $object->getId() );
}
#---------------------------------------------------------------------------------
sub ajaxRegenerateCachedObjectId {
  my ($obj) = @_;
  my $object = $obj->_getObject(1);
  return 1 unless $object;

  my $pageCache = $context->getSingleton('O2CMS::Publisher::PageCache');

  my $success = eval {
    return $pageCache->regenerateCached($object);
  };
  return $obj->ajaxError( sprintf "Couldn't regenerate cached object (%s): $@", $object->getId() ) unless $success;
  return 1;
}
#---------------------------------------------------------------------------------
# Cache logic end
#---------------------------------------------------------------------------------
1;
