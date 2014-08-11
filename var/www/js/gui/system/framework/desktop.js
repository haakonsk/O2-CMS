/**
 Handle all the desktop related logic
 - drag drop
 - setup new shortcut/widget
*/

o2.addLoadEvent(initDesktop);

var desktop = null;
function initDesktop() {
  desktop = new Desktop();
}

function Desktop(){
  this.setupDragDrop();
  return this;
}

Desktop.prototype.setupDragDrop = function() {
  var shortCuts = this.getShortcuts();
  for (var i = 0; i < shortCuts.length; i++) {
    var shortcut = document.getElementById( shortCuts[i] );
    if (shortcut) {
      var id   = shortCuts[i].split("_");
      var imgs = shortcut.getElementsByTagName("img");
      var img  = imgs[0];
      if (!img.id) {
        img.id = "shortcutImage_" + id[1];
      }

      img.setAttribute( "componentId", id[1]                    );
      img.setAttribute( "component",   "DesktopDraggableObject" );
      img.setAttribute( "dragid",      id[1]                    );
      initDragContainer(img);
    }
  }

  var dd = document.getElementById("desktopPanel");
  dd.setAttribute( "componentId", "desktop"             );
  dd.setAttribute( "component",   "DesktopDragReceiver" );
  initDragContainer(dd);
}

Desktop.prototype.getShortcuts = function() {
  var divs = document.body.getElementsByTagName("div");
  var shortCuts = new Array();
  for (var i = 0;i < divs.length; i++){
    if (divs[i].id.substring(0, 8) === "shortcut") {
      shortCuts.push( divs[i].id );
    }
  }
  return shortCuts;
}

Desktop.prototype.handleOnDropEvent = function(source, target, event) {
  var newY = event.getY() - 32;
  var newX = event.getX() - 32;    

  // Relocate of an existing shortcut
  if (source.data.className === "O2CMS::Obj::Desktop::Shortcut") {
    this.relocateShortcut( source.data.id, event.getY(), event.getX() );
  }
  else {
    var dropData = {
      name      : source.data.name || "",
      className : source.data.className,
      xPosition : newX > 0 ? newX : 0,
      yPosition : newY > 0 ? newY : 0,
      id        : source.data.id,
      iconUrl   : source.data.iconUrl
    };
    if( source.data.className == 'O2CMS::Obj::DomMenu::MenuItem') {
      dropData.action = source.data.menuAction;
    }
    this.setupNewShortcut(dropData);
  }
}

Desktop.prototype.setupNewShortcut = function(data) {
  try {
    o2.ajax.call({
      setMethod : "addShortcut",
      setParams : data,
      handler   : "desktop.handleAddShortcutResponse",
      method    : "post"
    });
  }
  catch(e) {
    alert("Could not relocate shortcut, reason: " + o2.getExceptionMessage(e));
  }
}

Desktop.prototype.handleAddShortcutResponse = function(data) {
  var shortcut = this._buildHTMLShortcut(data);
  document.getElementById("desktopPanel").appendChild(shortcut);
  if (desktopCSSLayout === "desktopFlowLayout") {
    this._sortShortcutsBy(desktopSortBy);
  }
}

