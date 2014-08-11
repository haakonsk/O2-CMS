o2.require("/js/DOMUtil.js");

o2.addLoadEvent(initSlider);

function initSlider() {
  // Create invisible element to "hide" iframes so dragging experience becomes much better
  var newDiv = document.createElement("div");
  newDiv.setAttribute("id", "bigDiv");
  document.body.appendChild(newDiv);

  // Create invisible element to click on to drag
  var dragDiv = document.createElement("div");
  dragDiv.setAttribute("id", "dragDiv");
  dragDiv.style.left = (o2.getComputedStyle(document.getElementById("leftColumn"), "width") - 4)  +  "px";
  document.body.appendChild(dragDiv);

  o2.addEvent( document.getElementById("dragDiv"), "mousedown", initMoveSlider );
}

function initMoveSlider(e) {
  document.getElementById("bigDiv").style.zIndex = 10;
  o2.addEvent( document, "mousemove", moveSlider    );
  o2.addEvent( document, "mouseup",   endMoveSlider );
  e.preventDefault();
}

function moveSlider(e) {
  var elm = e.getTarget();
  document.getElementById("leftColumn").style.width =  e.getX()      + "px";
  document.getElementById("dragDiv").style.left     = (e.getX() - 4) + "px";
  e.preventDefault();
}

function endMoveSlider(e) {
  o2.removeEvent( document, "mousemove", moveSlider    );
  o2.removeEvent( document, "mouseup",   endMoveSlider );
  document.getElementById("bigDiv").style.zIndex = -1;
  oldColWidth = document.getElementById("leftColumn").style.width;
  e.preventDefault();
}


function toggleMenu() {
  startMenu.toggleMenu();
}


/**
    This is the code to hide/show the menuPane
  */

var oldColWidth = null;

function toggleMenuFrame(forceShow) {
  var lCol = document.getElementById("leftColumn");
  var iFra = document.getElementById("left");
  var rCol = document.getElementById("rightColumn");

  if (forceShow == null) {
    forceShow = false;
  }

  var toggleButton = document.getElementById("toggleButton");
  if (toggleButton == null) {
    toggleButton    = document.createElement("div");
    toggleButton.id = "toggleButton";
    document.body.appendChild(toggleButton);
    toggleButton.style.height           = "20px";
    toggleButton.style.width            = "20px";
    toggleButton.style.backgroundImage  = "url('/images/system/forwd_16.gif')";
    toggleButton.style.backgroundRepeat = "no-repeat";
    toggleButton.style.position         = "absolute";
    toggleButton.style.top              = "0px";
    toggleButton.style.zIndex           = "1";
    toggleButton.onmousedown = showMenuPane;
  }

  if (oldColWidth != null && ( lCol.width == 0 || forceShow == true )) {
    lCol.style.width  = oldColWidth;
    iFra.style.width  = "100%";
    rCol.style.width  = "";
    oldColWidth = null;
    toggleButton.style.visibility = "hidden";
  }
  else if (lCol.width > 0 && forceShow == false) {
    oldColWidth = lCol.style.width;
    lCol.style.width  = 0;
    iFra.style.width  = 0;
    rCol.style.width  = "100%";
    toggleButton.style.visibility = "visible";
  }
}


function isMenuPaneShowing() {
  return (oldColWidth == null);
}

function showMenuPane() {
  if (isMenuPaneShowing()) {
    return;
  }
  toggleMenuFrame(true);
}


function registerMouse() {
  document.onmousemove = test;
  document.getElementById("test").value = "ok";
}

function unregisterMouse() {
}

function resizeFrame(xPos) {
}

//-----------------------------------------------------------------------------
// DialogWindows API - Nils 
// Comment: API methods are located in the top Frame
//-----------------------------------------------------------------------------

var ___currCallBackMethods = new Array();
function showConfirmBox(question, callBack, properties) {
  if (!callBack) {
    return top.errorBox("No callBack method provided to confirmBox!");
  }
  ___currCallBackMethods.confirmBox = callBack;
  o2.popupDialog.display("confirmBox");
  document.getElementById("confirmBoxText").innerHTML = question;

  if (properties) {
    if (properties.title) {
      confirmBox.setTitle(properties.title);
    }
    if (properties.icon) {
      document.getElementById("confirmBoxIconCell").style.backgroundImage = "url('" + properties.icon + "')";
    }
  }
  document.getElementById("confirmBoxYesBtn").focus(); // Hitting return means yes
  return;
}

function confirmBoxAnswer(boolAnswer) {
  o2.popupDialog.hide();
  try {
    if (typeof(___currCallBackMethods.confirmBox) === "string") {
      eval(___currCallBackMethods.confirmBox + '(' + (boolAnswer ? 'true' : 'false') + ')');
    }
    else {
      boolAnswer = boolAnswer ? true : false;
      ___currCallBackMethods.confirmBox.call(this, boolAnswer);
    }
  }
  catch (e) {
    alert( "QuextionBox error: Could not call back method '" + ___currCallBackMethods.confirmBox + "\nError: " + o2.getExceptionMessage(e) );
  }
}

