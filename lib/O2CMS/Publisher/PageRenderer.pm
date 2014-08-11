package O2CMS::Publisher::PageRenderer;

use strict;

use O2 qw($context $cgi $config $session);

#--------------------------------------------------------------------------------------------
sub new {
  my ($pkg, %init) = @_;
  die "Missing page"  unless $init{page};
  die "Missing media" unless $init{media};
  
  my $obj = bless {
    page          => $init{page},
    mediaName     => $init{media},
    fullId        => [], # Keeps track of where in the slotId hierarchy we are currently
    currentSlot   => undef,
    currentObject => undef,
  }, $pkg;
  
  my $user   = $context->getUser();
  my $parser = $context->getSingleton('O2::Template::TagParser');
  $parser->setProperty( 'pageRenderer', $obj        );
  $parser->setProperty( 'page',         $init{page} );
  $parser->setVar( 'context', $context               );
  $parser->setVar( 'config',  $config                );
  $parser->setVar( 'page',    $init{page}            );
  $parser->setVar( 'lang',    $context->getLang()    );
  $parser->setVar( 'user',    $user                  ) if $user && !$user->isa('O2CMS::Obj::AdminUser');
  $parser->setVar( 'session', $session               );
  $parser->setVar( 'cgi',     $cgi                   );
  $parser->setVar( 'ENV',     { $context->getEnv() } );
  $obj->{parser} = $parser;
  
  my $module = "O2CMS::Publisher::Media::$init{media}";
  eval "require $module;";
  die "Could not require $module: $@" if $@;
  
  $obj->{media} = $module->new(
    page   => $obj->{page},
    parser => $obj->{parser},
  );
  return $obj;
}
#--------------------------------------------------------------------------------------------
sub getMedia {
  my ($obj) = @_;
  return $obj->{media};
}
#--------------------------------------------------------------------------------------------
sub getMediaName {
  my ($obj) = @_;
  return $obj->{mediaName};
}
#--------------------------------------------------------------------------------------------
# set extra variable available in template
sub setTemplateVariable {
  my ($obj, $name, $value) = @_;
  $obj->{parser}->setVar($name, $value);
}
#--------------------------------------------------------------------------------------------
# returns html for a slot including header control panel
sub renderSlot {
  my ($obj, %params) = @_;
  return "missing id attribute in slot tag" unless $params{id};
  push @{ $obj->{fullId} }, $params{id};
  my $slotId = join '.', @{ $obj->{fullId} };

  $obj->_prepareSlot( %params, slotId => $slotId );
  my $result = $obj->{media}->renderSlot( %params, slotId => $slotId );
  pop @{ $obj->{fullId} };
  return $result;
}
#--------------------------------------------------------------------------------------------
# returns content html for a slot (without header control panel)
# this method is mainly for reloading a slot in the editor
sub renderSlotContent {
  my ($obj, %params) = @_;
  $obj->{fullId} = [ split /\./, $params{slotId} ]; # we receive slotId as a full slot-path, so we need to update 
  $obj->{parser}->parseVars( \$params{slotId} );
  $obj->_prepareSlot( %params, slotId => $params{slotId} );
  return $obj->{media}->renderSlotContent(
    %params,
    slotId    => $params{slotId},
    extraHtml => '<o2 use Html />',
  );
}
#--------------------------------------------------------------------------------------------
# called before a slot is used
sub _prepareSlot {
  my ($obj, %params) = @_;
  
  # inheritIfEmpty attribute in <o2 slot> tag?
  if ($params{inheritIfEmpty} && lc $params{inheritIfEmpty} eq 'yes') {
    # does slot already have content?
    my $slot = $obj->{page}->getSlotById( $params{slotId} );
    return if $slot && $slot->getContentId() > 0;

    # look up ids for all parent categories of page (and keep it for subsequent calls)
    if (!$obj->{parentIds}) {
      my $metaTreeManager = $context->getSingleton('O2::Mgr::MetaTreeManager');
      my @parentIds = $metaTreeManager->getIdPathTo( $obj->{page}->getMetaParentId() );
      push  @parentIds, $obj->{page}->getMetaParentId();
      shift @parentIds; # there is no frontpage below Installation object, so remove it
      $obj->{parentIds} = \@parentIds;
    }

    # look for frontpages with matching slot, and use slot-content for this slot (caching frontpages in $obj->{frontpages})
    my $frontpageMgr = $context->getSingleton('O2CMS::Mgr::FrontpageManager');
    foreach my $parentId (reverse @{ $obj->{parentIds} }) {
      if ( !exists $obj->{frontpages}->{$parentId} ) {
        $obj->{frontpages}->{$parentId} = $frontpageMgr->getFrontpageByCategoryId($parentId);
      }
      next unless $obj->{frontpages}->{$parentId}; # frontpage must have been removed for some reason
      my $slot = $obj->{frontpages}->{$parentId}->getSlotById( $params{slotId} );
      if ($slot && $slot->getContentId() > 0) {
        $slot->setOverride('_isInherited', 1);
        $obj->{page}->getSlotList()->setExternalSlot($slot);
        return;
      }
    }
  }
}
#--------------------------------------------------------------------------------------------
sub renderSlotChildren {
  my ($obj, %params) = @_;

  my $currentSlot = $obj->{media}->{currentSlot};
  return "Slot object for slotId '$params{slotId}' not found" if !$currentSlot || !$currentSlot->getContentId(); # this should not happen
  $currentSlot->setOverrideByName('_isListSlot', 1); # mark slot - XXX make sure this is unset at appropriate place?

  my $object = $obj->{media}->{currentObject};
  return "Content object not found for slotId '$params{slotId}'" unless $object; # this should not happen
  my @children = $object->can('getChildren') && lc($params{virtual}) ne 'yes' ? $object->getChildren() : (); # XXX special case for variable.html...

  # max number of items in this list
  my $maxItems = $currentSlot->getOverrideByName('_maxItems'); # is it defined in overrides?
  $maxItems = $params{maxItems} unless defined $maxItems;      # default to maxItems attribute
  $currentSlot->setOverrideByName('_maxItems', $maxItems);

  my $html = '';
  my $slotList = $obj->{media}->{page}->getSlotList();
  for (my $slotIndex = 0; $slotIndex < $maxItems; $slotIndex++) {
    # should number of children or maxItems determine number of slots?
    last if lc($params{alwaysMaxItems}) ne 'yes' && $slotIndex > $#children;
    my $child = $children[$slotIndex];

    # fill out slots for child objects. _isLocked means item should not be replaced
    my $childSlotId = $currentSlot->getSlotId() . ".slot$slotIndex";
    require O2CMS::Obj::Template::Slot;
    my $childSlot = $slotList->getLocalSlotById($childSlotId) || O2CMS::Obj::Template::Slot->new();
    if (!$childSlot->getOverrideByName('_isLocked')) {
      $childSlot->setSlotId(    $childSlotId    );
      $childSlot->setContentId( $child->getId() ) if $child;
      # template will be determed by renderSlotContent() when <o2 slot> tag is executed
    }
    $childSlot->setOverrideByName('_isListItemSlot', 1);
    $slotList->setLocalSlot($childSlot);

    $obj->{media}->{parser}->setVar('$slotIndex', $slotIndex);
    my $tmpl =  $params{content};
    $html .= ${ $obj->{media}->{parser}->_parse(\$tmpl) };
  }
  return $html;
}
#--------------------------------------------------------------------------------------------
sub renderPage {
  my ($obj) = @_;
  return $obj->{media}->renderPage();
}
#--------------------------------------------------------------------------------------------
sub renderObjectImage {
  my ($obj, %params) = @_;
  $params{slotId} = join '.', @{ $obj->{fullId} };
  return $obj->{media}->renderObjectImage(%params);
}
#--------------------------------------------------------------------------------------------
sub renderObjectString {
  my ($obj, %params) = @_;
  $params{slotId} = join '.', @{ $obj->{fullId} };
  return $obj->{media}->renderObjectString(%params);
}
#--------------------------------------------------------------------------------------------
1;