Desktop.prototype._buildHTMLShortcut = function(data) {
  var main = document.createElement("DIV");
  main.id = "shortcut_" + data.newShortcutId;
  main.setAttribute( "shortcutId", data.newShortcutId );
  main.setAttribute( "icon",       data.iconUrl       );

  main.style.top  = data.yPosition + "px";
  main.style.left = data.xPosition + "px";
  main.className = "desktopShortcut " + desktopCSSLayout;
  main.setAttribute( "label",      data.name || "No name given" );
  main.setAttribute( "createTime", data.createTime              );

  var iconImg = document.createElement("IMG");
  iconImg.id        = "icon";
  iconImg.src       = data.iconUrl;
  iconImg.id        = "shortcutImage_" + data.newShortcutId;
  iconImg.className = "icon";
  main.appendChild(iconImg);

  // make the iconDragAble
  iconImg.setAttribute( "componentId", data.newShortcutId       );
  iconImg.setAttribute( "component",   "DesktopDraggableObject" );
  iconImg.setAttribute( "dragid",      data.newShortcutId       );
  initDragContainer(iconImg);

  var label = document.createElement("DIV");
  label.id        = "label_" + data.newShortcutId;
  label.className = "label";
  label.innerHTML = data.name;

  main.appendChild(label);
  if (!data.noContextMenu) {
    o2.replaceEvent( main, "contextmenu", function(e) {
      desktop.showShortcutContextMenu(e);
    });
  }
  o2.addEvent( iconImg, "click", new Function(["e"], data.action) );
  o2.addEvent( label,   "click", new Function(["e"], data.action) );
  return main;
}

Desktop.prototype.reloadDesktop = function() {
  location.href = location.href + "?42342342fdsafsdafdas";
}

Desktop.prototype.setFlowLayoutMode = function(orderBy) {
  this._setLayoutMode("desktopFlowLayout", orderBy);
}

Desktop.prototype.setUserLayoutMode = function() {
  this._setLayoutMode("desktopUserLayout");
}

Desktop.prototype._setLayoutMode = function(layoutMode, orderBy) {
  desktopCSSLayout = layoutMode;

  var shortCuts = this.getShortcuts();
  for (var i = 0; i < shortCuts.length; i++) {
    var shortDiv = document.getElementById( shortCuts[i] );
    if (shortDiv) {
      var cssClass = shortDiv.className.split(" ");
      shortDiv.className=cssClass[0]+" "+layoutMode;
    }
  }
  if (orderBy == null) {
    orderBy = 'auto';
  }
  if (layoutMode == "desktopFlowLayout") {
    this._sortShortcutsBy(orderBy);
  }
  desktopSortBy = orderBy;

  var data = {
    layoutMode : layoutMode == "desktopFlowLayout" ? "flowLayout" : "userLayout",
    orderBy    : orderBy
  };
  try {
    o2.ajax.call({
      setMethod : "saveDesktopSettings",
      setParams : data,
      handler   : "desktop.handleSaveLayoutModeResponse",
      method    : "post"
    });
  }
  catch(e) {
    alert( "Could not set layout mode, reason: " + o2.getExceptionMessage(e) );
  }
}

Desktop.prototype._sortShortcutsBy = function(sortBy) {
  var shortCuts    = this.getShortcuts();
  var shortCutRefs = new Array();
  var desktopPanel = document.getElementById("desktopPanel");

  for (var i = 0; i < shortCuts.length; i++) {
    var short = document.getElementById( shortCuts[i] );
    shortCutRefs.push(        short );
    desktopPanel.removeChild( short );
  }

  if (sortBy === "name") {
    shortCutRefs.sort(this._sortByName);
  }
  else if (sortBy === "type") {
    shortCutRefs.sort(this._sortByType);
  }
  else {
    shortCutRefs.sort(this._sortByDate);
  }

  for (var i = 0; i < shortCutRefs.length; i++) {
    desktopPanel.appendChild( shortCutRefs[i] );
  }
}

Desktop.prototype._sortByDate = function(a, b) {
  var aa = a.getAttribute("createTime");
  var bb = b.getAttribute("createTime");
  return (aa < bb);
}

Desktop.prototype._sortByName = function(a,b) {
  var aName = a.getAttribute("label").toLowerCase();
  var bName = b.getAttribute("label").toLowerCase();
  return (aName > bName);
}

Desktop.prototype._sortByType = function(a,b) {
  var aName = a.getAttribute("icon").toLowerCase();
  var bName = b.getAttribute("icon").toLowerCase();
  return (aName > bName);
}

Desktop.prototype.handleSaveLayoutModeResponse = function(data) {}

