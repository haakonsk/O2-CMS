package O2CMS::Obj::Template::Directory; # Represents a template directory on the filesystem

use strict;

use base 'O2::Obj::Container';

use O2 qw($context $config);

#-------------------------------------------------------------------------------
# Return directory name (last part of path)
sub getDirectoryName {
  my ($obj) = @_;
  my ($name) = $obj->getPath() =~ m{ (\w+) \z }xms;
  return $name;
}
#-------------------------------------------------------------------------------
sub getChildIds {
  my ($obj, $skip, $limit, %searchParams) = @_;
  my $fileMgr = $context->getSingleton('O2::File');
  
  # find files in both O2ROOT and O2CUSTOMER
  my %files;
  my @ignorePaths = $config->getArray('template.ignorePaths');
  foreach my $rootDir ( $context->getRootPaths() ) {
    my $fullDir = $rootDir . $obj->getPath();
    if (-e $fullDir) {
      foreach my $file ( $fileMgr->scanDir($fullDir) ) {
        next if grep { $file =~ m/$_/ } @ignorePaths;
        my $isDir = -d "$fullDir/$file";
        next if $file =~ m/^\.\.?$/;
        next if !$isDir && $file !~ m{ [.] (?:x|ht) ml \z }xms;
        $files{ $obj->getPath() . "/$file" } = $isDir;
      }
    }
  }
  
  # select or create objects
  my @files;
  foreach my $file (keys %files) {
    if ( $files{$file} ) {
      my $directory = $obj->getManager()->getObjectByPath($file);
      if (!$directory) {
        # auto create directory with same default templateClass
        $directory = $obj->getManager()->newObject();
        my ($fileName) = $file =~ m|/([^/]+)$|;
        $directory->setMetaName(      $fileName                );
        $directory->setMetaParentId(  $obj->getId()            );
        $directory->setTemplateClass( $obj->getTemplateClass() );
        $directory->setPath(          $file                    );
        $directory->save();
      }
      push @files, $directory;
    }
    else {
      my $template = $context->getSingleton('O2CMS::Mgr::TemplateManager')->getObjectByPath($file);
      if (!$template) {
        $template = $context->getSingleton('O2::Mgr::UniversalManager')->newObjectByClassName( $obj->getTemplateClass() );
        my ($fileName) = $file =~ m|/([^/]+)$|;
        $template->setMetaName(     $fileName     );
        $template->setMetaParentId( $obj->getId() );
        $template->setPath(         $file         );
        $template->save();
      }
      push @files, $template;
    }
  }
  @files = sort { $a->getMetaName() cmp $b->getMetaName() } @files;
  @files = splice @files, $skip, $limit if $limit;
  @files = splice @files, $skip         if $skip && !$limit;
  return map { $_->getId() } @files;
}
#-------------------------------------------------------------------------------
1;
