package O2CMS::Setup::CMS::ClassesAndDefaults;

use strict;

use base 'O2::Setup::ClassesAndDefaults';

use O2 qw($context $db);
use Term::ANSIColor;

#---------------------------------------------------------------------
sub install {
  my ($obj) = @_;

  $obj->createDefaultCategories();
  $obj->registerClasses();
  $obj->createAdminUser();
  $obj->registerTemplates();
  $obj->createSite();
  
  return 1;
}
#---------------------------------------------------------------------
sub registerTemplates {
  my ($obj) = @_;

  my $setupConf = $obj->getSetupConf();
  die 'Seems like there was a problem creating the "/Templates" object.' unless $setupConf->{objectIds}->{templatesId};

  my $templates = $context->getObjectById( $setupConf->{objectIds}->{templatesId} );
  my %classMapping = (
    pages    => 'Page',
    grids    => 'Grid',
    objects  => 'Object',
    includes => 'Include'
  );

  foreach my $directory ($templates->getChildren()) {
    my $className = $classMapping{ $directory->getDirectoryName() };
    if ($className) {
      $className = "O2CMS::Obj::Template::$className";
      $directory->setTemplateClass($className);
      $directory->save();
      print "Using $className for " . $directory->getPath() . "\n" if $obj->debug();
      # register template files (in order to register /Templates/Pages/frontpage.html - needed below)
      $directory->getChildren();
    }
    else {
      print "Do not know what class to use on " . $directory->getPath() . ".\n" if $obj->debug();
    }
  }
  
  # set default frontpage template property (needed when we create a new site+frontpage)
  my $installation = $context->getObjectById( $setupConf->{objectIds}->{installationId} );
  my $propertyName = 'pageTemplateId.O2CMS::Obj::Frontpage';
  my $templateId   = $installation->getPropertyValue($propertyName);
  
  if (!$templateId) {
    my $pageMgr      = $context->getSingleton('O2CMS::Mgr::Template::PageManager');
    my $pageTemplate = $pageMgr->getObjectByPath('/var/templates/frontend/pages/frontpage.html');
    print "  Point $propertyName property to " . $pageTemplate->getPath() . ' (' . $pageTemplate->getId() . ")\n" if $obj->debug();
    $installation->setPropertyValue( $propertyName, $pageTemplate->getId() );
    $installation->save();
  }

  my $metaTreeMgr = $context->getSingleton('O2::Mgr::MetaTreeManager');
  
  # Hack to make sure all needed template objects exist:
  $metaTreeMgr->getObjectByPath( '/Templates/objects/category'   )->getChildren();
  $metaTreeMgr->getObjectByPath( '/Templates/objects/site'       )->getChildren();
  $metaTreeMgr->getObjectByPath( '/Templates/objects/statistics' )->getChildren();
  $metaTreeMgr->getObjectByPath( '/Templates/objects/survey'     )->getChildren();
  $metaTreeMgr->getObjectByPath( '/Templates/objects/video'      )->getChildren();
  $metaTreeMgr->getObjectByPath( '/Templates/objects/common'     )->getChildren();
  
  my %usableClasses = (
    article                           => ['O2CMS::Obj::Article'],
    'category/basicAlbum.html'        => ['O2CMS::Obj::Category', 'O2CMS::Obj::WebCategory'],
    file                              => ['O2::Obj::File'],
    flash                             => ['O2CMS::Obj::Flash'],
    image                             => ['O2::Obj::Image'],
    menu                              => ['O2CMS::Obj::Menu'],
    query                             => ['O2::Obj::Object::Query'],
    'site/sitemap.html'               => ['O2CMS::Obj::Site::Sitemap'],
    'statistics/googleAnalytics.html' => ['O2CMS::Obj::Statistics::GoogleAnalytics'],
    'survey/poll.html'                => ['O2CMS::Obj::Survey::Poll'],
    'video/video.html'                => ['O2CMS::Obj::MultiMedia::Video'],
    'common/linkOnly.html'            => ['O2::Obj::Object'],
  );
  foreach my $path (keys %usableClasses) {
    print "  Registering objects for template(s): $path\n" if $obj->debug();
    my $dirOrFile = $metaTreeMgr->getObjectByPath("/Templates/objects/$path");
    if (!$dirOrFile) {
      warn "  ERROR! Path '/Templates/objects/$path' doesn't seem to exist";
      next;
    }
    $obj->_registerTemplatesToClasses( $dirOrFile, $usableClasses{$path} );
  }
}
#---------------------------------------------------------------------
sub _registerTemplatesToClasses {
  my ($obj, $dirOrFile, $classes) = @_;
  if ($dirOrFile->can('getChildren')) {
    my @children = $dirOrFile->getChildren();
    foreach my $child (@children) {
      if ($child->can('getChildren')) {
        $obj->_registerTemplatesToClasses($child, $classes);
      }
      else {
        $child->setUsableClasses( @{$classes} );
        $child->save();
      }
    }
  }
  else {
    $dirOrFile->setUsableClasses( @{$classes} );
    $dirOrFile->save();
  }
}
#---------------------------------------------------------------------
sub createAdminUser {
  my ($obj) = @_;
  my $setupConf = $obj->getSetupConf();
  
  my $adminPassword = $setupConf->{o2cmsPassword} || $setupConf->{systemModelPassword} || $context->{__adminPassword} || $context->getSingleton('O2::Util::Password')->generatePassword();
  $context->{__adminPassword} = $adminPassword;
  
  print '  Creating adminuser (admin / ' . (colored ['red on_white'], $adminPassword) . ")\n";
  
  my $userMgr = $context->getSingleton('O2CMS::Mgr::AdminUserManager');
  my $user = $userMgr->getUserByUsername('admin') || $userMgr->newObject();
  
  $user->setMetaName(   'Administrator'        );
  $user->setMetaStatus( 'active'               );
  $user->setUsername(   'admin'                );
  $user->setFirstName(  'System Administrator' );
  $user->setLastName(   'System Administrator' );
  $user->setPassword(   $adminPassword         ) unless $user->getId();
  $user->save();
}
#---------------------------------------------------------------------
sub createDefaultCategories {
  my ($obj) = @_;

  print "  Creating default objects\n" if $obj->verbose();
  
  my $setupConf = $obj->getSetupConf();

  $setupConf->{objectIds}->{trashcanId}
    = $obj->createCategory(
      className        => 'O2CMS::Obj::Trashcan', 
      managerClassName => 'O2CMS::Mgr::TrashcanManager',
      set              => { metaName => 'Trash', },
    );
  
  $setupConf->{objectIds}->{classesId}
    = $obj->createCategory(
      className        => 'O2CMS::Obj::Category::Classes', 
      managerClassName => 'O2CMS::Mgr::Category::ClassesManager',
      set              => { metaName => 'Classes', },
    );
  
  $setupConf->{objectIds}->{installationId}
    = $obj->createCategory(
      className        => 'O2CMS::Obj::Installation', 
      managerClassName => 'O2CMS::Mgr::InstallationManager',
      set              => {
        metaName    => 'Installation',
        version     => '2.0.1',
        versionName => 'Bootstrapped Core',
      },
    );
  
  $setupConf->{objectIds}->{templatesId}
    = $obj->createCategory(
      className        => 'O2CMS::Obj::Category::Templates', 
      managerClassName => 'O2CMS::Mgr::Category::TemplatesManager',
      set              => {
        metaName      => 'Templates',
        path          => '/var/templates/frontend',
        templateClass => 'O2CMS::Obj::Template::Object',
      },
    );
  
  $setupConf->{objectIds}->{keywordsId}
    = $obj->createCategory(
      parentId         => $setupConf->{objectIds}->{installationId},
      className        => 'O2CMS::Obj::Category::Keywords', 
      managerClassName => 'O2CMS::Mgr::Category::KeywordsManager',
      set              => { metaName => 'Keywords' },
    );
  
  return;
}
#---------------------------------------------------------------------
sub createSite {
  my ($obj) = @_;
  my $setupConf = $obj->getSetupConf();

  print "  Creating site-object\n" if $obj->verbose();
  
  $setupConf->{objectIds}->{siteId} =
    $obj->createCategory(
      parentId         => $setupConf->{objectIds}->{installationId},
      className        => 'O2CMS::Obj::Site', 
      managerClassName => 'O2CMS::Mgr::SiteManager',
      set              => {
        metaName      => $setupConf->{hostname},
        hostname      => $setupConf->{hostname},
        directoryName => join ( '/', $setupConf->{customersRoot}, $setupConf->{customer}, $setupConf->{hostname} ),
        portNumber    => 80,
      },
    );
  return;
}
#---------------------------------------------------------------------
sub createCategory {
  my ($obj, %params) = @_;
  
  eval "require $params{managerClassName}";
  die "Could not load manager-class '$params{managerClassName}': $@\n" if $@;
  
  my $setupConf = $obj->getSetupConf();
  my $manager = $params{managerClassName}->new();
  
  my $object;
  my $objectId = $db->fetch( "select objectId from O2_OBJ_OBJECT where className = ?", $params{className} );
  
  if ($objectId) {
    $object = $manager->getTrashedObjectById($objectId);
    print "  Resurrecting category '$params{set}->{metaName}' in database\n" if $obj->debug();
  }
  else {
    $object = $manager->newObject();
    print "  Creating category '$params{set}->{metaName}' in database\n" if $obj->debug();
  }
  
  foreach my $accessorName (keys %{ $params{set} }) {
    my $method = 'set' . ucfirst $accessorName;
    $object->$method( $params{set}->{$accessorName} );
  }
  $object->setMetaParentId( $params{parentId} ) if $params{parentId};
  
  $object->save();
  
  die "Could not create $params{className} $params{metaName}" unless $object->getId() > 0;
  return $object->getId();
}
#---------------------------------------------------------------------
sub _getClassEntries {
  my ($obj, $setupConf) = @_;
  my $filePath = "$setupConf->{o2CmsRoot}/src/classDefinitions/O2-Obj-Class-entries.plds";
  my $classEntries = eval $setupConf->getSingleton('O2::File')->getFile($filePath);
  die "Couldn't find class entries file: $@" if $@;
  return @{$classEntries};
}
#---------------------------------------------------------------------
1;