Desktop.prototype.relocateShortcut = function(id, y, x) {
  if (desktopCSSLayout === "desktopFlowLayout") {
    this.setUserLayoutMode();
  }

  var shortcut = document.getElementById("shortcut_" + id);
  if (shortcut == null) {
    alert("DESKTOP ERROR\n- could handle relocation of shortcut [" + id + "]");
    return;
  }
  var diffX = shortcut.offsetWidth;
  var diffY = shortcut.offsetHeight;
  var newY  = y - (diffY/2);
  var newX  = x - (diffX/2);
  shortcut.style.top  = newY + "px";
  shortcut.style.left = newX + "px";

  var data = {
    shortcutId : id,
    newX       : newX,
    newY       : newY
  };
  
  try {
    o2.ajax.call({
      setMethod : "relocateShortcut",
      setParams : data,
      handler   : "desktop.handleRelocateShortcutResponse",
      method    : "post"
    });
  }
  catch (e) {
    alert( "Could not relocate shortcut, reason: "+o2.getExceptionMessage(e) );
  }
}

Desktop.prototype.handleRelocateShortcutResponse = function(params) {}

//------------------------------------------------------------------------------
// Widget code and its methods
//------------------------------------------------------------------------------
                  
Desktop.prototype.handleRelocateWidgetEvent = function(e, ins) {
  var d = ins.initDragElement.id.split("_");
  if (d[0] !== "widget") {
    return;
  }

  var elm = document.getElementById(ins.initDragElement.id);
  var top  = parseInt( elm.style.top  );
  var left = parseInt( elm.style.left );
  desktop.relocateWidget( d[1], top, left );
}
//------------------------------------------------------------------------------
Desktop.prototype.relocateWidget = function(id, y, x) {
  var data = {
    widgetId : id,
    newX     : x,
    newY     : y
  };
  this.saveWidgetSettings(data);
}
//------------------------------------------------------------------------------
Desktop.prototype.showWidget = function(widgetId, shortcutId) {
  document.getElementById( "widget_"   + widgetId   ).style.display = "";
  document.getElementById( "shortcut_" + shortcutId ).style.display = "none";
  var data = {
    widgetId   : widgetId,
    shortcutId : shortcutId
  };

  try {
    o2.ajax.call({
      setMethod : "showWidget",
      setParams : data,
      handler   : "desktop.handleShowWidget"
    });
  }
  catch (e) {
    alert( "Could not save widget settings, reason: " + o2.getExceptionMessage(e) );
  }
}
//------------------------------------------------------------------------------
Desktop.prototype.parseId = function(elmId) {
  var d = elmId.split("_");
  for (var i = d.length; i > -1; i--) {
    var id = parseInt( d[i] );
    if (id && id > 0) {
      return id;
    }
  }
  return null;
}
//------------------------------------------------------------------------------
Desktop.prototype.handleShowWidget = function(data)  {
  desktop.handleDeleteShortcut(data);
}
//------------------------------------------------------------------------------
Desktop.prototype.minimizeWidget = function(e) {
  e.stopPropagation();
  var elm = e.getTarget();
  var data = {
    widgetId    : desktop.parseId(elm.id),
    isMinimized : 1
  };
  try {
    o2.ajax.call({
      setMethod : "minimizeWidget",
      setParams : data,
      handler   : "desktop.handleMinimizeWidget",
      method    : "post"
    });
  }
  catch (e) {
    alert( "Could not save widget settings, reason: " + o2.getExceptionMessage(e) );
  }
}
//------------------------------------------------------------------------------
Desktop.prototype.handleMinimizeWidget = function(data) {
  data.noContextMenu = true;
  var shortcut = this._buildHTMLShortcut(data);
  document.getElementById("desktopPanel").appendChild(shortcut);
  document.getElementById("widget_" + data.widgetId).style.display = "none";
}
//------------------------------------------------------------------------------
Desktop.prototype.deleteWidget = function(e) {
  e.stopPropagation();
  var elm = e.getTarget();
  var data = {
    widgetId : desktop.parseId(elm.id)
  };
  try {
    o2.ajax.call({
      setMethod : "deleteWidget",
      setParams : data,
      handler   : "desktop.handleDeleteWidget",
      method    : "post"
    });
  }
  catch (e) {
    alert( "Could not save widget settings, reason: " + o2.getExceptionMessage(e) );
  }
}
//------------------------------------------------------------------------------
Desktop.prototype.handleDeleteWidget = function(data) {
  if (data.result === "ok") {
    var d = document.getElementById("desktopPanel");
    d.removeChild( document.getElementById("widget_" + data.widgetId) );
  }
}
//------------------------------------------------------------------------------
Desktop.prototype.removeWidget = function(e) {
  e.stopPropagation();
  var elm = e.getTarget();
  var data = {
    widgetId : desktop.parseId(elm.id)
  };

  try {
    o2.ajax.call({
      setMethod : "removeWidget",
      setParams : data,
      handler   : "desktop.handleRemoveWidget",
      method    : "post"
    });
  }
  catch (e) {
    alert( "Could not save widget settings, reason: " + o2.getExceptionMessage(e) );
  }
}
//------------------------------------------------------------------------------
Desktop.prototype.handleRemoveWidget = function(data) {
  if (data.result === "ok") {
    document.getElementById("desktopPanel").removeChild( document.getElementById("widget_" + data.widgetId) );
  }
}
//------------------------------------------------------------------------------
Desktop.prototype.saveWidgetSettings = function(data) {
  try {
    o2.ajax.call({
      setMethod : "saveWidgetSettings",
      setParams : data,
      handler   : "desktop.handleSaveWidgetSettingsResponse",
      method    : "post"
    });
  }
  catch (e) {
    alert( "Could not save widget settings, reason: " + o2.getExceptionMessage(e) );
  }
}
//------------------------------------------------------------------------------
Desktop.prototype.handleSaveWidgetSettingsResponse = function(params) {}
//------------------------------------------------------------------------------

