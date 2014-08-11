package O2CMS::Backend::Gui::Revision::Manager;

use strict;

use base 'O2CMS::Backend::Gui';

use O2 qw($context);

#------------------------------------------------------------
sub init {
  my ($obj) = @_;
  
  my $objectId = $obj->getParam('objectId');
  $obj->display(
    'init.html',
    srcObject         => $objectId ? $context->getObjectById($objectId) : undef,
    srcObjectId       => $objectId,
    totalNumRevisions => $obj->getNumRevisions($objectId),
    gui               => $obj,
  );
}
#------------------------------------------------------------
sub getNumRevisions {
  my ($obj, $objectId) = @_;
  $obj->getRevisions($objectId, 0, 1);
  return $context->getSingleton('O2::Mgr::RevisionedObjectManager')->getTotalNumSearchResults();
}
#------------------------------------------------------------
sub getRevisions {
  my ($obj, $objectId, $skip, $limit) = @_;
  return unless $objectId;
  return $context->getSingleton('O2::Mgr::RevisionedObjectManager')->getRevisionsByObjectId($objectId, $skip, $limit);
}
#------------------------------------------------------------
sub restore2Revision {
  my ($obj) = @_;
  my $object = $context->getObjectById( $obj->getParam('objectId') );
  my $revisionId = $obj->getParam('revisionId');

  $context->getSingleton('O2::Mgr::RevisionedObjectManager')->restoreRevisionById($revisionId);
  eval {
    $obj->openRevision($revisionId);
  };
  if ($@) {
    print "Sorry, incompatible revision (probably too old).<br>\n";
    die $@;
  }
}
#------------------------------------------------------------
sub openDraft {
  my ($obj) = @_;
  $obj->openRevision();
}
#------------------------------------------------------------
sub openRevision {
  my ($obj, $revisionId) = @_;
  $revisionId ||= $obj->getParam('objectId');
  die "Missing revision id" unless $revisionId;
  my $revision = $context->getObjectById($revisionId);
  my $object = $revision->getUnserializedObject();

  my $class = $context->getSingleton('O2::Mgr::ClassManager')->getObjectByClassName( $object->getMetaClassName() );
  my $editUrl = $class->getEditUrl();
  my $module  = $editUrl;
  $module     =~ s{ / [^/]+ \z }{}xms;
  $module     =~ s{ \A /o2cms/ }{O2CMS::Backend::Gui::}xms;
  $module     =~ s{ [/-] }{::}xmsg;
  $module     =~ s{ [?] .* \z }{}xms;
  $module     =~ s{ :: \z }{}xms;

  eval "require $module";
  my $guiModule;
  eval { $guiModule = $module->new(); };
  $guiModule->openRevision($object, $revisionId);
}
#------------------------------------------------------------
sub revisionDiff {
  my ($obj) = @_;
  my $objectId   = $obj->getParam('objectId')   or die 'Missing objectId parameter';
  my $revisionId = $obj->getParam('revisionId') or die 'Missing revisionId parameter';
  my $srcObject  = $context->getObjectById($objectId)   or die 'No object';
  my $revision   = $context->getObjectById($revisionId) or die 'No revision object';
  $obj->display(
    'revisionDiff.html',
    revision  => $revision,
    keys      => ['data.serializedObject'],
    srcObject => $srcObject,
    guiModule => $obj,
  );
}
#------------------------------------------------------------
sub getValue {
  my ($obj, $object) = @_;
  return $object->{data}->{serializedObject} if $object->isa('O2::Obj::RevisionedObject');
  return $object->serialize();
}
#------------------------------------------------------------
sub getValueAsDiff {
  my ($obj, $revision, $prevRevision) = @_;
  my $value = $obj->getValue($revision);
  return $value unless $prevRevision;
  my $prevValue = $obj->getValue($prevRevision);
  return $value if $value eq $prevValue;
  my $fileMgr      = $context->getSingleton('O2::File');
  my $userId       = $context->getUserId();
  my $customerRoot = $context->getEnv('O2CUSTOMERROOT');
  my $file1 = "$customerRoot/var/diffValue1-$userId.txt";
  my $file2 = "$customerRoot/var/diffValue2-$userId.txt";
  $fileMgr->writeFile( $file1, $value     );
  $fileMgr->writeFile( $file2, $prevValue );
  my $diff = `diff --side-by-side --left-column --width 180 $file1 $file2`;
  return $diff;
}
#------------------------------------------------------------
1;
