package O2CMS::Backend::Gui::Article::Editor;

use strict;

use base 'O2CMS::Backend::Gui';

use O2 qw($context $cgi $config);

#---------------------------------------------------------------------------------------
sub init {
  my ($obj) = @_;
  use Time::HiRes qw/time/;
  my $start = time;
 
  #startup the editor in this category
  my $catId = $obj->getParam("catId");
  #use this article
  my $artId = $obj->getParam("artId");
  
  my $article = $artId ? $context->getObjectById($artId) : $context->getSingleton('O2CMS::Mgr::ArticleManager')->newObject();
  $obj->error("Article not found") unless $article;
  $article->setIsSearchable(1)     unless $artId;
  $article->setMetaParentId($catId)    if $catId;

  $obj->edit($article);
}
#---------------------------------------------------------------------------------------
sub edit {
  my ($obj, $article, $revisionId) = @_;
  my ($revision, $draft);
  $revision = $context->getObjectById($revisionId) if $revisionId;
  if (!$revision || !$revision->isa('O2CMS::Obj::Draft')) {
    # Find the draft for this article
    $draft = $context->getSingleton('O2CMS::Mgr::DraftManager')->getDraftByObjectId( $article->getId() ) if $article->getId();
  }
  # Find draftId
  my $draftId;
  $draftId = $draft->getId() if $draft;
  $draftId = $revisionId     if !$draftId && $revision && $revision->isa('O2CMS::Obj::Draft');

  my $hasNewerDraft = $revision   &&   $revision->isa('O2CMS::Obj::Draft')   &&   $revision->getMetaChangeTime()-10 > $article->getMetaChangeTime();
  $hasNewerDraft    = $draft->getMetaChangeTime()-10 > $article->getMetaChangeTime() if !$hasNewerDraft && $draft;
  $obj->display(
    'editor.html',
    categoryId    => $article->getMetaParentId(),
    article       => $article,
    draftId       => $draftId,
    hasNewerDraft => $hasNewerDraft && ($revision ? $revision->isa('O2CMS::Obj::Draft') : 1),
    publishPlaces => [ $article->getPublishPlaces() ],
  );
}
#---------------------------------------------------------------------------------------
sub openRevision {
  my ($obj, $article, $revisionId) = @_;
  $obj->edit($article, $revisionId);
}
#---------------------------------------------------------------------------------------
sub preview {
  my ($obj) = @_;
  my $category = $context->getObjectById( $obj->getParam('categoryId') );
  $cgi->redirect( $category->getUrl() . $obj->getParam('draftId') . '.o2?preview=1' );
}
#---------------------------------------------------------------------------------------
sub showRevisions {
  my ($obj) = @_;
  my @revisions;
  my $articleId = $obj->getParam("artId");

  if ($articleId) {
    my $revisionMgr = $context->getSingleton('O2::Mgr::RevisionedObjectManager');
    @revisions = sort { $a->getId() <=> $b->getId() } $revisionMgr->getRevisionsByObjectId($articleId);
  }
  $obj->display(
    'showRevisions.html',
    articleRevisions => \@revisions,
  );
}
#---------------------------------------------------------------------------------------
sub restoreToRevision {
  my ($obj) = @_;
  my $articleId  = $obj->getParam("artId");
  my $revisionId = $obj->getParam("revisionId");
  
  if ($articleId && $revisionId) {
    my $revisionMgr = $context->getSingleton('O2::Mgr::RevisionedObjectManager');
    my $revObj = $revisionMgr->getObjectById( $revisionId );
    if ($revObj->getRevisionedObjectId() != $articleId) { # just checking one more time
      die "The given revision Id '$revisionId' is not a rev. object for article with id '$articleId'"; 
    }
    $obj->init() if $revisionMgr->restoreRevision($revObj);
  }
  die "An error occured while restoring object id '$revisionId' as article with id '$articleId'";
}
#---------------------------------------------------------------------------------------
sub saveDraft {
  my ($obj) = @_;
  my $draft = $obj->_saveDraft();
  return {
    draftId => $draft ? $draft->getId() : undef,
  };
}
#---------------------------------------------------------------------------------------
sub _saveDraft {
  my ($obj, $articleId) = @_;
  my %q = $obj->getParams();
  my ($draft, $article);
  $articleId ||= $q{articleId};
  
  if ($articleId) {
    my $draftMgr = $context->getSingleton('O2CMS::Mgr::DraftManager');
    $draft   = $draftMgr->getDraftByObjectId( $articleId  );
    $draft ||= $draftMgr->getObjectById(      $q{draftId} ) if $q{draftId};
    if ($draft) {
      $article = $draft->getUnserializedObject();
      $article->setId($articleId);
    }
    else {
      $draft = $draftMgr->newObject();
      $article = $context->getObjectById($articleId);
    }
    die "\$draft is not of class O2CMS::Obj::Draft" if ref ($draft) ne 'O2CMS::Obj::Draft';
  }
  
  if (!$article) {
    $article = $context->getSingleton('O2CMS::Mgr::ArticleManager')->newObject();
    my $parentId = $q{parentId} || $q{category};
    die "Missing objectId or parentId" if !$articleId && !$parentId;
    
    $article->setMetaParentId($parentId) if $parentId;
  }
  $draft ||= $context->getObjectById( $q{draftId} ) if $q{draftId};
  $obj->_fillObject($article, %q);
  my %texts = $article->getTexts();
  return unless %texts;
  
  $draft = $article->saveDraft($draft); # But we're not saving the article
  return $draft;
}
#---------------------------------------------------------------------------------------
sub _fillObject {
  my ($obj, $article, %params) = @_;
  my $object = $cgi->getStructure('object');
  my $keywords;
  $keywords = $object->{keywordIds} if  ref $object eq 'HASH';
  $keywords = [ $keywords ]         if !ref $keywords && $keywords =~ m/\d?_\w+/;
  if (ref $keywords eq 'ARRAY') {
    my $keywordMgr = $context->getSingleton('O2::Mgr::KeywordManager');
    my @keywordIds;
    foreach my $rawKeyword (@{ $keywords }) {
      my ($keywordId, $keywordName) = split /_/, $rawKeyword, 2;
      if ( $keywordId !~ m/^\d+$/ ) { # It's an ID
        my $keyword = $keywordMgr->newObjectByName($keywordName);
        $keyword->save();
        $keywordId = $keyword->getId();
      }
      push @keywordIds, $keywordId;
    }
    $article->setKeywordIds(@keywordIds);
  }

  $article->setRelatedArticles( split /,/, $params{articleRelations}   );
  $article->setMetaParentId(    $params{parentId} || $params{category} );

  my $metaname = $params{$article->getCurrentLocale() . 'articleTitle'};
  foreach my $locale ($article->getAvailableLocales()) {
    last if $metaname;
    $metaname = $params{"$locale.articleTitle"};
  }
  $article->setMetaName($metaname) unless $article->getMetaName(); # Håkon. Added unless.

  foreach my $locale ($article->getAvailableLocales()) {
    $article->setCurrentLocale($locale);
    $article->setTitle($params{"$locale.articleTitle"});
  }

  $article->setMetaStatus(     $params{status} || $params{oldStatus}  );
  $article->setIsSearchable(   $params{isSearchable}                  );
  $article->setMetaChangeTime( time                                   );

  # Hack for including publish/unpublish dates
  my $publishTime = $obj->_date2epoch( $params{publishDateText} );
  $article->setPublishTime(   $publishTime                                    );
  $article->setUnPublishTime( $obj->_date2epoch( $params{unPublishDateText} ) );

  my %deletedTexts;
  foreach (grep {/text/i} (keys %params)) {
    next if $_ =~ m{ \A _ }xms;
    $params{$_} = $obj->_parseImages($params{$_},$article) if $_=~m{ \A   (?: \w\w_\w\w [.] )?   section_ }xmsi;
    if ($_ =~ m{ \A (\w\w_\w\w) [.] (.+) \z }xms) {
      my $locale  = $1;
      my $textKey = $2;
      $deletedTexts{$textKey} = 1;
      $article->setCurrentLocale($locale);
      $params{$_} = $obj->_filterOutBuggyDragIcon($params{$_});
      $article->setText($textKey, $params{$_});
    }
    else {
      $article->setText($_,$params{$_}) unless $deletedTexts{$_}; # Avoid unpredictable fuckup. Entire foreach loop should perhaps be rewritten?
    }
  }

  # what urls 
  if ( $config->get('publisher.allowPublishingPerUrl') eq 'yes' ) {
    my @publishableUrls = ref $params{publishableUrls} ? @{$params{publishableUrls}} : $params{publishableUrls};
    @publishableUrls = grep {$_} @publishableUrls;
    $article->setPublishableUrls(@publishableUrls);
  }
}
#---------------------------------------------------------------------------------------
# sometimes the drag-icon "gets stuck" in the html. This is a symptom fix
sub _filterOutBuggyDragIcon {
  my ($obj, $html) = @_;
  $html =~ s|<div[^>]+?id="dragElement".*?</div>||gs;
  return $html;
}
#---------------------------------------------------------------------------------------
sub saveArticle {
  my ($obj) = @_;
  my %params = $obj->getParams();

  my $article;
  if ($params{articleId}) {
    $article = $context->getObjectById( $params{articleId} );
  }
  else {
    $article = $context->getSingleton('O2CMS::Mgr::ArticleManager')->newObject();
    $article->setMetaOwnerId( $context->getUserId() );
  }

  $obj->_fillObject($article, %params);
  eval {
    $article->save();
    $obj->_saveDraft( $article->getId() );
  };
  # Since saveArticle is done in an invisible iframe, we have to print a javascript call to that iframe in
  # order for us to display the error message in the browser. The jsError method does that.
  return $obj->jsError($@, 'An error occurred while trying to save the article:') if $@;

  # publish article
  my $pageMgr = $context->getSingleton('O2CMS::Mgr::PageManager');
  $pageMgr->publishDirectly($article->getId(), $params{directPublishData}) if $article->getMetaStatus() eq 'approved';

  my $artId    = $article->getId();
  my $parentId = $article->getMetaParentId();
  return {
    articleId => $artId,
  };
}
#---------------------------------------------------------------------------------------
sub _date2epoch {
  my ($obj, $dateStr) = @_;
  return unless $dateStr;
  return $context->getSingleton('O2::Mgr::DateTimeManager')->newObject($dateStr)->getEpoch();
}
#---------------------------------------------------------------------------------------
# find all images tags and replaces them with ready scaled url + also finds allready existing O2 imgs
sub _parseImages {
 my ($obj, $html, $article) = @_;

 my $imgId = 0;
 my @imgStack;
 my %imgIds;
 while ($html =~ s|(<img[^>]+>)|#imgId_$imgId#|xms && $imgId++ <1000) { # Max 1000 images in one article should be enough? 
   my ($imgTag, $imageId) = $obj->_evalImgTag($1);
   push @imgStack, $imgTag;
   $imgIds{$imageId} = 1 if $imageId;
 }
 for (my $i = 0; $i < @imgStack; $i++) {
   $html =~ s/\#imgId_$i\#/$imgStack[$i]/xms;
 }
 $article->setImageIds( keys %imgIds );
 return $html; 
}
#---------------------------------------------------------------------------------------
sub _evalImgTag {
  my ($obj, $imgTag) = @_;
  $obj->_debug("_evalImgTag($imgTag) called");
  return $imgTag if $imgTag !~ m{(Image-Editor/previewCommands|imageRepository)}xms;
  
  $imgTag =~ s/src\=\"([^\"]+)\"/#url#/xmis;
  my $imgUrl = $1;
  $obj->_debug("Url of img-tag: $imgUrl");

  my ($oldHeight, $oldWidth);
  my ($objectId) = $imgUrl =~ m/id\=(\d+)/xms;
  ($objectId, $oldHeight, $oldWidth) = $imgUrl =~ m{ / (\d+) _? (\d*)? x? (\d*)? [.] \w+ \z }xms unless $objectId;
  if (!$objectId) {
    $imgTag =~ s/\#url\#/src=\"$imgUrl\"/xms;
    return $imgTag;
  }

  my ($_quote1, $_quote2);
  ($_quote1, $oldWidth)  = $imgTag =~ m{ width  = ([\"\']) (\d+) \1 }xmsi unless $oldWidth;
  ($_quote2, $oldHeight) = $imgTag =~ m{ height = ([\"\']) (\d+) \1 }xmsi unless $oldHeight;

  # is there style defined?
  my ($height) = $imgTag =~ m/height\:\s?(\d+)px/ixms;
  ($height)    = $imgTag =~ m{height=[\"\'] (\d+) [\"\']}ixms unless $height;
  my ($width)  = $imgTag =~ m/width\:\s?(\d+)px/ixms;
  ($width)     = $imgTag =~ m{width=[\"\'] (\d+) [\"\']}ixms unless $width;
  $height ||= $oldHeight;
  $width  ||= $oldWidth;
  my $useReasonableSize = 0;
  if (!$height) { # nope, no CSS style. user was happy with the default size
    ($width, $height) = $imgUrl =~ m/resize\,(\d+)\,(\d+)/xms;
    $useReasonableSize = 1;
  }

  # putting the url back
  if (!$height && !$width) {
    $imgTag =~ s/\#url\#/src=\"$imgUrl\"/xms;
    return $imgTag;
  }

  if ($objectId) {
    my $imageObj = $context->getObjectById($objectId); # If we don't get an object back, it may have been deleted
    if ($imageObj) {
      my $scaledUrl = $imageObj->getScaledUrl($width, $height); # use same fileformat when resizing vonheim@20061114
      if ($useReasonableSize) {
        $scaledUrl = $imageObj->getFileUrl() if $imageObj->getWidth() < 800 && $imageObj->getHeight() < 800;
      }
      $imgTag =~ s/\#url\#/src=\"$scaledUrl\"/xms;
    }
    else {
      $imgTag =~ s/\#url\#/src=\"$imgUrl\"/xms; # Using the original image url as default if the image object doesn't exist (to avoid too much confusion)
    }
  }
      
  return ($imgTag, $objectId);
}
#---------------------------------------------------------------------------------------
sub blank {
  my ($obj) = @_;
  my $time = time;
  print qq{<html><body><!-- $time --></body></html>};
}
#---------------------------------------------------------------------------------------
sub _debug {
  my ($obj, $message) = @_;
#  print "<font color=blue>$message</font><br>\n";
}
#---------------------------------------------------------------------------------------
sub jsError {
  my ($obj, $msg, $title) = @_;
  $title ||= 'An error occurred';
  $msg   = "<b>$title</b>\n\n$msg";
  $msg   =~ s{ \" }{&quot;}xmsg;
  $msg   =~ s{ \n }{<br>\\n}xmsg;
  print qq{<html><body><script language="javascript">top.displayError("$msg");</script></body></html>};  
  $cgi->output();
  $cgi->exit();
}
#---------------------------------------------------------------------------------------
1;
