package O2CMS::Backend::Gui::File::Upload;

use strict;

use base 'O2CMS::Backend::Gui';

use O2 qw($context $cgi);

#-------------------------------------------------------------------------------
sub popup {
  my ($obj) = @_;
  my $folderId      = $cgi->getParam('folderId');
  my $numberOfFiles = $cgi->getParam('numberOfFiles') || 1;
  $obj->display(
    'popup.html',
    folderId      => $folderId,
    numberOfFiles => $numberOfFiles,
  );
}
#-------------------------------------------------------------------------------
sub previewImage {
  my ($obj) = @_;
  my $file = $cgi->getParam('file');
  print "<img src=$file>";
}
#-------------------------------------------------------------------------------
# This is the new one
sub fileUpload {
  my ($obj) = @_;

  my $uploadedFile = $cgi->getParam("file");
  die "No file uploaded (It needs to be called file)" unless $uploadedFile;

  my $object = $uploadedFile->storeFileAndGetO2Object();
  $object->setMetaOwnerId( $context->getUserId() );
  
  my $objectId = $object->getId();
  eval {
    $object->save();
  };
  if ($@) {
    $object->deletePermanently() unless $objectId;
    die "Error saving uploaded file: $@";
  }
  
  print "ALL OK";

  return 1;
}
#-------------------------------------------------------------------------------
# This is the old one. Remove as soon as every upload is done by fileUpload
sub upload {
  my ($obj) = @_;

  require O2::Util::String;
  my $string = O2::Util::String->new();

  foreach my $param ($cgi->getParams()) {
    next if $param !~ m{ \A file (\d+) \z }xms;
    my $fileNum = $1;
    my $uploadFile = $cgi->getParam("file$fileNum");
    next unless $uploadFile;
    # XXX handle unknown format
    # XXX init video specifics

    my $object = $uploadFile->storeFileAndGetO2Object();

    $object->setMetaParentId( $cgi->getParam('folderId')     );
    $object->setMetaName(     $cgi->getParam("name$fileNum") );
    foreach my $locale ($object->getAvailableLocales()) {
      $object->setCurrentLocale( $locale                        );
      $object->setTitle(         $cgi->getParam("name$fileNum") );
      $object->setDescription(   ''                             );
    }
    
    my $objectId = $object->getId();
    eval {
      $uploadFile->setImageProperties($object) if $object->isa('O2::Obj::Image');
      $object->save();
    };
    my $errorMsg = $@;
    if ($errorMsg) {
      my $stackTrace = $O2::Cgi::CGI->{_stackTrace};
      $object->deletePermanently() unless $objectId;
      return $context->getConsole()->error( "Error saving uploaded file: $errorMsg", stackTrace => $stackTrace );
    }
    
    my $executeJs = $obj->getParam('executeJs');
    if ($executeJs) {
      my %subst = (
        id        => $object->getId(),
        parentId  => $object->getMetaParentId(),
        name      => $object->getMetaName(),
        className => $object->getMetaClassName(),
      );
      print '<script>' . $string->substitute($executeJs, %subst) . '</script>';
    }
  }
  return;
}
#-------------------------------------------------------------------------------
# returns a new O2 object based on content type
sub mimeType2object {
  my ($obj, $mimeType) = @_;
  my $manager;
  if ( $mimeType =~ /^image\// ) {
    $manager = $context->getSingleton('O2::Mgr::ImageManager');
  }
  elsif ( $mimeType =~ /^video\// ) {
    $manager = $context->getSingleton('O2CMS::Mgr::VideoManager');
  }
  elsif ( $mimeType =~ m|^application\/x-shockwave-flash$| ) {
    $manager = $context->getSingleton('O2CMS::Mgr::FlashManager');
  }
  else {
    $manager = $context->getSingleton('O2::Mgr::FileManager');
  }
  return $manager->newObject();
}
#-------------------------------------------------------------------------------
1;
