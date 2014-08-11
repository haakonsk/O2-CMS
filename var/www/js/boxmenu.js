var _boxMenuCounts = 0;
var _boxMenuNamePrefix = "boxMenu";

var _defaultCSSClassname = "boxMenu";
var _boxMenus = new Array();
var _aniStep = 4;

function BoxMenu(id, doc, props) {
  _boxMenuCounts++;
  if (doc == null) {
    this.doc = document;
  }
  else {
    this.doc = doc;
  }
  this.menuItems    = 0;
  this.activeMenuId = null;
  if (id != null) {
    this.id = id;
  }
  else {
    this.id = _boxMenuNamePrefix+_boxMenuCounts;
  }
  if (props != null) {
    this.props = props;
  }
  this.className = _defaultCSSClassname;
  this.animateMenu = true;
  this.initialize(this.id);
  _boxMenus[this.id] = this;
}

/*
 * Building the main table 
 */
BoxMenu.prototype.initialize = function(tableId) {
  var thisContainer = this.doc.getElementById(tableId); 
  boxTable = this.doc.createElement("TABLE");
  boxTable.className = this.className;
  boxTable.id = tableId;
  boxTable.cellSpacing = "0";
  boxTable.cellPadding = "0";
  boxTable.border = "0";
  if (this.props.height) {
    boxTable.style.height = this.props.height;
  }
  if (this.props.width) {
    boxTable.style.width = this.props.width;
  }
  
  if (thisContainer == null) {
    this.doc.body.appendChild(boxTable);
  }
  else {
    thisContainer.appendChild(boxTable);
  }
  var boxTBody = this.doc.createElement("TBODY");
  boxTable.appendChild(boxTBody);
  this.table = boxTable;  
}

BoxMenu.prototype.addItem = function(title) {
  this.addItem(title, null);
}

BoxMenu.prototype.addItem = function(title, icon, activeIcon) {
  this.menuItems++;
  var tTr = this.doc.createElement("TR");
  tTr.setAttribute("id", "menuTr_" + this.table.id + "_" + this.menuItems);
  var tTd = this.doc.createElement("TD");

  tTd.setAttribute("id", "menuTd_" + this.table.id + "_" + this.menuItems);
  tTd.className = this.className + "-menu-item";
  
  var mItemDiv = this.doc.createElement("DIV");
  mItemDiv.setAttribute("id", "menuTd_" + this.table.id + "_" + this.menuItems + "_div");
  mItemDiv.className = tTd.className + "-icon";
  mItemDiv.appendChild( this.doc.createTextNode(title) );
  tTd.appendChild(mItemDiv);
  if (icon != null) {
    mItemDiv.style.backgroundImage = "url(" + icon + ")";
    mItemDiv.BoxMenuItemIcon = icon;
  }
  if (activeIcon != null) {
    mItemDiv.BoxMenuItemActiveIcon = activeIcon;
  }

  
  tTr.appendChild(tTd);
  tTr.onmousedown = this.handleClick;
  tTr.onmouseover = this.onHover;
  tTr.onmouseout  = this.onHover;
  
  //building the bodycell for this menu item
  var tTrBody = this.doc.createElement("TR");
  tTrBody.setAttribute("id", "bodyTr_" + this.table.id + "_" + this.menuItems);
  //not visible yet
  tTrBody.style.display = "none";
  var tTdBody = this.doc.createElement("TD");
  tTdBody.setAttribute("id", "bodyTd_" + this.table.id + "_" + this.menuItems);
  tTdBody.style.height = "100%"; 
  tTrBody.appendChild(tTdBody);
  this.table.getElementsByTagName("tbody").item(0).appendChild(tTr);
  this.table.getElementsByTagName("tbody").item(0).appendChild(tTrBody);
  return this.table.id + "_" + this.menuItems;
}

BoxMenu.prototype.selectByIdx = function(idx) {
  this.showMenu(this.id + '_' + idx);
}

BoxMenu.prototype.add = function(title, icon, htmlBody, activeIcon) {
  newId = this.addItem(title, icon, activeIcon);
  this.setMenuBody(newId, htmlBody);
  return newId;
}

BoxMenu.prototype.addFromElement = function(title, icon, elementId, activeIcon) {
  newId = this.addItem(title, icon, activeIcon);
  this.setMenuBodyFromElement(newId, elementId);
  return newId;
}

BoxMenu.prototype.addRefToUrl = function(title, icon, url, activeIcon) {
  newId = this.addItem(title, icon, activeIcon);
  this.setMenuBodyUrl(newId, url);
  return newId;
}

BoxMenu.prototype.setMenuBody = function(itemId, htmlBody) {
  var elm = this.doc.getElementById("bodyTd_" + itemId);
  elm.className = this.className + "-menu-body";
  var div = this.doc.createElement("DIV");
  div.className = this.className + "-menu-innerbody";
  div.id = "bodyTd_" + itemId + "_div";
  div.style.width = this.props.width;
  div.style.height = "100%";
  div.innerHTML = htmlBody;
  elm.appendChild(div);
}