Desktop.prototype.showWidgetDialog = function(widgetId) {
  o2.popupDialog.display("addWidgetDialog");
  document.getElementById("addWidgetDialogIframe").src = o2.urlMod.urlMod({
    setClass  : "System-Desktop",
    setMethod : "listWidgets"
  });
}
//------------------------------------------------------------------------------
Desktop.prototype.addWidget = function(pseudoWidgetId) {
  try {
    o2.ajax.call({
      setMethod : "addWidget",
      setParams : { pseudoWidgetId : pseudoWidgetId },
      handler   : "desktop.handleAddWidgetResponse",
      method    : "post"
    });
  }
  catch (e) {
    alert("Could not save widget settings, reason: " + o2.getExceptionMessage(e));
  }
}
//------------------------------------------------------------------------------
Desktop.prototype.handleAddWidgetResponse = function(data) {
  desktop.addWidgetToDesktop(data);
}
//------------------------------------------------------------------------------
Desktop.prototype.addWidgetToDesktop = function(data) {
  var widget = document.createElement("DIV");
  widget.id           = "widget_" + data.widgetId;
  widget.style.height = data.height + "px";
  widget.style.width  = data.width  + "px";
  widget.style.left   = (data.xPosition || 25) + "px";
  widget.style.top    = (data.yPosition || 25) + "px";
  widget.style.border = "0px solid red";
  widget.className    = "widget";

  if (data.isMinimized && data.isMinimized == "1") {
    widget.style.display = "none";
  }

  var widgetToolbar = document.createElement("DIV");
  widgetToolbar.id           = "toolbar_" + data.widgetId;
  widgetToolbar.className    = "toolbar";
  widgetToolbar.style.zIndex = 100;
  o2.addEvent( widgetToolbar, "mouseover", desktop.showWidgetDecoration );
  o2.addEvent( widgetToolbar, "mouseout",  desktop.hideWidgetDecoration );

  var toolbarContainer = document.createElement("DIV");
  toolbarContainer.id            = "toolbar_container_widget_" + data.widgetId;
  toolbarContainer.className     = "container";
  toolbarContainer.style.display = "none";

  var removeImg = document.createElement("IMG");
  removeImg.id  = "remove_" + data.widgetId;
  removeImg.src = "/images/icons/o2default/O2/action/delete/O2-action-delete-16.png";
  o2.addEvent(removeImg, "mousedown", desktop.deleteWidget);
  toolbarContainer.appendChild(removeImg);

  var moveImg = document.createElement("IMG");
  moveImg.id  = "move_" + data.widgetId;
  moveImg.src = "/images/icons/o2default/O2/action/move/O2-action-move-16.png";
  toolbarContainer.appendChild(moveImg);

  var minimizeImg = document.createElement("IMG");
  minimizeImg.id  = "minimize_" + data.widgetId;
  minimizeImg.src = "/images/icons/o2default/O2/action/minimize/O2-action-minimize-16.png";
  o2.addEvent(minimizeImg, "mousedown", desktop.minimizeWidget);
  toolbarContainer.appendChild(minimizeImg);

  widget.appendChild(widgetToolbar);
  widgetToolbar.appendChild(toolbarContainer);    

  if (data.widgetUrl) {
    var iframe = document.createElement("IFRAME");
    iframe.id                = "iframe_widget_" + data.widgetId;
    iframe.className         = "iframeWidget";
    iframe.src               = data.widgetUrl;
    iframe.frameBorder       = 0;
    iframe.style.border      = "0px solid blue";
    iframe.style.margin      = "0px";
    iframe.style.padding     = "0px";
    iframe.style.height      = "100%";
    iframe.style.width       = "100%";
    iframe.style.background  = "transparent";
    iframe.scrolling         = "no";
    iframe.allowTransparency = "true";
    iframe.setAttribute("allowTransparency", true);
    widget.appendChild(iframe);
  }
  else {
    var div = document.createElement("DIV");
    div.id = "div_widget_" + data.widgetId;
    alert(data.widgetCode);
    div.innerHTML     = data.widgetCode;
    div.style.border  = "0px";
    div.style.margin  = "0px";
    div.style.padding = "0px";
    div.style.height  = "100%";
    div.style.width   = "100%";
    widget.appendChild(div);
  }
  document.getElementById("desktopPanel").appendChild(widget);
  o2.draggable.setupDragDrop({
    initDragElement : widget,
    dragEndCallback : desktop.handleRelocateWidgetEvent
  });

  if (data.isResizeable && data.isResizeable == 1) {
    o2Resizable.setupResizable({
      element           : widget,
      allowedDirections : "se",
      edgeThickness     : 20
    });
  }
  return true;
}

