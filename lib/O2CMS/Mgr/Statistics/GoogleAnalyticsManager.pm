package O2CMS::Mgr::Statistics::GoogleAnalyticsManager;

use strict;

use base 'O2::Mgr::ObjectManager';

use O2 qw($context $db);
use O2CMS::Obj::Statistics::GoogleAnalytics;

#-----------------------------------------------------------------------------
sub initModel {
  my ($obj, $model) = @_;
  $obj->SUPER::initModel($model);
  $model->registerFields(
    'O2CMS::Obj::Statistics::GoogleAnalytics',
    # Your class definition goes here:
    #-----------------------------------------------------------------------------
    email       => { type => 'varchar' },
    password    => { type => 'varchar' },
    analyticsId => { type => 'varchar' },
    javascript  => { type => 'text'    },
    #-----------------------------------------------------------------------------
  );
}
#-----------------------------------------------------------------------------
sub getAccount {
  my ($obj) = @_;
  my $query = "select a.objectId from O2CMS_OBJ_STATISTICS_GOOGLEANALYTICS a, O2_OBJ_OBJECT o where a.objectId = o.objectId and status != 'deleted' and status not like 'trashed%' and o.parentId is not null";
  my @accountIds = $db->selectColumn($query);
  my $account;
  if (!@accountIds) {
    $account = $obj->newObject();
    $account->setMetaName('Google Analytics');
    return $account;
  }
  return $context->getObjectById( $accountIds[0] );
}
#-----------------------------------------------------------------------------
sub getAllAccounts {
  my ($obj) = @_;
  my $query = "select a.objectId from O2CMS_OBJ_STATISTICS_GOOGLEANALYTICS a, O2_OBJ_OBJECT o where a.objectId = o.objectId and status != 'deleted' and status not like 'trashed%' and o.parentId is not null";
  my @accountIds = $db->selectColumn($query);
  return $context->getObjectsByIds(@accountIds);
}
#-----------------------------------------------------------------------------
sub getAccountByCurrentSite {
  my ($obj) = @_;
  my $hostname = $context->getHostname();

  my $accountId = $obj->_getAccountIdForHostnameFromCache($hostname);

  if (!$accountId) {
    my @siteIds = $db->selectColumn("select o.objectId from O2CMS_OBJ_SITE s, O2_OBJ_OBJECT o where s.objectId = o.objectId and hostname = ? and status != 'deleted' and status not like 'trashed%'", $hostname);
    die "More than one site object with hostname = '$hostname'. Don't know which one to use." if @siteIds > 1;
    my $query = "select a.objectId from O2CMS_OBJ_STATISTICS_GOOGLEANALYTICS a, O2_OBJ_OBJECT o where a.objectId = o.objectId and o.parentId = ? and status != 'deleted' and status not like 'trashed%'";
    my @accountIds = $db->selectColumn( $query, $siteIds[0] );
    return unless @accountIds;
    die "More than one Google Analytics object found for site $hostname. Don't know which one to use." if @accountIds > 1;
    
    return unless $accountIds[0];
    $accountId = $accountIds[0];
    $obj->_setAccountIdForHostnameToCache($hostname, $accountId);
  }
  return $context->getObjectById($accountId);
}
#-----------------------------------------------------------------------------
sub _getAccountIdForHostnameFromCache {
  my ($obj, $hostname) = @_;
  my $hostnameHash = $context->getMemcached()->get( $obj->_getCacheId() );
  return $hostnameHash->{$hostname} if exists $hostnameHash->{$hostname};
  return undef;
}
#-----------------------------------------------------------------------------
sub _setAccountIdForHostnameToCache {
  my ($obj, $hostname, $accountId) = @_;
  my $hostnameHash = $context->getMemcached()->get( $obj->_getCacheId() );
  $hostnameHash->{$hostname} = $accountId;
  $context->getMemcached()->set( $obj->_getCacheId(), $hostnameHash );
  return 1;
}
#-----------------------------------------------------------------------------
sub _resetHostnameCache {
  my ($obj) = @_;
  $context->getMemcached()->set( $obj->_getCacheId(), {} ); # sets just and empty hash here to reset the caching
}
#-----------------------------------------------------------------------------
sub _getCacheId {
  my ($obj) = @_;
  return __PACKAGE__ . ':hostnameMap';
}
#-----------------------------------------------------------------------------
1;
