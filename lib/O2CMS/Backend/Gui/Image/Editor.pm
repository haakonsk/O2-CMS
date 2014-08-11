package O2CMS::Backend::Gui::Image::Editor;

use strict;

use base 'O2CMS::Backend::Gui';

use constant DEBUG => 0;

use O2 qw($context $cgi);

#-------------------------------------------------------------------------------
sub init {
  my ($obj, %params) = @_;
  $obj->display('editor.html', %params);
}
#-------------------------------------------------------------------------------
sub edit {
  my ($obj) = @_;
  my $image = $context->getObjectById( $obj->getParam('id') ) or die 'Image not found';
  $obj->display(
    'editor.html',
    image => $image,
  );
}
#-------------------------------------------------------------------------------
sub image {
  my ($obj) = @_;
  my $image = $context->getObjectById( $obj->getParam('id') ) or die 'Image not found';
  $obj->display(
    'image.html',
    image => $image,
  );
}
#-------------------------------------------------------------------------------
sub saveMetaInfo {
  my ($obj) = @_;
  my $image = $context->getObjectById( $obj->getParam('imageId') );
  $image->setMetaName(   $obj->getParam('name')   );
  $image->setExifArtist( $obj->getParam('artist') );
  my ($exifTitleIsSet, $exifDescriptionIsSet);
  foreach my $locale ($image->getAvailableLocales()) {
    $image->setCurrentLocale($locale);
    $image->setTitle(         $obj->getParam("$locale.title")         );
    $image->setDescription(   $obj->getParam("$locale.description")   );
    $image->setAlternateText( $obj->getParam("$locale.alternateText") );
    if (!$exifTitleIsSet) {
      $image->setExifTitle( $obj->getParam("$locale.title") );
      $exifTitleIsSet = 1;
    }
    if (!$exifDescriptionIsSet) {
      $image->setExifDescription( $obj->getParam("$locale.description") );
      $exifDescriptionIsSet = 1;
    }
  }
  $image->save();
  return 1;
}
#-------------------------------------------------------------------------------
sub previewCommands {
  my ($obj) = @_;
  eval {
    my $image = $context->getObjectById( $obj->getParam('id') );
    
    $cgi->setContentType('image/jpeg');
    require O2::Image::Image;
    my $img = O2::Image::Image->newFromFile( $image->getFilePath() );
    my $executeFilter = 1;
    if ( $obj->getParam('reasonableSize') ) {
      $executeFilter = 0  if  $img->getWidth() < 800  &&  $img->getHeight() < 800; # do not resize, if image has "reasonable size"
    }
    $img->filterCommands( $obj->getParam('cmds') ) if $executeFilter;
    
    # XXX NASTY hack. need to figure out stdout from Image::Magick issue

    print $img->asBlob();
  };
  if ($@) {
    $cgi->setContentType('text/plain');
    die "Image could not be processed: $@";
  }
}
#-------------------------------------------------------------------------------
sub saveAs {
  my ($obj) = @_;
  my %params = $obj->getParams();
  my $originalImage = $context->getObjectById( $params{fileId} ) or die 'Image was removed';
  
  require O2::Image::Image;
  my $img = O2::Image::Image->newFromFile( $originalImage->getFilePath() );
  $img->filterCommands( $params{cmds} );
  
  my $saveImage;
  if ($params{fileId} == $params{saveAsId}) { # overwrite image
    $saveImage = $context->getObjectById( $params{saveAsId} ) or die 'Image was removed';
    # return description of objects using image
    if (!$params{ignoreUsedBy}) {
      my $usedByDescription = $obj->_describeUsedBy($saveImage);
      return {
        usedByDescription => $usedByDescription,
      } if $usedByDescription;
    }
  }
  else {
    $saveImage = $context->getSingleton('O2::Mgr::ImageManager')->newObject();
  }
  
  $saveImage->setMetaName(     $params{filename}               );
  $saveImage->setTitle(        $params{filename}               );
  $saveImage->setMetaParentId( $params{parentId}               );
  $saveImage->setFileFormat(   $originalImage->getFileFormat() );
  $saveImage->save();
  $img->write( $saveImage->getCreatedFilePath() );
  debug 'write to ' . $saveImage->getCreatedFilePath();
  
  return {
    parentId => $saveImage->getMetaParentId(),
  };
}
#-------------------------------------------------------------------------------
# returns description of objects using $object, or undef if unused
sub _describeUsedBy {
  my ($obj, $object) = @_;
  my @usedBy = $object->getPublishPlaces() or return;
  
  my $description = '';
  foreach my $usedBy (@usedBy) {
    $description .= '-' . $usedBy->{object}->getMetaName() . "\n";
  }
  return $description;
}
#-------------------------------------------------------------------------------
1;