function showMessageBox(messageText, properties, callBack) {
  ___currCallBackMethods.messageBox = callBack ? callBack : null;

  o2.popupDialog.display("messageBox");

  document.getElementById("messageBoxText").innerHTML = messageText;
  document.getElementById("messageBoxIconCell").className = properties && properties.className  ?  properties.className  :  "messageBoxIconCell";

  // messageBox.setTitle( properties && properties.title  ?  properties.title  :  "Message" );

  if (properties && properties.icon) {
    document.getElementById("messageBoxIconCell").style.backgroundImage = "url('" + properties.icon + "')";
  }

  document.getElementById("messageBoxOkBtnLink").focus();
  document.getElementById("messageBox").scrollTop  = 0;
  document.getElementById("messageBox").scrollLeft = 0;
}

function messageBoxAnswer() {
  o2.popupDialog.hide();
  if (___currCallBackMethods.messageBox) {
    try {
      eval(___currCallBackMethods.messageBox + ";");
    }
    catch(e) {
      alert( "MessageBox error: Could not call back method '" + ___currCallBackMethods.messageBox + "'" );
    }
  }
}

function showErrorBox(errorText, properties, callBack) {
  if (!properties) {
    properties = new Object();
  }
  if (!properties.icon) {
    o2.addClassName(properties, "errorBoxIconCell");
  }
  showMessageBox(errorText, properties, callBack);
}

function showPropertiesDialog(objectId) {
  if (!objectId) {
    alert("System error: objectId not provided in showPropertiesDialog");
  }
  o2.popupDialog.display("propertiesDialog");
  document.getElementById("propertiesDialogIframe").src = "/o2cms/System-Properties/?objectId=" + objectId;
}


// Added by nilschd 20061003, this section contains the logic for the generic revision manager 
/* generic revision manager API
    - showRevisionDialog(objectId,callBackWindow)
    - preRestore               : called before a restore is done
    - onRestore                : called when restore is done.
  */


var __callBackWindow = null;

function showRevisionDialog(objectId, callBackWindow) {
  if (!objectId) {
    alert("system error missing objectId ");
    return false;     
  }

  o2.popupDialog.display("revisionDialog");
  document.getElementById("revisionDialogIframe").src = o2.urlMod.urlMod({
    setClass  : "Revision-Manager",
    setMethod : "init",
    setParams : "objectId=" + objectId
  })
  if (callBackWindow) {
    __callBackWindow = callBackWindow;
    setTimeout("__setCallBackWindow()", 100); //doing this to make sure that we are able to set it (slow load times etc..)
  }
}

//we need to keep trying setting this callback window ref
//till the iframe content is loaded
function __setCallBackWindow() {
  if (!__callBackWindow) {
    return;
  }

  try {
    var ifr = revisionDialog.getIframe();
    window.frames[ifr.id].callPreRestoreFunction(__callBackWindow);
  }
  catch (e) {
    setTimeout("__setCallBackWindow()", 200);
    return;
  }
  __callBackWindow = null;
}

function restoreDone(objectId) {
  document.getElementById("revisionDialogIframe").src = "about:blank";
  o2.popupDialog.hide();
  top.reloadTree();
}


// Proxy method for the inline (which is defined in this template) popupMenu showRevision
function _showRevisionProxyMethod(objectId) {
  showRevisionDialog(objectId, this);
}
// end generic revision manager

function showKeywordDialog(objectId) {
  o2.popupDialog.display("keywordDialog");
  document.getElementById("keywordDialogIframe").src = o2.urlMod.urlMod({
    setClass  : "Keyword-KeywordEditor",
    setMethod : "init",
    setParams : "objectId=" + objectId
  });
}
//-----------------------------------------------------------------------------
// End DialogWindows API - Nils 
//-----------------------------------------------------------------------------



function setLeftColumnWidth(width) {
  document.getElementById("leftColumn").style.width = width + "px";
}



function setSortMethod(folderId, method, direction) {
  o2.ajax.call({
    setClass  : "System-Tree",
    setMethod : "setSortMethod",
    setParams : "folderId=" + folderId + "&method=" + method + "&direction=" + direction,
    onSuccess : "top.reloadTreeFolder(" + folderId + ");",
    method    : "post"
  });
}

/*
    Code for the popupMenu when right clicking on menu items in the tree, this code is 
    co-operating with the code in tree.html
  */
var treeContextMenu = null;
var taskBarMenu = null;

