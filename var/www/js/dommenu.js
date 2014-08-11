var hideTimeOut = 2000;
var timeouts = new Array();
var _domMenuCounts = 0;
var _domMenuNamePrefix = "_domMenu";
var _defaultDOMMEnuCSSClassname = "domMenu";
var _domMenus  = new Array();
var _isShowing = new Array();
var _popupMenus = null;

function DOMMenu(elmId, title, action, direction, visibility, parent, doc, hoverAction, dragId) {
  _domMenuCounts++;
  this.doc       = doc || document;
  this.id        = elmId;
  this.parent    = parent;
  this.kids      = Array();
  this.direction = direction;
  this.container = null;
  this.className = _defaultDOMMEnuCSSClassname;
  // is not a popup menu, but a pull down menu
  if (elmId != null) {
    this.elm = this.doc.getElementById(elmId);

    if (this.elm == null) {
      this.elm = this.doc.createElement("DIV");
      this.elm.setAttribute("id", elmId);
      o2.addClassName(this.elm, "domMenuItem");
      if (parent != null && action != null) {
        o2.replaceEvent(this.elm, "click", new Function( '_handleAction("' + action + '");'));
      }
      //action todo run when onmouseover for this menuitem
      if (hoverAction != null && hoverAction != "") {
        o2.replaceEvent(this.elm, "mouseover", new Function(hoverAction));
      }

      if (title != null) {
        var icon = this.doc.createElement("IMG");
        if (title.length >= 2) {
          icon.src = title[1];
        }
        else { 
          icon.src = "/images/system/pix.gif";
        }
        var menuText = this.doc.createElement("SPAN");
        menuText.innerHTML = title[0];
        menuText.className = "menuItemText";
        this.elm.appendChild(icon);
        this.elm.appendChild(menuText);

        //dragdrop setup of this element
        if (dragId) {
          //console.log("setup up drag on elmId:"+elmId+" title:"+title+" : "+dragId);
          icon.id = "dragIcon_" + dragId;
          icon.setAttribute( "componentId", dragId );
          icon.setAttribute( "component",   "DomMenuDraggableObject" );
          icon.setAttribute( "dragid",      dragId);
          icon.setAttribute( "menuAction",  action);
          initDragContainer(icon);
        }
      }
      this.doc.body.appendChild(this.elm);
    }
  }
  else { // is a popup menu,

  }
  this.subMenuParentOffsetTop  = 0;
  this.subMenuParentOffsetLeft = 0;
  this.isActive = false;
  return this;
}

function DOMPopupMenu(element, handleRightClickManually) {
  this.handleRightClickManually = handleRightClickManually;
  this.element = element;
  var doc = document; // doc is the document that includes this js file.
  this.element = this.element || doc;
  if (typeof(this.element) !== "object") {
    return alert("Argument to new DOMPopupMenu must be an html element");
  }
  // XXX handle click for element and multiple popups
  if (_popupMenus == null) {
    _popupMenus = new Array();
  }

  var popId = (this.element === doc ? "document" : _domMenuNamePrefix + (_domMenuCounts+1));

  // params: elmId,title,action,direction,visibility,parent,doc
  _popupMenus[popId] = new DOMMenu(popId, null, null, "down"); //, null, null, doc);
  _popupMenus[popId].handleRightClickManually = this.handleRightClickManually;

  o2.replaceEvent( this.element, "contextmenu", new Function(["e"], "_popupMenus['" + popId + "'].handleRightClick(e);" ) );
  o2.replaceEvent( doc,          "click",       function(e) { hidePopupMenus(); } );

  this.subMenuParentOffsetTop  = -10;
  this.subMenuParentOffsetLeft = -10;

  return _popupMenus[popId];
}

DOMMenu.prototype.setClassName = function(className) {
  this.className = className;
}

DOMMenu.prototype.handleRightClick = function(e) {
  if (this.handleRightClickManually) {
    return;
  }
  e.preventDefault();
  e.stopPropagation();
  hidePopupMenus();
  if (!this.handleRightClickManually) {
    this.showMenu( e.getY(), e.getX() );
  }
  return false;
}

DOMMenu.prototype.addSeperator = function() {
  this.addSeparator();
}

DOMMenu.prototype.addSeparator = function() {
  var separator = this.doc.createElement("div");
  o2.addClassName(separator, this.container.className + "-separator");
  this.container.appendChild(separator);
}

