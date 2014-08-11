package O2CMS::Obj::Directory;

# Links a directory in the operating system filesystem into the O2 tree

use strict;

use base 'O2::Obj::Container';

use O2 qw($context);

#--------------------------------------------------------------------------------------------------
sub isContainer {
  return 1;
}
#--------------------------------------------------------------------------------------------------
sub canRemoveObject {
  my ($obj, $toContainer, $object) = @_;
  return 1;
}
#--------------------------------------------------------------------------------------------------
sub canAddObject {
  my ($obj, $fromContainer, $object) = @_;
  return $object->isa('O2::Obj::File');
}
#--------------------------------------------------------------------------------------------------
sub canMove {
  my ($obj, $fromContainer, $toContainer) = @_;
  return 1;
}
#--------------------------------------------------------------------------------------------------
sub removeObject {
  my ($obj, $toContainer, $object) = @_;
}
#--------------------------------------------------------------------------------------------------
sub addObject {
  my ($obj, $fromContainer, $object) = @_;
}
#--------------------------------------------------------------------------------------------------
sub getChildren {
  my ($obj, $skip, $limit, %searchParams) = @_;
  my $dontWantReferencedObjects = delete $searchParams{dontWantReferencedObjects};
  $searchParams{metaClassName} ||= { in => ['O2CMS::Obj::Directory::File', 'O2CMS::Obj::Directory'] };
  my @objects = $context->getSingleton('O2::Mgr::MetaTreeManager')->getChildren( $obj->getId(), $skip, $limit, %searchParams );
  return @objects if $dontWantReferencedObjects;
  return map { $_->isa('O2CMS::Obj::Directory') ? $_ : $_->getFile() } @objects; # By default (in the o2cms tree) we want to list the files that are referenced, not the O2CMS::Obj::Directory::File objects
}
#--------------------------------------------------------------------------------------------------
sub sync {
  my ($obj, %params) = @_;
  my $debugLevel = $params{debugLevel};
  $obj->setDebugLevel($debugLevel) if $debugLevel;
  my $dirMgr  = $context->getSingleton('O2CMS::Mgr::DirectoryManager');
  my $dirPath = $obj->getPath();
  $obj->_debug("Syncing directory: $dirPath", 2);

  foreach my $filename ($context->getSingleton('O2::File')->scanDir($dirPath)) {
    next if $filename =~ m{ \A [.] }xms || $filename =~ m{ ~ \z }xms;
    my $filePath = "$dirPath/$filename";

    if (-d $filePath) {
      my $dir = $dirMgr->getObjectByPath($filePath) || $obj->_newDirectoryDiscovered($filename);
      $dir->sync( debugLevel => $debugLevel );
      next;
    }

    my $existingDirFile = $obj->getChildByFilename($filename);
    if ($existingDirFile) {
      my $changeEpoch = (stat $filePath)[10];
      if ($changeEpoch > $existingDirFile->getImportEpoch()) {
        $obj->_changedFileDiscovered($existingDirFile);
      }
      else {
        $obj->_debug( sprintf ("$filePath unchanged (objectId %d)", $existingDirFile->getFileId()), 3 );
        $existingDirFile->getFile();
      }
    }
    else {
      $obj->_newFileDiscovered($filename);
    }
  }
}
#--------------------------------------------------------------------------------------------------
sub _newFileDiscovered {
  my ($obj, $filename) = @_;
  my $object = $obj->_newObjectFromFilename($filename);
  return unless $object;
  $obj->_debug( "$filename new. Created " . $object->getMetaClassName() . " objectId " . $object->getId(), 1 );
  # XXX remove if $object ok && newAction=='remove'
  my $dirFile = $context->getSingleton('O2CMS::Mgr::Directory::FileManager')->newObject();
  $dirFile->setMetaParentId( $obj->getId()    );
  $dirFile->setFilename(     $filename        );
  $dirFile->setImportEpoch(  time             );
  $dirFile->setFileId(       $object->getId() );
  $dirFile->save();
}
#--------------------------------------------------------------------------------------------------
sub _newDirectoryDiscovered {
  my ($obj, $dirName) = @_;
  my $dirPath = $obj->getPath() . "/$dirName";
  $obj->_debug("New directory: $dirPath", 1);

  require Encode;
  my $encodedPath;
  $encodedPath = Encode::encode( $obj->getDirectoryEncoding(), $dirPath ) if $obj->getDirectoryEncoding() && $obj->getDirectoryEncoding() ne 'inherited';

  my $newDirectory = $obj->getManager()->newObject();
  $newDirectory->setMetaName(     $dirName                );
  $newDirectory->setMetaParentId( $obj->getId()           );
  $newDirectory->setPath(         $encodedPath            ); # XXX Encoded???
  $newDirectory->setChangeAction( $obj->getChangeAction() ); # Inherit change action
  $newDirectory->save();

  return $newDirectory;
}
#--------------------------------------------------------------------------------------------------
sub _changedFileDiscovered {
  my ($obj, $dirFile) = @_;
  my $filename = $dirFile->getFilename();
  my $filePath = $obj->getPath() . "/$filename";
  $obj->_debug("$filename changed.", 1);
  my $object = $dirFile->getFile();
  return unless $object; # ignore object if it has been deleted
  # handle according to changeAction
  my $changeAction = $obj->getChangeAction();
  return if $changeAction eq 'none';
  if ($changeAction eq 'overwrite') {
    $obj->_debug("Setting new content", 1);
    $object->setContentFromPath($filePath);
    $object->save();
  }
  elsif ($changeAction eq 'createNew') {
    $obj->_debug("Create new object", 1);
    $object = $obj->_newObjectFromFilename($filename);
  }
  $dirFile->setImportEpoch(time);
  $dirFile->save();
}
#--------------------------------------------------------------------------------------------------
sub _newObjectFromFilename {
  my ($obj, $filename) = @_;

  my $filePath = $obj->getPath() . "/$filename";
  require Encode;
  my $encodedPath;
  $encodedPath = Encode::encode( $obj->getDirectoryEncoding(), $filePath ) if $obj->getDirectoryEncoding() && $obj->getDirectoryEncoding() ne 'inherited';

  die "Ups, directory ($filePath)" if -d $filePath;

  my %mapping = (
    jpg  => 'O2::Obj::Image',
    jpeg => 'O2::Obj::Image',
    gif  => 'O2::Obj::Image',
    png  => 'O2::Obj::Image',
    mpg  => 'O2CMS::Obj::Video',
  );
  my ($extension) = $filename =~ m|\.(\w+)$|;
  return unless $extension; # Ignoring files without extension (directories are handled elsewhere)

  my $className = $mapping{ lc $extension } || 'O2::Obj::File'; # default to plain file

  my $object = $context->getUniversalMgr()->newObjectByClassName($className);
  $object->setMetaName(        $filename     );
  $object->setMetaParentId(    $obj->getId() );
  $object->setContentFromPath( $encodedPath  ); # XXX Encoded???
  $object->save();
  return $object;
}
#--------------------------------------------------------------------------------------------------
sub getChildByFilename {
  my ($obj, $filename) = @_;
  my @files = $context->getSingleton('O2CMS::Mgr::Directory::FileManager')->objectSearch(
    metaParentId => $obj->getId(),
    filename     => $filename,
  );
  die sprintf "More than one file with the same name ($filename) in dir %s (%d)", $obj->getMetaName(), $obj->getId() if @files > 1;
  return @files ? $files[0] : undef;
}
#--------------------------------------------------------------------------------------------------
sub getDirectoryEncoding {
  my ($obj) = @_;
  return $obj->{directoryEncoding} if $obj->{directoryEncoding};
  $obj->{directoryEncoding} = $obj->getPropertyValue($obj, 'directoryEncoding') || 'utf8'; # Need a default encoding
  return $obj->{directoryEncoding};
}
#--------------------------------------------------------------------------------------------------
sub setDebugLevel {
  my ($obj, $debugLevel) = @_;
  $obj->{_debugLevel} = $debugLevel || 0;
}
#--------------------------------------------------------------------------------------------------
sub _debug {
  my ($obj, $msg, $debugLevel) = @_;
  $debugLevel ||= 1;
  return if $debugLevel > $obj->{_debugLevel};
  print "$msg\n";
}
#--------------------------------------------------------------------------------------------------
1;