Desktop.prototype.showWidgetDecoration = function(e) {
  e.stopPropagation();
  var elm = e.getTarget();
  var widgetId = desktop.parseId(elm.id);
  document.getElementById("toolbar_container_widget_" + widgetId).style.display = "";  
  o2.addClassName( document.getElementById("widget_" + widgetId), "moving" );
}

Desktop.prototype.hideWidgetDecoration = function(e) {
  e.stopPropagation();
  var elm = e.getTarget();
  var d = elm.id.split("_");
  var widgetId = d[ d.length-1 ];
  document.getElementById("toolbar_container_widget_" + widgetId).style.display = "none";  
  o2.removeClassName( document.getElementById("widget_"+widgetId), "moving" );
}

//------------------------------------------------------------------------------
// Context menu for shortcuts and its methods
//------------------------------------------------------------------------------
Desktop.prototype.initShortcutContextMenu = function() {
  var shortCuts = this.getShortcuts();
  for (var i = 0; i < shortCuts.length; i++) {
    var shortDiv = document.getElementById( shortCuts[i] );
    o2.replaceEvent( shortDiv, "contextmenu", function(e) { desktop.showShortcutContextMenu(e); } );
    o2.replaceEvent( shortDiv, "click",       function(e) { e.stopPropagation();                } );
  }
}