DOMMenu.prototype.addMenuItem = function(title, action, direction, hoverAction, dragId) {
  //creating sub menu items container
  if (this.container == null) {
    this.container = this.doc.createElement("DIV");
    this.doc.body.appendChild(this.container);

    this.container.setAttribute("id","domMenu_container_" + this.id);

    this.container.style.visibility = "hidden";
    this.container.style.position   = "absolute";
    this.container.style.top        = "0px";
    this.container.style.left       = "0px";

    o2.replaceEvent( this.container, "mousemove", new Function("_cancelHide('" + this.container.id + "')") );
    o2.replaceEvent( this.container, "mouseout",  new Function("_hideMenu('"   + this.container.id + "')") );

    o2.addClassName(this.container, this.className + "-container");
    _domMenus[this.container.id] = this;

    if (this.parent == null) {
      o2.addClassName(this.elm, "domMenuItem");
      o2.replaceEvent(this.elm, "click", function(e) {
        var target = e.getTarget();
        while (target && !o2.hasClassName(target, "domMenuItem")) { // In case the target element is a descendent of the domMenuItem.
          target = target.parentNode;
        }
        e.targetId = target.id;
        e.preventDefault(); 
        e.stopPropagation();
        if (_domMenus[e.targetId] == null) {
          e.targetId = "domMenu_container_" + e.targetId;
        }
        _showMenu(e.targetId);
      }); // avoid text select 
    }
    else {
      o2.replaceEvent(this.elm, "mouseover", new Function("_showMenu('" + this.container.id + "');"));
    }
    o2.replaceEvent(this.elm, "mouseout",  new Function("_hideMenu('"   + this.container.id + "', 2)"));
    o2.replaceEvent(this.elm, "mousemove", new Function("_cancelHide('" + this.container.id + "')"));

    this.elm.onselectstart = function() { return false; }; 
    if (this.parent != null) {
      o2.addClassName(this.elm, "hasSubMenu");
    }
  }
  if (direction == null) {
    direction = "left";
  }
  hoverAction += "; _clearTimeoutsAndHideMenuItems('" + this.container.id + "');";
  var childMenu = new DOMMenu(this.container.id + "_" + this.kids.length, title, action, direction, "hidden", this, this.doc, hoverAction, dragId);
  childMenu.setClassName( this.className );
  this.kids.push(childMenu);
  this.container.appendChild(this.kids[this.kids.length-1].elm);
  if (this.kids.length > 15) {
    o2.addClassName(this.container, "longMenu");
  }

  return this.kids[this.kids.length-1];
}

DOMMenu.prototype.executeEvent = function(elmId, eventType) {
  for (var i = 0; i < this.EventRegister[elmId][eventType].length; i++) {
    eval(this.EventRegister[elmId][eventType][i]);
  }
}

DOMMenu.prototype.getAbsTop = function() {
  var top = 0;
  var obj = this.elm;

  if (obj.offsetParent) {
    while (obj.offsetParent) {
      top += obj.offsetTop
      obj = obj.offsetParent;
    }
  }
  else if (obj.y) {
    top += obj.y;
  }
  return top;
}

DOMMenu.prototype.getAbsLeft = function() {
  var left = 0;
  var obj = this.elm;

  if (obj.offsetParent) {
    while (obj.offsetParent) {
      left += obj.offsetLeft;
      obj = obj.offsetParent;
    }
  }
  else if (obj.x) {
    left += obj.x;
  }
  return left;
}

DOMMenu.prototype.clearTimeoutsAndHideMenuItems = function() {
  // Clear all timeouts
  for (var i = 0; i < timeouts.length; i++) {
    clearTimeout( timeouts[i] );
  }
  // Hide other menu items on the same level
  for (var i = 0; i < this.kids.length; i++) {
    this.kids[i].hideMenu(false, false, true); // Hide without delay
  }
}

DOMMenu.prototype.showMenu = function(top, left) {
  if (!this.container) {
    return;
  }
  if (top == null) {
    top = this.getAbsTop() + this.subMenuParentOffsetTop;
  }
  if (left == null) {
    left = this.getAbsLeft() + this.subMenuParentOffsetLeft;
  }

  if (this.direction == null || this.direction == "down") {
    top += this.elm.offsetHeight;
  }
  else if (this.direction == "left") {
    left += this.elm.offsetWidth;
  }

  // XXX fix popup adjust according to window size
  // are starting to show out side of the viewable window? 
  // if(this.parent == null)
  // window.status=left+" "+( this.container.offsetWidth)+" > "+this.getInnerWidth()+" "+this.elm.id;
  // if (this.parent!= null)
  var edge = 20;
  if (this.parent == null && (left + this.container.offsetWidth) > this.getInnerWidth() - edge) {
    left = this.getInnerWidth() - this.container.offsetWidth - edge;
  }
  else if (this.parent != null && (left + this.elm.offsetWidth) > this.getInnerWidth() - edge) {
    left -= this.elm.offsetWidth*2;
  }
  if (top+this.container.offsetHeight > (this.getInnerHeight() - edge)) {
    top = this.getInnerHeight() - this.container.offsetHeight;
  }

  this.isActive = true;
  this.container.style.left       = left + "px";
  this.container.style.top        = top  + "px";
  this.container.style.visibility = "visible";
  this.container.style.zIndex     = (this.parent != null ? this.parent.container.style.zIndex+1 : 0);
}

