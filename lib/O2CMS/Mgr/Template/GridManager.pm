package O2CMS::Mgr::Template::GridManager;

use strict;

use base 'O2CMS::Mgr::TemplateManager';

use O2 qw($context $db);
use O2CMS::Obj::Template::Grid;

#-------------------------------------------------------------------------------
sub initModel {
  my ($obj, $model) = @_;
  $obj->SUPER::initModel($model);
  $model->registerFields(
    'O2CMS::Obj::Template::Grid',
    # Your class definition goes here:
    #-----------------------------------------------------------------------------
    #-----------------------------------------------------------------------------
  );
}
#-------------------------------------------------------------------------------
sub init {
  my ($obj, $object) = @_;
  $obj->SUPER::init($object);
  my $slotList = $obj->_getSlotManager()->getSlotListById( $object->getId() );
  $object->setSlotList($slotList);
  return $object;
}
#-------------------------------------------------------------------------------
sub save {
  my ($obj, $object) = @_;
  $obj->SUPER::save($object);
  $obj->_getSlotManager()->saveSlotList( $object->getId(), $object->getSlotList() );
}
#-------------------------------------------------------------------------------
sub _getSlotManager {
  my ($obj) = @_;
  return $context->getSingleton('O2CMS::Mgr::Template::SlotManager');
}
#-------------------------------------------------------------------------------
sub deleteObjectPermanentlyById {
  my ($obj, $objectId) = @_;
  $obj->_getSlotManager()->deleteSlotsByObjectId($objectId);
  $obj->SUPER::deleteObjectPermanentlyById($objectId);
}
#-------------------------------------------------------------------------------
sub queryGrids {
  my ($obj, %params) = @_;
  return $obj->queryGridsOrIncludes('Grid', %params);
}
#-------------------------------------------------------------------------------
sub queryGridsOrIncludes {
  my ($obj, $Type, %params) = @_;
  my $type = lc $Type;
  if ($params{accepts}) {
    my @classes = split /,\s*/, $params{accepts};
    my $found = 0;
    foreach my $className (@classes) {
      $found = 1 if $className eq "O2CMS::Obj::Template::$Type";
    }
    return () unless $found;
  }
  my $templateMatch = $params{templateMatch};
  if (!$obj->{"${type}s"}->{$templateMatch}) {
    my $templateMatchSql = '';
    my @likeVars;
    my @templateMatches = split /\|/, $templateMatch;
    foreach my $match (@templateMatches) {
      push @likeVars, $db->glob2like($match);
      $templateMatchSql .= "t.path like ? or ";
    }
    $templateMatchSql = substr $templateMatchSql, 0, -3 if @likeVars;
    $templateMatchSql ||= "t.path like '%' ";

    my $query = "select o.objectId from O2CMS_OBJ_TEMPLATE t, O2_OBJ_OBJECT o where t.objectId = o.objectId and className = 'O2CMS::Obj::Template::$Type' and ($templateMatchSql)";
    my @objectIds = $db->selectColumn($query, @likeVars);
    my @objects   = $context->getObjectsByIds(@objectIds);
    @objects      = sort { $a->getMetaName() cmp $b->getMetaName() } @objects;
    $obj->{"${type}s"}->{$templateMatch} = \@objects;
  }
  return @{ $obj->{"${type}s"}->{$templateMatch} };
}
#-------------------------------------------------------------------------------
1;
