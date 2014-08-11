package O2CMS::Backend::Gui::Category::PublisherSettings;

use strict;

use base 'O2CMS::Backend::Gui';

use O2 qw($context);

#---------------------------------------------------------------------------------------
sub edit {
  my ($obj) = @_;
  
  my $categoryId = $obj->getParam('categoryId');
  return $obj->error("Missing categoryId parameter") unless $categoryId > 0;
  my $category = $context->getObjectById($categoryId);
  
  # All page templates
  my @pageTemplates = $context->getSingleton('O2CMS::Mgr::Template::PageManager')->getPageTemplates();
  
  my $objectTemplateMgr = $context->getSingleton('O2CMS::Mgr::Template::ObjectManager');
  my $propertyMgr       = $context->getSingleton('O2::Mgr::PropertyManager');
  
  my $classMgr = $context->getSingleton('O2::Mgr::ClassManager');
  my @pageSubClasses = $classMgr->getSubClasses('O2CMS::Obj::Page');
  my @pageClassNames = map { $_->getClassName() } @pageSubClasses;
  push @pageClassNames, 'O2CMS::Obj::Page';
  
  my @classes;
  foreach my $className ($classMgr->getClassNames()) {
    my @objectTemplates = $objectTemplateMgr->queryTemplates( class => $className );
    # Figure out property values for default object and page templates, and where it came from
    my $isPage = grep  { $className eq $_ }  @pageClassNames;
    if (@objectTemplates || $isPage) { # Ignore classes without object templates (since they cannot be displayed). Always include pages
      my $name = $obj->getLang()->getString("o2.className.$className");
      $name = $className if $name =~ m/</; # Use class name if no translation was found
      my %class = (
        className => $className,
        name      => $name,
        isPage    => $isPage ? 1 : 0,
      );
      foreach my $key (qw(objectTemplateId pageTemplateId)) {
        $class{$key}->{options} = $key eq 'objectTemplateId' ? \@objectTemplates : \@pageTemplates;
        my $propertyName = "$key.$className";
        my $property = $propertyMgr->getProperty($categoryId, $propertyName);
        if ($property) {
          $class{$key}->{value}          = $property->getValue();
          $class{$key}->{isInherited}    = $property->isInherited() ? 1 : 0;
          $class{$key}->{inheritedValue} = $propertyMgr->getPropertyValue( $category->getMetaParentId(), $propertyName );
          $obj->_debug( "Found $propertyName. Value: $class{$key}->{value}, set on objectId: " . $property->getOriginatorId() );
        }
        else {
          $class{$key}->{isInherited} = 1;
        }
      }
      push @classes, \%class;
    }
  }
  
  my @categoryPath = $context->getSingleton('O2::Mgr::MetaTreeManager')->getObjectPath($category);
#  shift @categoryPath; # remove installation
  $obj->display(
    'edit.html',
    category     => $category,
    categoryPath => \@categoryPath,
    classes      => \@classes,
  );
}
#---------------------------------------------------------------------------------------
sub save {
  my ($obj) = @_;
  
  my %q = $obj->getParams();
  require Data::Dumper;
  $obj->_debug('<pre>' . Data::Dumper::Dumper(\%q) . '</pre>');
  my $categoryId = $obj->getParam('categoryId');
  return $obj->error("Missing categoryId parameter") unless $categoryId > 0;
  my $category = $context->getObjectById($categoryId);
  
  my $propertyMgr = $context->getSingleton('O2::Mgr::PropertyManager');
  
  foreach my $className ( $obj->getParam('classNames') ) {
    foreach my $prefix (qw(objectTemplateId pageTemplateId)) {
      my $propertyName  = "$prefix.$className";
      my $previousValue = $propertyMgr->getPropertyValue($categoryId, $propertyName);
      my $isInherited   = $obj->getParam("$propertyName.isInherited") eq 'on';
      my $templateId    = $obj->getParam($propertyName);
      if ($isInherited && $previousValue) {
        $obj->_debug("Delete property $propertyName from category $categoryId");
        $propertyMgr->deletePropertyValue($categoryId, $propertyName);
      }
      else {
        $obj->_debug("Setting $propertyName to $templateId on category $categoryId");
        $propertyMgr->setPropertyValue($categoryId, $propertyName, $templateId) if $previousValue ne $templateId;
      }
    }
  }
  $obj->edit();
}
#---------------------------------------------------------------------------------------
sub _debug {
  my ($obj, $msg) = @_;
#  print "<font color=blue>$msg</font><br>";
}
#---------------------------------------------------------------------------------------
1;
