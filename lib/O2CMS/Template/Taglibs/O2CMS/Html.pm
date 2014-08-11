package O2CMS::Template::Taglibs::O2CMS::Html;

use strict;

use O2 qw($context);

#--------------------------------------------------------------------------------------------
sub register { # Method called by the tag-parser to see what and how methods should be called
  my ($package, %params) = @_;
  
  my $obj = bless { parser => $params{parser} }, $package;
  
  my %methods = (
    cmsLink => 'postfix',
  );
  
  return ($obj, %methods);
}
#--------------------------------------------------------------------------------------------
sub cmsLink {
  my ($obj, %params) = @_;
  my $url;
  if (my $editObject = delete $params{editObject}) {
    my $object = $obj->{parser}->findVar($editObject);
    my $name = $context->getSingleton('O2::Javascript::Data')->escapeForSingleQuotedString( $object->getMetaName() );
    $url = sprintf "javascript: top.openObject('%s', '%d', '%s')", $object->getMetaClassName(), $object->getId(), $name;
  }
  elsif (my $className = delete $params{newObjectClass}) {
    my $urlMod = $context->getSingleton('O2::Util::UrlMod');
    my $queryString = $urlMod->_updateQueryString('', %params);
    $url = "javascript: top.newObject('$className', '$params{parentId}', '$queryString')";
  }
  elsif (my $startMenuItemId = delete $params{startMenuItem}) {
    my $menuItem = $obj->_getStartMenuItemHashById($startMenuItemId) or die "Didn't find start menu item: $startMenuItemId";
    my $iconMgr  = $context->getSingleton('O2::Image::IconManager');
    my $iconSrc  = $menuItem->{iconClass}  ?  $iconMgr->getIconUrl( $menuItem->{iconClass}, 24 )  :  $menuItem->{icon};
    my $name     = $context->getLang()->getString( $menuItem->{name} );
    $name        = $context->getSingleton('O2::Javascript::Data')->escapeForSingleQuotedString($name);
    $url = "javascript: top.openInFrame('$menuItem->{action}', '$iconSrc', '$name')";
  }
  return $obj->{parser}->getTaglibByName('Html')->link(%params, url => $url);
}
#--------------------------------------------------------------------------------------------
sub _getStartMenuItemHashById {
  my ($obj, $id) = @_;
  
  my @configFiles = (
    $context->getCustomerPath() . '/etc/conf/startMenu.conf',
    $context->getCmsPath()      . '/etc/conf/startMenu.conf',
  );
  
  foreach my $file (@configFiles) {
    my $plds = do $file;
    if (ref $plds eq 'ARRAY') {
    ARRAY_ITEM:
      foreach my $hash (@{$plds}) {
        return $hash if $hash->{id} eq $id;
        
        my $subMenuItems = $hash->{subMenus} or next ARRAY_ITEM;
        my $item = $obj->_getStartMenuItemHashByIdAndSubMenuItems($id, $subMenuItems);
        return $item if $item;
      }
    }
    elsif (ref $plds eq 'HASH') {
      return $plds if $plds->{id} eq $id;
      
      my $subMenuItems = $plds->{subMenus} or next;
      my $item = $obj->_getStartMenuItemHashByIdAndSubMenuItems($id, $subMenuItems);
      return $item if $item;
    }
  }
}
#--------------------------------------------------------------------------------------------
sub _getStartMenuItemHashByIdAndSubMenuItems {
  my ($obj, $id, $subMenuItems) = @_;
  foreach my $item (@{$subMenuItems}) {
    return $item if $item->{id} eq $id;
    
    my $subMenuItems = $item->{subMenus};
    $item = $obj->_getStartMenuItemHashByIdAndSubMenuItems($id, $subMenuItems);
    return $item if $item;
  }
  return;
}
#--------------------------------------------------------------------------------------------
1;