DOMMenu.prototype.getInnerWidth = function()  { 
  var w = window.innerWidth;
  if (w == null) {
    w = window.document.body.offsetWidth;
  }
  return w;
}

DOMMenu.prototype.getInnerHeight = function()  { 
  var h = window.innerHeight;
  if (h == null) {
    h = window.document.body.offsetHeight;
  }
  return h;
}

DOMMenu.prototype.setAutoHide = function(bool) {
  this.autoHide = bool;
  if (this.autoHide) {
    this.hideMenu();
  }
}

DOMMenu.prototype.hideMenu = function(force, hideParent, hideKids) {
  if (typeof(hideParent) === "undefined") { 
    hideParent = true;
  }

  if (force == null) {
    force = false;
  }
  if (!force && this.container == null) {
    return;
  }
  if (!force && this.isActive) {
    return;
  }
  if (this.container != null) {
    this.container.style.visibility = "hidden";
  }
  this.isActive = false;
  if (this.parent != null && hideParent) {
    this.parent.hideMenu();
  }
  if (hideKids && this.kids) {
    for (var i = 0; i < this.kids.length; i++) {
      this.kids[i].hideMenu(force, hideParent, hideKids);
    }
  }
}

DOMMenu.prototype.toggleMenu = function() {
  if (this.isActive) {
    this.hideMenu(1);
  }
  else {
    this.showMenu();
  }
}

DOMMenu.prototype.isShowing = function() {
  return this.isActive;
}

DOMMenu.prototype.setActive = function(bool) {
  this.isActive = bool;
  if (this.parent != null) 
    this.parent.setActive(bool);
}

function _showMenu(id) {
  if (!_domMenus[id]) {
    return alert("_domMenus['" + id + "'] does not exist");
  }
  _domMenus[id].showMenu();
}

function hidePopupMenus() {
  for (var id in _domMenus) {
    _domMenus[id].hideMenu(true);
  }
}

function _hideMenu(id) {
  _domMenus[id].setActive(false);
  timeouts.push( window.setTimeout("_domMenus['" + id + "'].hideMenu(true, true, true)", hideTimeOut) );
}


function _cancelHide(id) {
  _domMenus[id].setActive(true);
  cancelTime = (new Date).getTime();
  // Activating Mozilla and Iframe event problem
  // XXX better browswer detection rule needed here
  if (navigator.appName == "Netscape" && _domMenus[id].doc.getElementsByTagName("IFRAME").length > 0) {
    timeouts.push( window.setTimeout("_domMenus['" + id + "'].mozillaHideMenu()", cancelEventTimeOut) );
  }
}


function _handleAction(action) {
  try {
    eval(action);
  }
  catch (e) {
    alert("_handleAction: Error eval'ing '" + action + "': " + o2.getExceptionMessage(e));
  }
  for (elm in _domMenus) {
    if (_domMenus[elm]) {
      _domMenus[elm].hideMenu(true);
    }
  }
}

function _clearTimeoutsAndHideMenuItems(id) {
  _domMenus[id].clearTimeoutsAndHideMenuItems();
}

//--------------------------------------------------------------------
// Iframe problem fix for firefox
var cancelEventTimeOut = 2000;
var cancelTime = 0;
DOMMenu.prototype.mozillaHideMenu = function() {
  if ( (cancelTime >0 && (new Date).getTime() - cancelTime) >= cancelEventTimeOut) {
    for (elm in _domMenus) {
      if (_domMenus[elm]) {
        _domMenus[elm].hideMenu(true);
      }
    }
  }
}

/*
 * Nullify this menu and remove all components beloging to it.
 */
DOMMenu.prototype.flush = function() {
  if (this.kids.length > 0) {
    for (var i in this.kids) {
      this.kids[i].flush();
    }
  }
  var elm = this.doc.getElementById(this.id);
  if (elm != null) {
    try {
      elm.parentNode.removeChild(elm);
    }
    catch (e) {
      alert("DOMMENU: could remove node\n" + o2.getExceptionMessage(e));
    }
  }
  if (this.container != null) {
    try {
      this.doc.body.removeChild(this.container);
    }
    catch (e) {
      // Suppress error message
    }
    delete _domMenus[this.container.id];
  }
}

DOMMenu.prototype.flushKids = function() {
  if (this.kids.length > 0) {
    for (var i in this.kids) {
      this.kids[i].flush();
    }
  }
  this.kids = new Array();
}
