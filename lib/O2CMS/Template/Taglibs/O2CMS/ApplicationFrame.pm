package O2CMS::Template::Taglibs::O2CMS::ApplicationFrame;

# Define a standard header for O2 Applications

use strict;

use base 'O2::Template::Taglibs::Html';

use O2 qw($context);

#--------------------------------------------------------------------------------------------
sub register { # Method called by the tag-parser to see what and how methods should be called
  my ($package, %params) = @_;
  my %methods = (
    ApplicationFrameHeader => 'postfix',
    ApplicationFrameFooter => 'postfix',
    ApplicationStatusBar   => '',
  );
  my $obj = bless { parser => $params{parser} }, $package;
  $obj->{parser}->getTaglibByName('Html'); # Make sure Html is loaded
  return ($obj, %methods);
}
#--------------------------------------------------------------------------------------------
sub ApplicationFrameHeader {
  my ($obj, %params) = @_;

  # Find the path to where we are in the application (tree)
  my ($path, @path);
  my $parser = $obj->{parser};
  my $objectId = $parser->findVar( $params{objectId} );
  if ($objectId) {
    @path = $context->getSingleton('O2::Mgr::MetaTreeManager')->getObjectPath($objectId);
    shift @path if @path > 1 && $path[0]->isa('O2CMS::Obj::Installation'); # Remove installation-object
  }
  my $extraPath = $params{extraPath} || $params{path} || '';
  $extraPath    = $parser->findVar($extraPath) if $extraPath =~ m{ \A \$ }xms;
  if (@path || $extraPath) {
    $path = join ' / ',  map { $_->getMetaName() } @path;
    my @extraPath = $extraPath  ?  split /,\s*/, $extraPath  :  ();
    $path .= ' / '                  if @path && @extraPath;
    $path .= join ' / ', @extraPath if @extraPath;
  }

  $obj->addJsFile( file => 'ajax'      );
  $obj->addJsFile( file => 'htmlToDom' );
  $obj->addJsFile( file => 'o2escape'  );

  $obj->addJs(
    where   => 'pre',
    content => "
function setApplicationFrameHeaderExtraPath(text) {
  document.getElementById('applicationFrameHeaderExtraPath').innerHTML = ' / ' +  text;
}
function setApplicationFrameHeaderCurrentPath(categoryId) {
  o2.ajax.call({
    setDispatcherPath : 'o2cms',
    setClass          : 'Category-Manager',
    setMethod         : 'displayCurrentPath',
    setParams         : 'categoryId=' + categoryId,
    target            : 'applicationFrameHeaderCurrentPath',
    where             : 'replace'
  });
}",
  );

  my $bodyScroll = '';
  my $frameBody  = '';

  if ($params{useCloseAction} eq 'confirmClose') {               # Just an alias to...
    $params{useCloseAction} = '_confirmCloseApplicationFrame()'; # ...this one
  }
  elsif ($params{useCloseAction} eq 'confirmCloseIfChanged') {
    $params{useCloseAction} = '_confirmCloseApplicationFrameIfChanged()';
  }

  if ($params{url}) { # iframe mode
    $frameBody = qq{<iframe id=bodyIFrame style="border:0px;" height="100%" width="100%" src="$params{url}"></iframe>};
  }
  else {
    $bodyScroll = "overflow:auto;" if !$params{disableScrollBar} && !$params{disableScrollbar};
  }
  $obj->addCssFile(    file => 'O2ApplicationFrame' );
  $obj->addJsFromFile( file => 'applicationFrame'   );
  
  $params{content} .= $obj->getSettingsMenu() if $params{showSettingsButton};
  
  $obj->{parser}->pushMethods('addCell' => $obj, 'addCellSeparator' => $obj,'addHeaderButton' => $obj);
  $obj->{parser}->_parse( \$params{content} );
  $obj->{parser}->popMethod('addCell' => $obj, 'addCellSeparator' => $obj, 'addHeaderButton' => $obj);
  
  my $closeTag;
  $closeTag = '<a href="#" class="closeButton" onclick="' . ($params{useCloseAction} || '_closeApplicationFrame()') . '">Close</a>' if $params{showCloseButton};
  
  $obj->{parsedElementCount} = 0; #just in case
  my $currentPathHtml = '';
  $currentPathHtml = "<h2 class='appHeader'>" . $obj->{parser}->findVar('$lang')->getString('o2.desktop.currentPath')
    . ": <span id='applicationFrameHeaderCurrentPath'>$path</span><span id='applicationFrameHeaderExtraPath'></span></h2>" if $path;

  return "<div id='application'>
  <div id='frameHeader'>
    <h1 class='frameTitle'>$params{frameTitle}</h1>
    $currentPathHtml
    $params{content}$closeTag
  </div>
  <div id='frameBody'>
    $frameBody";
}
#--------------------------------------------------------------------------------------------
sub ApplicationFrameFooter {
  my ($obj, %params) = @_;
  my $statusBar = "</div>";

  $obj->{parser}->pushMethods('addCell' => $obj, 'addCellSeparator' => $obj);
  $obj->{parser}->_parse( \$params{content} );
  $obj->{parser}->popMethod('addCell' => $obj, 'addCellSeparator' => $obj,);

  if ($params{statusBar}) {
    $obj->{parser}->_parse( \$params{content} );
    $statusBar .= "<div class='statusBar' id='applicationFrameFooterStatusBar'>$params{content}</div>";
  } 
  return "$statusBar</div>";
}
#--------------------------------------------------------------------------------------------
sub addCell {
  my ($obj,%params)=@_;
  my $w      = $params{width}  ? qq{ width="$params{width}" }    : '';
  my $action = $params{action} ? qq{ onclick="$params{action}" } : '';
  my $id     = $params{id}     ? qq{ id="$params{id}" }          : '';
  my $icon   = $params{icon}   ? qq{<img src="$params{icon}">}   : '';
  return "<div$action>$icon$params{content}</div>";
}
#--------------------------------------------------------------------------------------------
sub addHeaderButton {
  my ($obj, %params) = @_;
  my $w          = $params{width}  ? qq{ width="$params{width}" }    : '';
  my $action     = $params{action} ? qq{ onclick="$params{action}" } : '';
  my $id         = $params{id}     ? qq{ id="$params{id}" }          : '';
  my $icon       = $params{icon}   ? qq{<img src="$params{icon}">}   : '';
  my $domMethod  = "document.getElementById('$params{id}').className";
  return qq{<div onmouseover="$domMethod='application-HeaderButtonHover'" onmouseout="$domMethod='application-HeaderButton' "class=application-HeaderButton $w$id$action>$icon$params{content}</div>};
}
#--------------------------------------------------------------------------------------------
sub addCellSeparator {
  my ($obj, %params) = @_;
  return "<div class='separator'" . ($params{width} ? qq{ width="$params{width}" } : '') . "><img src='/images/system/pix.gif' width='1px' height='1px'></div>";
}
#--------------------------------------------------------------------------------------------
sub getSettingsMenu {
  my ($obj, %params) = @_;
  my $settingMenu = qq|
<o2 use O2CMS::Html::PopupMenu/>
<o2 PopupMenu menuId="settingsMenu" element="_settingsButton">
  <o2 addMenuItem name="Meta properties" icon="/images/system/prefs_16.gif" action="settingsMenuCallMethod('toggleMeta();')"/>
  <o2 addMenuItem name="Properties" icon="/images/system/confg_16.gif" action="settingsMenuCallMethod('toggleProperties();')"/>
  <o2 addSeparator/>
  <o2 addMenuItem name="Information" icon="/images/system/sinfo_16.gif" action="settingsMenuCallMethod('toggleAbout();')"/>
</o2:PopupMenu>|;
  $obj->{parser}->_parse(\$settingMenu);
  return $settingMenu;
}
#--------------------------------------------------------------------------------------------
1;
