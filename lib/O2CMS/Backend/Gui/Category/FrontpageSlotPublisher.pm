package O2CMS::Backend::Gui::Category::FrontpageSlotPublisher;

use strict;

use base 'O2CMS::Backend::Gui';

use O2 qw($context $cgi);

#---------------------------------------------------------------------------------------
sub view {
  my ($obj) = @_;
  
  my $parentId = $obj->getParam('parentId');
  die "Missing parentId" unless $parentId;
  
  my @pages;
  
  my @selectedPageIds = $cgi->getParam('selectedPageIds');
  my %selectedPageIds = map { $_ => 1 } @selectedPageIds;
  
  my $pageMgr = $context->getSingleton('O2CMS::Mgr::PageManager');
  my @standardPageIds = $pageMgr->getCategoryStandardPageIds($parentId);
  
  # add page to standard list for this category
  if ( $obj->getParam('addedPageId') ) {
    my $addedPage = $context->getObjectById( $obj->getParam('addedPageId') );
    die "addedPageId parameter does not point to a valid object" unless $addedPage;
    # accept webcategory, but use its frontpage
    if ( $addedPage->isa('O2CMS::Obj::WebCategory') ) {
      $addedPage = $context->getObjectById( $addedPage->getFrontpageId() );
    }
    
    if ( !$addedPage->isa('O2CMS::Obj::Page') ) {
      push @pages, { status => 'objectNotAPage' };
    }
    else {
      my $alreadyAdded = grep { $_ == $addedPage->getId() }  @standardPageIds;
      if (!$alreadyAdded) {
        # add standard pages
        push @standardPageIds, $addedPage->getId();
        $pageMgr->setCategoryStandardPageIds($parentId, @standardPageIds);
      }
      # select it default 
      $selectedPageIds{ $addedPage->getId() } = 1;
    }
  }
  
  # remove page from standard list for this category
  if ( $obj->getParam('removedPageId') ) {
    @standardPageIds = grep { $_ != $obj->getParam('removedPageId') } @standardPageIds;
    $pageMgr->setCategoryStandardPageIds($parentId, @standardPageIds);
  }

  my @standardPages = $context->getObjectsByIds(@standardPageIds);
  foreach my $frontpage (@standardPages) {
    push @pages, $obj->_createPageStruct( $frontpage, $selectedPageIds{ $frontpage->getId() } );
  }

  @pages = sort { $a->{sortKey} cmp $b->{sortKey} } @pages;
  $obj->display(
    'view.html',
    pages    => \@pages,
    parentId => $parentId,
  );
}
#---------------------------------------------------------------------------------------
sub _createPageStruct {
  my ($obj, $page, $pageChecked) = @_;
  return { status => 'missingObject' } unless $page;

  my $lang = $context->getLang();

  my $slotList = $page->getSlotListWithTags();
  my @directPublishSlots;
  foreach my $tag ($slotList->getDirectPublishTags()) {
    # title is either slotId, title attribute or title attribute used as I18N key
    my $title = $tag->{slotId};
    if( $tag->{title} ) {
      $title = $tag->{title};
      $title = $lang->getString($title) if $lang->keyExists($title); # title might be a I18N key
    }
    
    # does slot contain an object?
    my $existingContent;
    my $slot = $slotList->getSlotById( $tag->{slotId} );
    $existingContent = $context->getObjectById( $slot->getContentId() ) if $slot && $slot->getContentId();
    
    # build list of slot info
    push @directPublishSlots, {
      slotId          => $tag->{slotId},
      title           => $title,
      existingContent => $existingContent,
    };
  }
  
  # select first slot, or use cgi param
  my $selectedSlotId = $obj->getParam( 'selectedSlotId_' . $page->getId() );
  $selectedSlotId    = $directPublishSlots[0]->{slotId} if !$selectedSlotId && @directPublishSlots;
  
  # direct publish status
  my $status = 'pageHasNoDirectPublishSlots';
  $status = 'singleSlot'    if @directPublishSlots == 1;
  $status = 'multipleSlots' if @directPublishSlots  > 1;
  
  my @categoryPath = map { $_->getMetaName() } $page->getCategoryPath();
  my $sortKey  = join '/', @categoryPath;
  my $hostname = shift @categoryPath;
  my $category = join ('', map "/$_", @categoryPath) .'/';
  $category .= $page->getMetaName() unless $page->isa('O2CMS::Obj::Frontpage'); # include page name only for Page objects, not Frontpage objects
  
  return {
    page               => $page,
    directPublishSlots => \@directPublishSlots,
    status             => $status,
    checked            => $pageChecked,,
    selectedSlotId     => $selectedSlotId,
    sortKey            => $sortKey,
    hostname           => $hostname,
    category           => $category,
  };
}
#---------------------------------------------------------------------------------------
1;
