package O2CMS::Backend::Gui::Category::Manager;

use strict;

use base 'O2CMS::Backend::Gui';

use O2 qw($context);

#---------------------------------------------------------------------------------------
sub init {
  my ($obj, $skip) = @_;
  $skip ||= 0;
  $obj->{loadIncrements} = 100; # Load this number of items at a time
  my $categoryId = $obj->getParam("catId") or return;
  my $category   = $context->getObjectById($categoryId) || $context->getSingleton('O2::Mgr::UniversalManager')->getTrashedObjectById($categoryId);

  my $categoryNameEscaped = $category->getMetaName();
  $categoryNameEscaped    =~ s{ \' }{&apos;}xmsg;
  $categoryNameEscaped    =~ s{ \" }{&quot;}xmsg;

  my $parent = $category->getParent();
  my $parentCategoryId = $parent && $parent->isa('O2::Obj::Container') ? $parent->getId() : undef;

  my $user = $context->getUser();
  my @columnOrder  = split /,/, $user->getAttribute('categoryBrowserColumnOrder');
  my @columnWidths = split /,/, $user->getAttribute('categoryBrowserColumnWidths');
  @columnOrder     = qw(smallIcon name owner type status createTime modifiedTime) unless @columnOrder;
  @columnWidths    = qw(   16      168  169   140   70       105         105    ) unless @columnWidths;
  my @columns;
  foreach  my $columnName (@columnOrder) {
    push @columns, {
      name  => $columnName,
      Name  => ucfirst $columnName,
      width => shift(@columnWidths),
    };
  }
  my $sortBy        = $user->getAttribute('categoryBrowserSortByColumn')    || 'name';
  my $sortDirection = $user->getAttribute('categoryBrowserSortByDirection') || 'ascending';
  my $sortType      = $user->getAttribute('categoryBrowserSortType')        || 'string';
  my @objects = $obj->_getCategoryObjects($category, $skip);
  @objects
    = $sortType eq 'numeric'
    ? sort { $obj->getCellValue($a, $sortBy, 1) <=> $obj->getCellValue($b, $sortBy, 1) } @objects
    : sort { $obj->getCellValue($a, $sortBy, 1) cmp $obj->getCellValue($b, $sortBy, 1) } @objects
    ;
  @objects = reverse @objects if $sortDirection eq 'descending';

  my $template = $skip ? 'includes/items.html' : 'init.html';
  $obj->display(
    $template,
    category            => $category,
    parentId            => $category->getMetaParentId(),
    viewMode            => $user->getAttribute('categoryBrowserViewMode') || 'listView',
    objects             => \@objects,
    categoryNameEscaped => $categoryNameEscaped,
    parentCategoryId    => $parentCategoryId,
    columns             => \@columns,
    guiModule           => $obj,
    numObjects          => scalar @objects,
    skipped             => $skip,
  );
}
#---------------------------------------------------------------------------------------
sub _getCategoryObjects {
  my ($obj, $category, $skip) = @_;
  my @children;
  @children = $category->getChildren( $skip, $obj->{loadIncrements} ) if $category->isContainer();

  my @activeChildren;
  foreach my $child (@children) {
    push @activeChildren, $child;
  }
  return @activeChildren;
}
#---------------------------------------------------------------------------------------
sub getCellValue {
  my ($obj, $object, $type, $isForSort) = @_;
  if ($type eq 'smallIcon') {
    return $isForSort ? $object->getIconUrl() : '<img class="categoryBrowserItemIcon" src="' . $object->getIconUrl() . '">';
  }
  if ($type eq 'name') {
    return $isForSort ? lc $object->getMetaName() : $object->getMetaName();
  }
  if ($type eq 'owner') {
    my $owner = $object->getOwner();
    return '' unless $owner;
    return $isForSort ? lc $owner->getFullName() : $owner->getFullName();
  }
  
  return $object->getMetaClassName() if $type eq 'type';
  return $object->getMetaStatus()    if $type eq 'status';
  
  my $dateFormatter = $context->getDateFormatter();
  return $dateFormatter->dateFormat( $object->getMetaCreateTime(), 'Y-MM-dd HH:mm' ) if $type eq 'createTime';
  return $dateFormatter->dateFormat( $object->getMetaChangeTime(), 'Y-MM-dd HH:mm' ) if $type eq 'modifiedTime';
}
#---------------------------------------------------------------------------------------
sub getFolderCode {
  my ($obj, $object) = @_;
  return '' unless $object->isa('O2::Obj::Container');
  
  my @idPath = $context->getSingleton('O2::Mgr::MetaTreeManager')->getIdPathTo( $object->getId() );
  return '.' . join '.', @idPath if @idPath;
}
#---------------------------------------------------------------------------------------
# Ajax method
sub displayCurrentPath {
  my ($obj) = @_;
  my $categoryId = $obj->getParam('categoryId');
  $obj->error('CategoryId missing in method displayCurrentPath') unless $categoryId;
  my @path = $context->getSingleton('O2::Mgr::MetaTreeManager')->getObjectPath($categoryId);
  shift @path if @path > 1; # Remove installation-object
  @path = map { $_->getMetaName() } @path;
  $obj->display(
    'currentPath.html',
    path            => \@path,
    numPathElements => scalar @path,
  );
}
#---------------------------------------------------------------------------------------
sub setViewMode {
  my ($obj) = @_;
  my $user = $context->getUser();
  $user->setAttribute( 'categoryBrowserViewMode', $obj->getParam('mode') );
  $user->save();
  return 1;
}
#---------------------------------------------------------------------------------------
sub trashObjects {
  my ($obj) = @_;
  my $universalMgr = $context->getSingleton('O2::Mgr::UniversalManager');
  my @ids = split /,/, $obj->getParam('ids');
  foreach my $id (@ids) {
    $universalMgr->deleteObjectById($id);
  }
  return {
    deletedIds => join (',', @ids),
    trashcanId => $context->getTrashcanId(),
  };
}
#---------------------------------------------------------------------------------------
sub saveColumnOrder {
  my ($obj) = @_;
  my $user = $context->getUser();
  $user->setAttribute( 'categoryBrowserColumnOrder', $obj->getParam('order') );
  $user->save();
  return 1;
}
#---------------------------------------------------------------------------------------
sub saveColumnWidths {
  my ($obj) = @_;
  my $user = $context->getUser();
  $user->setAttribute( 'categoryBrowserColumnWidths', $obj->getParam('widths') );
  $user->save();
  return 1;
}
#---------------------------------------------------------------------------------------
sub saveSortByInfo {
  my ($obj) = @_;
  my $user = $context->getUser();
  $user->setAttribute( 'categoryBrowserSortByColumn',    $obj->getParam('field')     );
  $user->setAttribute( 'categoryBrowserSortByDirection', $obj->getParam('direction') );
  $user->setAttribute( 'categoryBrowserSortType',        $obj->getParam('sortType')  );
  $user->save();
  return 1;
}
#---------------------------------------------------------------------------------------
sub getMoreResults {
  my ($obj) = @_;
  return $obj->init( $obj->getParam('skip') );
}
#---------------------------------------------------------------------------------------
1;