Desktop.prototype.showShortcutContextMenu = function(e) {
  e.stopPropagation();
  e.preventDefault();
  this.currentShortcutId = e.getTarget().parentNode.getAttribute("shortcutId");
  desktopMenu.hideMenu();
  shortCutContextMenu.showMenu( e.getY(), e.getX() );
}

Desktop.prototype.editShortcutName = function() {
    this.isEditingShortcutName = true;
    var shortCutDiv   = document.getElementById( "shortcut_" + desktop.currentShortcutId );
    var shortCutLabel = document.getElementById( "label_"    + desktop.currentShortcutId );
    var editNameForm  = document.getElementById( "editShortCutForm"                      );
    shortCutDiv.appendChild(editNameForm);
    editNameForm.editShortcutName.value = shortCutDiv.getAttribute("label");

    o2.replaceEvent( editNameForm.editShortcutName, "mousedown", function(e) { desktop.textAreaEvent(e);        } );
    o2.replaceEvent( document,                      "mousedown", function(e) { desktop.saveEditShortcutName(e); } );
    editNameForm.style.display  = "";
    shortCutLabel.style.display = "none";
    editNameForm.editShortcutName.focus();    
    editNameForm.editShortcutName.select();
}

Desktop.prototype.saveEditShortcutName = function(e) {
  if (this.isEditingShortcutName) {
    var editNameForm  = document.getElementById( "editShortCutForm"                      );
    var shortCutDiv   = document.getElementById( "shortcut_" + desktop.currentShortcutId );
    var shortCutLabel = document.getElementById( "label_"    + desktop.currentShortcutId );

    shortCutLabel.style.display = "";

    editNameForm.style.display = "none";
    document.body.appendChild( shortCutDiv.removeChild(editNameForm) );
    if (editNameForm.editShortcutName.value != shortCutLabel.innerHTML) {
      this.saveNewShortcutName( editNameForm.editShortcutName.value, desktop.currentShortcutId );
      shortCutLabel.innerHTML = editNameForm.editShortcutName.value;
      shortCutDiv.setAttribute("label", editNameForm.editShortcutName.value);  
    }
    editNameForm.editShortcutName.value = "";
    o2.removeEvent(editNameForm.editShortcutName, "mousedown", function(e) {
      desktop.textAreaEvent(e);
    });
  }

  this.isEditingShortcutName = false;
}

Desktop.prototype.saveNewShortcutName = function(name, shortcutId) {
  o2.ajax.call({
    setMethod : "saveNewShortcutName",
    setParams : { shortcutId : shortcutId, shortcutName : name },
    handler   : "desktop.handleSaveNewShortcutNameResponse",
    method    : "post"
  });
}

Desktop.prototype.handleSaveNewShortcutNameResponse = function(data) {}

Desktop.prototype.textAreaEvent = function(e) {
  e.stopPropagation();
}

Desktop.prototype.deleteShortcut = function(shortCutId) {
  // If delete by dragging down to the trashcan icon in bottom bar
  if (shortCutId != null  &&  shortCutId.indexOf("shortcutImage_") == 0) {
    var d = shortCutId.split("_");
    this.currentShortcutId = d[1];
  }
  try {
    o2.ajax.call({
      setMethod : "deleteShortcut",
      setParams : { shortcutId : this.currentShortcutId },
      handler   : "desktop.handleDeleteShortcut",
      method    : "post"
    });
  }
  catch (e) {
    alert( "Could not delete shortcut, reason: " + o2.getExceptionMessage(e) );
  }
}

Desktop.prototype.handleDeleteShortcut = function(data) {
  if (data.result === "ok") {
    var short = document.getElementById("shortcut_" + data.shortcutId);
    var desktopPanel = document.getElementById("desktopPanel");
    desktopPanel.removeChild(short);
    this.currentShortcutId = null;
  }
}
