#!/usr/bin/env perl

# Quick script for adding Image Galleries from a bunch of directories.
# Feel free to change and enhance it

use Encode;
use Encode::Guess;

my ($path, $parentId) = @ARGV;

die "Usage $0 path parentO2Id\n" unless $path && $parentId;

use O2::Context;
my $context = O2::Context->new();
die "Could not create O2::Context. Probably need to use o2Shell to set up environment variables\n" unless $context;

my $parent = $context->getObjectById( $parentId );
unless ($parent && $parent->isContainer()) {
  die "Not a valid parentId\n";
}

my $galleryManager  = $context->getSingleton( 'O2CMS::Mgr::Image::GalleryManager' );
my $imageManager    = $context->getSingleton( 'O2::Mgr::ImageManager'             );
my $categoryManager = $context->getSingleton( 'O2CMS::Mgr::CategoryManager'       );

die "Directory does not exist\n" unless -d $path;

use O2::File;
my $fh = O2::File->new();

foreach my $dir ( $fh->scanDir( $path => '\w+' ) ) {
  if (-d "$path/$dir") {
    createGallery( $dir => "$path/$dir" );
  }
}

sub createGallery {
  my ( $name, $galleryDir ) = @_;

  print "Creating gallery '$name' for directory '$galleryDir'.\n";

  $name = decode('Guess', $name);
  
  my $gallery = $galleryManager->newObject();
  $gallery->setTitle( $name );
  $gallery->setMetaName( $name );
  $gallery->setMetaParentId( $parentId );

  my $category = $categoryManager->newObject();
  $category->setMetaName( $name );
  $category->setMetaParentId( $parentId );
  $category->save();

  my @imageIds = ();
  foreach my $imgFile ($fh->scanDir( $galleryDir => '.jpg|.jpeg|.JPG|.JPEG|.png|.PNG' )) {
    print "  Adding image $imgFile\n";
    my $image = $imageManager->newFromFile( "$galleryDir/$imgFile" );
    $image->setMetaName( $imgFile );
    $image->setMetaParentId( $category->getId() );
    $image->save();
    push @imageIds, $image->getId();
  }
  $gallery->setImageIds( @imageIds );
  $gallery->save();
}