BoxMenu.prototype.setMenuBodyFromElement = function(itemId,elementId) {
  var elm = this.doc.getElementById("bodyTd_" + itemId);
  elm.className = this.className + "-menu-body";
  elm.setAttribute("valign", "top");

  var div = this.doc.createElement("DIV");
  div.id = "bodyTd_" + itemId + "_div";
  div.className = this.className + "-menu-innerbody";
  div.style.width = this.props.width;
  
  var elmSrc = this.doc.getElementById(elementId)
  div.appendChild(elmSrc);
  elm.appendChild(div);
}
//XXX fix borders on iframe
BoxMenu.prototype.setMenuBodyUrl = function(itemId, url) {
  var elm = this.doc.getElementById("bodyTd_" + itemId);
  elm.className = this.className + "-menu-body";
  elm.style.padding = "0px";
  elm.style.width = this.props.width;
  var iframe = this.doc.createElement("IFRAME");
  
  iframe.style.display = "none";
  iframe.id = "bodyTd_" + itemId + "_iframe";
  iframe.src = url;
  iframe.style.border = "0px";
  iframe.style.margin = "0px";
  iframe.style.width  = "100%";
  iframe.style.height = "100%";
  iframe.frameBorder  = "0";
  iframe.className = this.className + "-menu-innerbody";

  elm.appendChild(iframe);
}

BoxMenu.prototype.showMenu = function(menuId) {
  if (this.activeMenuId != null && this.activeMenuId == menuId) {
    return true;
  }

  if (this.activeMenuId != null) {
    this.collapseMenu(this.activeMenuId);
  }
  this.activeMenuId = menuId;
  this.expandMenu(menuId);
}

BoxMenu.prototype.expandMenu = function(menuId, aniDone) {
  if (this._aniHeight == null) {
    this._aniHeight = new Array();
  }

  var mItemDiv = document.getElementById("menuTd_" + menuId + "_div");
  if (mItemDiv.BoxMenuItemActiveIcon != null) {
    mItemDiv.style.backgroundImage = "url('" + mItemDiv.BoxMenuItemActiveIcon + "')";
  }

  var bodyElm = this.doc.getElementById("bodyTr_" + menuId);
  if (this.animateMenu && aniDone == null) {
    bodyElm.style.display = "";
    this._aniHeight[menuId] = bodyElm.offsetHeight;
    bodyElm.firstChild.firstChild.style.display = "none";
    bodyElm.style.height = 0;
    aniDone = false;
  }
  if ( this.animateMenu && aniDone == false && parseInt(bodyElm.style.height) < this._aniHeight[menuId]) {
    window.status = bodyElm.style.height + " " + bodyElm.offsetHeight + " " + (parseInt(bodyElm.offsetHeight) + _aniStep);
    bodyElm.style.height = (parseInt(bodyElm.style.height) + _aniStep) + "px";
    bodyElm.firstChild.style.height = (parseInt(bodyElm.style.height) + _aniStep) + "px";
    var data = menuId.split("_");
    if (this.activeMenuId == menuId) {
      setTimeout("_boxMenus['" + data[0] + "'].expandMenu('" + menuId + "',false)", 10);
    }
    else {
      this.collapseMenu(menuId);
    }
    return;
  }
  
  this.doc.getElementById("menuTd_" + menuId).className = this.className + "-menu-item " + this.className + "-menu-item-active";
  bodyElm.style.display = "";
  bodyElm.firstChild.firstChild.style.display = "";        
}

BoxMenu.prototype.collapseMenu = function (menuId,aniDone) {
  if (this._aniHeight == null) {
    this._aniHeight = new Array();
  }
  
  var bodyElm = this.doc.getElementById("bodyTr_" + menuId);
  if (this.animateMenu && aniDone == null) {
    bodyElm.firstChild.firstChild.style.display = "none";        
    aniDone = false;
  }

  if ( this.animateMenu && aniDone == false && parseInt(bodyElm.style.height) > _aniStep) {
    bodyElm.style.height = (parseInt(bodyElm.style.height) - _aniStep) + "px";
    bodyElm.firstChild.style.height = (parseInt(bodyElm.style.height) + _aniStep) + "px";
    var data = menuId.split("_");
    setTimeout("_boxMenus['" + data[0] + "'].collapseMenu('" + menuId + "', false)", 5);
    return;
  }

  var mItemDiv = document.getElementById("menuTd_" + menuId + "_div");
  if (mItemDiv.BoxMenuItemIcon != null) {
    mItemDiv.style.backgroundImage = "url('" + mItemDiv.BoxMenuItemIcon + "')";
  }

  bodyElm.style.display = "none";
  bodyElm.firstChild.firstChild.style.display = "";        
  this.doc.getElementById("menuTd_" + menuId).className = this.className + "-menu-item";
}

BoxMenu.prototype.menuItemChangeClass = function(menuId, eventType) {
  if (eventType == 'mouseover') {
    this.doc.getElementById("menuTd_" + menuId).className = this.className + "-menu-item " + this.className + "-menu-item-hover";
  }
  else {
    if (this.activeMenuId != null && this.activeMenuId == menuId) {
      this.doc.getElementById("menuTd_" + menuId).className = this.className + "-menu-item " + this.className + "-menu-item-active";
    }
    else {
      this.doc.getElementById("menuTd_" + menuId).className = this.className + "-menu-item";
    }
  }
  window.status = menuId + " " + eventType;
}

_chgClass = function(menuId, eventType) {
  var data = menuId.split("_");
  _boxMenus[ data[1] ].menuItemChangeClass( data[1] + "_" + data[2], eventType );
}

_BoxMenuShowMenu = function(menuId) {
  var data = menuId.split("_");
  window.status = data[1] + " show";
  _boxMenus[ data[1] ].showMenu( data[1] + "_" + data[2] );
}

BoxMenu.prototype.handleClick = function(e) {
  if (e == null) {
    _BoxMenuShowMenu(event.srcElement.id);
    return;
  }
  window.status = "click:" + e.target.id;
  _BoxMenuShowMenu(e.target.id);
}

BoxMenu.prototype.onHover = function(e) {
  if (e == null) {
    _chgClass(event.srcElement.id, event.type);
    return;
  }
  _chgClass(e.target.id, e.type);
}