function showSearchResultPropertiesMenu(currentTreeItem, isTrash, contextMenuElement) {
  if (treeContextMenu) {
    treeContextMenu.flush();
  }
  treeContextMenu = new DOMPopupMenu(contextMenuElement);
  var contextMenu_1 = treeContextMenu.addMenuItem([top.o2.lang.getString("o2.desktop.treeContextMenu.open"), "/images/system/classIcons/O2-Obj-Class.gif"],
    "top.openObject('" + currentTreeItem.className + "'," + currentTreeItem.id + ");");
  var contextMenu_properties = treeContextMenu.addMenuItem( [top.o2.lang.getString("o2.desktop.treeContextMenu.properties"),     "/images/system/addrecord_16.gif"], "top.showPropertiesDialog(" + currentTreeItem.id + ");" );
  treeContextMenu.showMenu(currentTreeItem.y+20, currentTreeItem.x);
}

function showPropertiesMenu(currentTreeItem, newList, isTrash, contextMenuElement) {
  if (treeContextMenu) {
    treeContextMenu.flush();
  }
  treeContextMenu = new DOMPopupMenu(contextMenuElement);
  if (isTrash  &&  currentTreeItem.className == "O2CMS::Obj::Trashcan") {
    var contextMenuEmptyTrash = treeContextMenu.addMenuItem(
      [top.o2.lang.getString("o2.desktop.treeContextMenu.emptyTrash"), "/images/system/classIcons/O2CMS-Obj-Trashcan.gif"],
      "top.frames.middleFrame.frames.left.emptyTrash(" + currentTreeItem.id + ");"
    );
  }
  else if (isTrash) {
    var contextMenuRestore = treeContextMenu.addMenuItem(
      [top.o2.lang.getString("o2.desktop.treeContextMenu.restore"), "/images/system/up_16.gif"],
      "top.frames.middleFrame.frames.left.restoreFromTrash(" + currentTreeItem.id + ", " + currentTreeItem.parentId + ");"
    );
    treeContextMenu.showMenu(currentTreeItem.y+20, currentTreeItem.x);
    return;
  }

  var contextMenu_1 = treeContextMenu.addMenuItem([top.o2.lang.getString("o2.desktop.treeContextMenu.open"), "/images/system/classIcons/O2-Obj-Class.gif"],
    "top.openObject('" + currentTreeItem.className + "'," + currentTreeItem.id + ");");
  if (newList != null) {
    var contextMenuNewItem = treeContextMenu.addMenuItem([top.o2.lang.getString("o2.desktop.treeContextMenu.new"), "/images/system/classIcons/O2-Obj-Class.gif"]);
    var didAddNewItem = false;
    for (var elm in newList.classNames) {
        didAddNewItem = true;
        var name   = newList.classNames[elm].metaName.split("::");
        var dragId = "newAction::" + newList.classNames[elm].className + "::" + currentTreeItem.id;
        var action = "top.newObject('" + newList.classNames[elm].className + "'," + currentTreeItem.id + ");";

        if ( newList.classNames[elm].className == "O2::Obj::File" ) {
          // ADD NEW MULTI UPLOAD HERE?
        }

        contextMenuNewItem.addMenuItem(
          [ name[name.length-1], top.getIconUrl(newList.classNames[elm].className)],
          action,
          null,
          null,
          dragId
        );
    }
    if (!didAddNewItem) {
      contextMenuNewItem.addMenuItem([top.o2.lang.getString("o2.desktop.treeContextMenu.notPermitted"), "/images/system/cancl_16.gif"]);
    }
    treeContextMenu.addSeperator();
  }
  var contextMenu_properties = treeContextMenu.addMenuItem( [top.o2.lang.getString("o2.desktop.treeContextMenu.properties"),     "/images/system/addrecord_16.gif"], "top.showPropertiesDialog(" + currentTreeItem.id + ");" );
                               treeContextMenu.addMenuItem( [top.o2.lang.getString("o2.desktop.treeContextMenu.propertyEditor"), "/images/system/addrecord_16.gif"], "top.showPropertyEditor("   + currentTreeItem.id + ");" );
  var contextMenu_revision   = treeContextMenu.addMenuItem( [top.o2.lang.getString("o2.desktop.treeContextMenu.revisions"),      "/images/system/addrecord_16.gif"], "_showRevisionProxyMethod(" + currentTreeItem.id + ");" );
  var contextMenu_keywords   = treeContextMenu.addMenuItem( [top.o2.lang.getString("o2.desktop.treeContextMenu.keywords"),       "/images/system/addrecord_16.gif"], "top.showKeywordDialog("    + currentTreeItem.id + ");" );
  treeContextMenu.addSeperator();
  var contextMenu_3 = treeContextMenu.addMenuItem( [top.o2.lang.getString("o2.desktop.treeContextMenu.reloadFolder"), "/images/system/ref_16.gif"], "top.reloadTreeFolder(" + currentTreeItem.id + ");" );
  var contextMenu_4 = treeContextMenu.addMenuItem( [top.o2.lang.getString("o2.desktop.treeContextMenu.reloadTree"),   "/images/system/ref_16.gif"], "top.reloadTree();"                                 );
  if (currentTreeItem.isFolder) {
    var contextMenu_sort = treeContextMenu.addMenuItem([top.o2.lang.getString("o2.desktop.treeContextMenu.sortBy"),    "/images/system/sortbyname_16.gif"]);
    contextMenu_sort.addMenuItem( [top.o2.lang.getString("o2.desktop.treeContextMenu.sortAlphabeticalAsc"),  "/images/system/sortbyname_16.gif"], "setSortMethod(" + currentTreeItem.id + ", 'alphabetical', 'asc');"  );
    contextMenu_sort.addMenuItem( [top.o2.lang.getString("o2.desktop.treeContextMenu.sortAlphabeticalDesc"), "/images/system/sortbyname_16.gif"], "setSortMethod(" + currentTreeItem.id + ", 'alphabetical', 'desc');" );
    contextMenu_sort.addMenuItem( [top.o2.lang.getString("o2.desktop.treeContextMenu.sortByChangeTimeAsc"),  "/images/system/sortbydate_16.gif"], "setSortMethod(" + currentTreeItem.id + ", 'changeTime',   'asc');"  );
    contextMenu_sort.addMenuItem( [top.o2.lang.getString("o2.desktop.treeContextMenu.sortByChangeTimeDesc"), "/images/system/sortbydate_16.gif"], "setSortMethod(" + currentTreeItem.id + ", 'changeTime',   'desc');" );
    contextMenu_sort.addMenuItem( [top.o2.lang.getString("o2.desktop.treeContextMenu.sortByCreateTimeAsc"),  "/images/system/sortbydate_16.gif"], "setSortMethod(" + currentTreeItem.id + ", 'createTime',   'asc');"  );
    contextMenu_sort.addMenuItem( [top.o2.lang.getString("o2.desktop.treeContextMenu.sortByCreateTimeDesc"), "/images/system/sortbydate_16.gif"], "setSortMethod(" + currentTreeItem.id + ", 'createTime',   'desc');" );
  }
  if (!isTrash) {
    treeContextMenu.addSeperator();
    var trashcanId = top.getTrashcanId();
    var contextMenu_moveToTrash
      = treeContextMenu.addMenuItem( [top.o2.lang.getString("o2.desktop.treeContextMenu.moveToTrash"), "/images/system/classIcons/O2CMS-Obj-Trashcan.gif"], "if (confirm(top.o2.lang.getString('o2.Category.Manager.questionConfirmDeleteOne'))) { top.moveObject(" + currentTreeItem.id + ", " + trashcanId + "); }" );
  }
  if (currentTreeItem.isWebCategory) {
    var contextMenu_publisherSettings = treeContextMenu.addMenuItem(
      [top.o2.lang.getString("o2.desktop.treeContextMenu.publisherSettings"), "/images/system/confg_16.gif"],
      "top.openInFrame('/o2cms/Category-PublisherSettings/edit?categoryId=" + currentTreeItem.id + "', top.getIconUrl('" + currentTreeItem.className + "'), '" + o2.lang.getString("o2.Category.PublisherSettings.frameTitle") + " " + currentTreeItem.metaName + "');"
    );
  }
  if (currentTreeItem.className == "O2CMS::Obj::Site") {
    var contextMenu_linkChecker = treeContextMenu.addMenuItem(
      [top.o2.lang.getString("o2.desktop.treeContextMenu.checkForBrokenLinks"), "/images/system/find_16.gif"],
      "top.openInFrame('/o2cms/Site-LinkChecker?siteId=" + currentTreeItem.id + "', top.getIconUrl('" + currentTreeItem.className + "'), '" + o2.lang.getString("o2.Site.LinkChecker.frameTitleShort") + "');"
    );
  }

  treeContextMenu.showMenu(currentTreeItem.y+20, currentTreeItem.x);
}

function showTaskBarMenu(data) {
  if (taskBarMenu != null) {
    taskBarMenu.flush();
  }
  //is it a frame or a popupwindow?
  var topAction = "closeFrameId";
  if ( data.frameId && data.frameId.length > 2 ) {
    topAction = "windowClosing";
  }

  taskBarMenu = new DOMMenu("taskBarMenu", null, "down");
  taskBarMenu.addMenuItem( [top.o2.lang.getString("o2.desktop.lblCloseWindow"), "/images/system/close_16.gif"], "top." + topAction + "('" + data.frameId + "');");
  var h = top.o2.getWindowHeight(this.window);
  taskBarMenu.showMenu(h-20, data.x-50);
}
