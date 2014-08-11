package O2CMS::Backend::Gui::System::Tree;

# Displays explorer tree

use strict;

use base 'O2CMS::Backend::Gui';

use O2 qw($context);

use O2::Util::List qw(upush);

my $MAX_NUM_FOLDER_ITEMS_TO_LOAD = 500;

#-------------------------------------------------------------------------------
sub showTree {
  my ($obj) = @_;
  my $backendUser = $context->getUser() or die 'Not logged in';
  
  my @expandFolders = split /,/, ($obj->getParam('expandFolders') || '');
  if (!@expandFolders  &&  $backendUser->getAttribute('treeExpandedFolders')) {
    @expandFolders = split /,/, $backendUser->getAttribute('treeExpandedFolders');
  }
  unshift @expandFolders, undef;
  require O2::Javascript::Data;
  my $jsData = O2::Javascript::Data->new();
  
  $obj->display(
    'tree.html',
    expandFolders => $jsData->dump(\@expandFolders),
  );
}
#-------------------------------------------------------------------------------
sub rememberTree {
  my ($obj) = @_;
  my $backendUser = $context->getUser() or die "Not logged in";
  my @expandFolders = split /,/, ($obj->getParam('expandFolders') || '');
  
  # Only save folders that have a parentFolder which is also saved.
  my %expandFolders = map { $_ => 1 } @expandFolders;
  foreach my $folder (@expandFolders) {
    my ($parentFolder) = $folder =~ m{ \A (.*) [.] \d+ \z }xms;
    delete $expandFolders{$folder} if $parentFolder && !$expandFolders{$parentFolder};
  }
  @expandFolders = keys %expandFolders;
  $backendUser->setAttribute( 'treeExpandedFolders', join (',', @expandFolders) );
  $backendUser->save();
  return 1;
}
#-------------------------------------------------------------------------------
sub setSortMethod {
  my ($obj) = @_;
  my $folder = $context->getObjectById( $obj->getParam('folderId') );
  $folder->setChildSortMethod(    $obj->getParam('method')    );
  $folder->setChildSortDirection( $obj->getParam('direction') );
  return 1;
}
#-------------------------------------------------------------------------------
sub createCategory {
  my ($obj) = @_;
  my $category = $context->getSingleton('O2CMS::Mgr::CategoryManager')->newObject();
  $category->setMetaName(     $obj->getParam('name')     );
  $category->setMetaParentId( $obj->getParam('parentId') );
  $category->save();
  
  return {
    categoryId  => $category->getId(),
  };
}
#-------------------------------------------------------------------------------
sub expandFolder {
  my ($obj) = @_;
  my %params = $obj->getParams();
  my $folderCode = $params{folderCode};
  my $skip       = $params{numItemsLoaded} || 0;
  
  my @path;
  my $folderId;
  if (defined $folderCode) {
    @path = split /[.]/, $folderCode;
    $folderId = pop @path;
  }
  
  my @objects;
  my %classOrder = (
    'O2CMS::Obj::Installation'        => 3,
    'O2CMS::Obj::Category::Templates' => 2,
    'O2CMS::Obj::Trashcan'            => 1,
  );
  
  my $metaTreeMgr = $context->getSingleton('O2::Mgr::MetaTreeManager');
  my $folder;
  if ($folderId > 0) {
    $folder = $context->getObjectById($folderId)  ||  $context->getSingleton('O2::Mgr::UniversalManager')->getTrashedObjectById($folderId) or die "FolderId $folderId is not a folder";
    die "Object '" . $folder->getMetaName() . "' ($folderId) did not return true for isContainer()" unless $folder->isContainer();
    
    my @objectIds;
    @objectIds =       $folder->getChildIds( undef, undef, -isa => 'O2::Obj::WebCategory', _folderCode => $folderCode ) unless $folder->isa('O2::Obj::Template::Directory');
    push  @objectIds,  $folder->getChildIds( undef, undef, -isa => 'O2::Obj::Page',        _folderCode => $folderCode ) unless $folder->isa('O2::Obj::Template::Directory');
    upush @objectIds,  $folder->getChildIds( undef, undef,                                 _folderCode => $folderCode );
    splice @objectIds, 0, $skip                      if $skip;
    splice @objectIds, $MAX_NUM_FOLDER_ITEMS_TO_LOAD if @objectIds > $MAX_NUM_FOLDER_ITEMS_TO_LOAD;
    @objects = $obj->getContext()->getObjectsByIds(@objectIds);
  }
  else {
    # no object to call getChildren on for top level...
    @objects = $context->getSingleton('O2::Mgr::ObjectManager')->objectSearch(
      metaClassName => { in     => [keys %classOrder] },
      metaParentId  => { isNull => 1                  },
    );
    @objects = sort {  $classOrder{ $b->getMetaClassName() } <=> $classOrder{ $a->getMetaClassName() }  } @objects;
  }
  
  # containers shouldn't be affected by filters (since you may end up with an empty tree)
  
  # filter out deleted objects (unless we're expanding a trashcan folder
  my ($topCategory) = $metaTreeMgr->getObjectPath($folder);
  if (!$topCategory || !$topCategory->isa('O2CMS::Obj::Trashcan')) {
    @objects = grep { $_ && !$_->isDeleted() } @objects;
  }
  elsif ($topCategory->isa('O2CMS::Obj::Trashcan')) {
    @objects = grep { $_ && $_->getMetaStatus() ne 'deleted' } @objects;
  }
  
  # order objects: webcategories, pages, other
  my @webCategories = grep {  $_->isa('O2CMS::Obj::WebCategory')                                 } @objects;
  my @pages         = grep {  $_->isa('O2CMS::Obj::Page')                                        } @objects;
  my @other         = grep { !$_->isa('O2CMS::Obj::WebCategory') && !$_->isa('O2CMS::Obj::Page') } @objects;
  @objects = (@webCategories, @pages, @other);
  
  my @files;
  my $i = 0;
  foreach my $object (@objects) {
    $i++;
    my $realObject = $object->getRealObject(); # expose objects as themselves
    my %file = (
      id            => $object->getId(),
      name          => $object->getMetaName(),
      iconUrl       => $object->getIconUrl(),
      className     => $realObject->getMetaClassName(),
      isContainer   => $object->isContainer(),
      parentId      => $object->getMetaParentId(),
      folderCode    => defined $folderCode ? "$folderCode.".$object->getId() : '.'.$object->getId(),
      isWebCategory => $object->isa('O2CMS::Obj::WebCategory'),
    );
    if ( $object->isa('O2::Obj::Image') ) {
      $file{imagePreviewUrl} = eval {
        $object->getScaledUrl(100, 100);
      };
    }
    
    push @files, \%file;
  }
  
  # Add load more-link if necessary
  my ($nextObject) = $folder ? $folder->getChildren($skip+$MAX_NUM_FOLDER_ITEMS_TO_LOAD, 1) : ();
  if ($nextObject) {
    push @files, {
      name          => $obj->getLang()->getString('o2.desktop.loadMoreItems'),
      isContainer   => 0,
      folderCode    => $folderCode || undef,
      isWebCategory => 0,
      isAddMoreLink => 1,
    };
  }
  
  return {
    folderCode => $folderCode eq 'null' ? '' : $folderCode,
    fileItems  => \@files,
    numSkipped => $skip,
  };
}
#-------------------------------------------------------------------------------
sub move {
  my ($obj) = @_;
  my @fileIds = split /,/, $obj->getParam('fileIds');
  my $metaTreeMgr = $context->getSingleton('O2::Mgr::MetaTreeManager');
  my $errorMessages = '';
  my $fromFolderId;
  foreach my $fileId (@fileIds) {
    my $errorCode;
    $fromFolderId = $context->getObjectById($fileId)->getMetaParentId();
    $errorCode    = $metaTreeMgr->move( $fileId, $obj->getParam('toFolderId') );
  }
  
  return {
    fromFolderId  => $fromFolderId,
    toFolderId    => $obj->getParam('toFolderId'),
    errorMessages => $errorMessages,
  };
}
#-------------------------------------------------------------------------------
sub restoreFromTrash {
  my ($obj) = @_;
  my $objectId   = $obj->getParam('objectId');
  my $trashcanId = $obj->getParam('trashcanId');
  
  my $restoredObject = $context->getSingleton('O2CMS::Mgr::TrashcanManager')->restoreFromTrash($trashcanId, $objectId)
    or die "Could not restore from trash, trashscanId = $trashcanId, objectId = $objectId";
  
  return {
    restoredInFolderId => $restoredObject->getMetaParentId(),
    trashcanId         => $trashcanId,
  };
}
#-------------------------------------------------------------------------------
sub emptyTrash {
  my ($obj) = @_;
  my $trashcanId = $obj->getParam('trashcanId');
  $context->getSingleton('O2CMS::Mgr::TrashcanManager')->emptyTrash($trashcanId) or die 'Could not empty trash';
  
  return {
    trashcanId => $trashcanId,
  };
}
#-------------------------------------------------------------------------------
1;
