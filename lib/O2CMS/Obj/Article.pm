package O2CMS::Obj::Article;

use strict;

use base 'O2::Obj::Object';

use O2 qw($context $config);

#-------------------------------------------------------------------------------
sub new {
  my ($pkg, %init) = @_;
  my $obj = $pkg->SUPER::new(%init);
  return $obj;
}
#-------------------------------------------------------------------------------
sub isPageCachable {
  return 1;
}
#-------------------------------------------------------------------------------
sub isSerializable {
  return 1;
}
#-------------------------------------------------------------------------------
sub isDeletable {
  return 1;
}
#-------------------------------------------------------------------------------
sub isRevisionable {
  return 1;
}
#-------------------------------------------------------------------------------
# set text by name
sub setText {
  my ($obj, $name, $text) = @_;
  my %texts = $obj->getTexts();
  $texts{$name} = $text;
  $obj->setTexts(%texts);
}
#-------------------------------------------------------------------------------
# returns text by name
#
# Parameters exist to modify the size of images: imageWidth, imageHeight, onImageTooBig, onImageTooSmall, imageKeepAspectRatio.
# These parameters are very similar to the parameters to <o2 img>, so check out that tag's documentation.
sub getText {
  my ($obj, $name, %params) = @_;
  my %texts = $obj->getTexts();
  my $text = $texts{$name} || '';
  $text    = $obj->_getTextWithResizedImages($text, %params) if %params;

  if ( !$params{skipIncludeFiles} ) { # If skipIncludeFiles is true, we won't include included files. This is mainly for use with the editor so that the editor can display the link to the file to be included
    $text =~ s/(<a\s+href="[^\d]+)(\d+)(\.o2">[^<]+<\/a>)/$obj->_includeFile($1,$2,$3)/eg;
  }

  return $text;
}
#-------------------------------------------------------------------------------
# Method for including files included by drag'n'drop in the form of <a href="/4250.o2">filename.html</a>
sub _includeFile {
  my ($obj, $pre, $objectId, $post) = @_;
  
  if ($objectId) {
    my $object = $context->getObjectById($objectId);
    if ( $object && $object->isa('O2CMS::Obj::Template') ) {  # Only parse/include templates
      my $file = $object->parse();
      if ($file) {
        return ref $file ? ${$file} : $file;
      }
    }
  }
  return join '', ($pre, $objectId, $post);
}
#-------------------------------------------------------------------------------
# Method for getting the first image in a text and removing it from the text while returning the image (scaled/cropped/resized)
# NB! If one saves the article while doing this, it naturally saves it with the image removed
sub getAndRemoveFirstImage {
  my ($obj, $textSectionName, %params) = @_;

  my %texts = $obj->getTexts();
  my $text = $texts{$textSectionName};

  $text =~ s{ ( <img [^>]+ src= ([\"\']) [^\"\']+ / (\d+) [.] \w+ \2 .*? > ) }{}xms;
  my ($imgTag, $quote, $id) = ($1, $2, $3);
  return unless $imgTag;
  
  my $firstImageTag = $obj->_getNewImgTag($imgTag, $id, %params);
  $obj->setText( $textSectionName => $text ); 
  return $firstImageTag;
}
#-------------------------------------------------------------------------------
sub _getTextWithResizedImages {
  my ($obj, $text, %params) = @_;
  my $taglib = $obj->_getHtmlTaglib();
  $text =~ s{ ( <img [^>]+ src= ([\"\']) [^\"\']+ / (\d+) [.] \w+ \2 .*? > ) }{$obj->_getNewImgTag($1, $3, %params)}xmsge;
  return $text;
}
#-------------------------------------------------------------------------------
sub _getHtmlTaglib {
  my ($obj) = @_;
  if (!$obj->{htmlTaglib}) {
    my $tagParser = $context->getSingleton('O2::Template::TagParser');
    $obj->{htmlTaglib} = $tagParser->getTaglibByName('Html');
  }
  return $obj->{htmlTaglib};
}
#-------------------------------------------------------------------------------
sub _getNewImgTag {
  my ($obj, $originalImgTag, $id, %params) = @_;
  return $originalImgTag if $originalImgTag !~ m{ imageRepository }xms;

  my @align;

  if ( $originalImgTag =~ m/align\s*=\s*[\'\"]?([^\'\"\s]+)[\'\"]?/ ) {
    push @align, 'align' => $1;
    push @align, 'class' => $1.'AlignedImage';
  }

  return $obj->_getHtmlTaglib()->img(
    id              => $id,
    width           => $params{imageWidth},
    height          => $params{imageHeight},
    onTooBig        => $params{onImageTooBig},
    onTooSmall      => $params{onImageTooSmall},
    keepAspectRatio => exists( $params{imageKeepAspectRatio} )  ?  $params{imageKeepAspectRatio}  :  1,
    @align,
  );
}
#-------------------------------------------------------------------------------
# returns text with o2-images removed
sub getTextWithoutImages {
  my ($obj, $name) = @_;
  my ($text, @images) = $obj->_splitTextAndImages($name);
  return $text;
}
#-------------------------------------------------------------------------------
# returns text without HTML
sub getTextWithoutHtml {
  my ($obj, $name) = @_;
  my $text = $obj->getText($name);

  $text =~ s/^[\s\r\n]+|[\s\r\n]+$//;
  $text =~ s/[\r\n]/ /g;
  $text =~ s/<[^>]+>//g; # XXX Replace with something more solid
  $text =~ s/\&\w+\;//g; # XXX Replace with something more solid
  $text =~ s/\x96/-/g;   # XXX Replace with something more solid
  $text =~ s/\x94/\"/g;  # XXX Replace with something more solid
  return $text;
}
#-------------------------------------------------------------------------------
sub getTextWithoutImagesAndFormTag {
  my ($obj, $name) = @_;
  my ($text, @images) = $obj->_splitTextAndImages($name);
  my $maxLoops = 100;
  while ( $maxLoops-- && $text =~ s{ < /? form [^>]* > }{}xms ) {
    # Don't need to do anything here
  }
  return $text;
}
#-------------------------------------------------------------------------------
# returns first image in text
sub getImage {
  my ($obj, $name) = @_;
  my @images = $obj->getImages($name);
  return $images[0];
}
#-------------------------------------------------------------------------------
# returns all images in text
sub getImages {
  my ($obj, $name) = @_;
  my ($text, @imageIds) = $obj->_splitTextAndImages($name);
  return $context->getObjectsByIds(@imageIds);
}
#-------------------------------------------------------------------------------
sub getFirstImageScaledUrl {
  my ($obj, $name, $width, $height, $fileFormat) = @_;
  my $image = $obj->getImage($name);
  return $image->getScaledUrl($width, $height, $fileFormat);
}
#-------------------------------------------------------------------------------------------------------------
# This function creates an PLDS representation of an object
sub getObjectPlds {
  my ($obj) = @_;
  
  my $plds = $obj->SUPER::getObjectPlds();
  
  # We don't do this unless the article actually has keywords attached to it
  my @keywordIds = $obj->getKeywordIds();
  return $plds if !@keywordIds || !$config->get('publisher.overrideObjectPldsInArticles');
  
  # Find all keyword IDs, revive keywords and then store their meta name in data->keywords (array)
  # which is added to the plds structure we got from SUPER
  my @keywords;
  foreach my $keywordId (@keywordIds) {
    my $keyword = $context->getObjectById($keywordId);
    push @keywords, $keyword->getMetaName() if $keyword;
  }
  
  # Place keywords into structure and return it
  $plds->{data}->{keywords} = \@keywords;
  return $plds;
}
#-------------------------------------------------------------------------------------------------------------
sub _splitTextAndImages {
  my ($obj, $name) = @_;
  my $text = $obj->getText($name);
  my @imageIds;
  my $maxLoops = 100;
  while ( $maxLoops-- && $text =~ s|<img [^>]*?src=\"[^\"]+?\b(\d+)[._][^>]+?>|| ) {
    push @imageIds, $1;
  }
  return ($text, @imageIds);
}
#-------------------------------------------------------------------------------
sub canMove {
  return 1;
}
#-------------------------------------------------------------------------------
# Returns true if object may be published
sub isPublishable {
  my ($obj, $url) = @_;
  
  my $publishTime   = $obj->getPublishTime();
  my $unPublishTime = $obj->getUnPublishTime();
  
  if ( $unPublishTime && $publishTime ) {
    return if $unPublishTime eq $publishTime;
    return if time > $unPublishTime && $publishTime > time;
    return if $unPublishTime > $publishTime && $unPublishTime < time;
  }
  else {
    return if $unPublishTime && $unPublishTime < time;
    return if $publishTime   && $publishTime   > time;
  }
  
  return if $obj->getMetaStatus() ne 'approved';

  # do we approve articles based on url?
  if ( $config->get('publisher.allowPublishingPerUrl') eq 'yes' ) {
    
    if (!$url) {
      # If url is empty the article will try to generate it by itself
      $url = $context->getSingleton('O2CMS::Publisher::UrlMapper')->generateUrl(
        object   => $obj,
        absolute => 'yes',
      );
    }
    
    # article is not publishable if url is not among those it is approved for
    return unless grep { $url=~/^$_/ } $obj->getPublishableUrls();
  }

  return 1;
}
#-------------------------------------------------------------------------------
sub isCurrentUrlPublishable {
  my ($obj) = @_;
  return 0 if $obj->isDeleted();
  
  my $url = $context->getSingleton('O2CMS::Publisher::UrlMapper')->generateUrl(
    object   => $obj,
    absolute => 'yes',
  );
  return $obj->isPublishable($url);
}
#-------------------------------------------------------------------------------
# This controls what sites the article can be published to. Add site ids to publisher.conf to controls what sites are available
sub getAvailablePublishableUrls {
  my ($obj) = @_;
  my $webCategoryIds = $obj->getContext()->getConfig()->get('publisher.availablePublishableWebCategoryIds');
  return map { $_->getUrl() } $obj->getContext()->getObjectsByIds( @{$webCategoryIds} );
}
#-------------------------------------------------------------------------------
sub getUsedLocales {
  my ($obj) = @_;
  my $currentLocale = $obj->getCurrentLocale();
  my @locales = $obj->SUPER::getUsedLocales();
  my %locales;

 LOCALE:
  foreach my $locale (@locales) {
    $obj->setCurrentLocale($locale);
    foreach my $text ($obj->getTexts()) {
      # getTexts returns all the texts for the given locale, so if at least one text isn't empty, then the object has used that locale
      if ($text) {
        $locales{$locale} = 1;
        next LOCALE;
      }
    }
  }
  $obj->setCurrentLocale($currentLocale);
  return keys %locales;
}
#-------------------------------------------------------------------------------
sub hasDraft {
  my ($obj) = @_;
  return $obj->getDraftId() > 0;
}
#-------------------------------------------------------------------------------
sub getAuthor {
  my ($obj) = @_;
  my $ownerId = $obj->getMetaOwnerId();
  return unless $ownerId;
  return $context->getObjectById($ownerId);
}
#-------------------------------------------------------------------------------
sub getIconUrl {
  my ($obj,$size) = @_;
  $size ||= 16;

  my $isPublishable = $config->get('publisher.allowPublishingPerUrl') eq 'yes' ? $obj->isCurrentUrlPublishable() : $obj->isPublishable();

  return $obj->SUPER::getIconUrl($size) if $isPublishable;
  
  my $iconMgr = $context->getSingleton('O2::Image::IconManager');
  return $iconMgr->getIconUrl('O2CMS::Obj::Article::NotApproved', $size);
}
#-------------------------------------------------------------------------------
sub getWebCategory {
  my ($obj) = @_;
  $obj->{categories} = [ $context->getSingleton('O2::Mgr::MetaTreeManager')->getObjectPath( $obj->getMetaParentId() ) ] unless $obj->{categories};
  my $category = $obj->{categories}->[-1];
  die sprintf "Didn't find web category for article '%s' (%d)", $obj->getMetaName(), $obj->getId() unless $category;
  return $category if $category->isa('O2CMS::Obj::WebCategory');
  die sprintf "Article ('%s' with ID %d) resides in a category ('%s' with ID %d) that's not a web category", $obj->getMetaName(), $obj->getId(), $category->getMetaName(), $category->getId() if $category->isa('O2CMS::Obj::Category');
  die sprintf "Article ('%s' with ID %d) resides in a something ('%s' with ID %d) that's not a category",    $obj->getMetaName(), $obj->getId(), $category->getMetaName(), $category->getId();
}
#-------------------------------------------------------------------------------
sub saveDraft {
  my ($obj, $draft) = @_;
  $obj->getManager()->saveDraft($obj, $draft);
}
#-----------------------------------------------------------------------------
1;
