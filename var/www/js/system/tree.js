var AUTO_SCROLL_INCREMENT = 10;  // Pixels
var AUTO_SCROLL_TIMEOUT   = 50;  // Milliseconds
var SCROLL_UP_TIMER;
var SCROLL_DOWN_TIMER;

function autoScrollUp(event) {
  autoScroll("up");
  SCROLL_UP_TIMER = setTimeout("autoScrollUp();", AUTO_SCROLL_TIMEOUT);
}
function autoScrollDown(event) {
  autoScroll("down");
  SCROLL_DOWN_TIMER = setTimeout("autoScrollDown();", AUTO_SCROLL_TIMEOUT);
}


function autoScroll(direction) {
  cancelAutoScroll();
  var offset = _getScrollAmount('y');
  var increment = direction === "up" ? -AUTO_SCROLL_INCREMENT : AUTO_SCROLL_INCREMENT;
  document.getElementById("documentsDiv").scrollTop += increment;
  var deltaOffset = _getScrollAmount('y') - offset;
  if (deltaOffset === 0) {
    // We have scrolled all the way up/down
    document.getElementById("bottom").style.zIndex = direction === "up" ?  1 : -1;
    document.getElementById("top").style.zIndex    = direction === "up" ? -1 :  1;
  }
  else {
    // Must be able to scroll both ways
    document.getElementById("bottom").style.zIndex = 1;
    document.getElementById("top").style.zIndex    = 1;
  }
}

function _getScrollAmount(direction) { // 0 means document is scrolled to the top
  var elm = document.getElementById("documentsDiv");
  if (direction === "y") {
    return elm.scrollTop || 0;
  }
  return elm.scrollLeft || 0;
}

function cancelAutoScroll() {
  clearTimeout(SCROLL_UP_TIMER);
  clearTimeout(SCROLL_DOWN_TIMER);
}

function initTree() {
  var tree = getComponentById('tree');

  if (EXPAND_FOLDERS.length > 0) {
    tree.expandFolders(EXPAND_FOLDERS);
  }
}

function reloadTree() {
  var tree = getComponentById('tree');
  var folderCodes = tree.listExpandedFolderIds();
  document.forms.reloadForm.expandFolders.value = folderCodes.join(',');
  document.forms.reloadForm.submit();
}

function rememberTree() {
  var tree = getComponentById('tree');
  var folderCodes = tree.listExpandedFolderIds();
  o2.ajax.call({
    setDispatcherPath : "o2cms",
    setClass          : "System-Tree",
    setMethod         : "rememberTree",
    setParams         : "expandFolders=" + o2.escape.escape( folderCodes.join(',') ),
    onSuccess         : "top.displayMessage('" + top.o2.lang.getString("o2.desktop.msgTreeRemembered") + "');",
    method            : "post"
  });
}

function hidePopupMenu() {
  if (top.middleFrame.treeContextMenu != null) {
    top.middleFrame.treeContextMenu.hideMenu(true);
  }
  if (top.middleFrame.startMenu) {
    top.middleFrame.startMenu.hideMenu(true, false, true);
  }
}

function openContextMenuForSearchItem(e, className, id, metaName) {
  var evt = new top.O2Event(this, e);
  if (evt.getButton() == 2) {
    setTimeout("top.middleFrame.showSearchResultPropertiesMenu({className:'" + className + "', id:" + id + ", x:" + evt.getX() + ", y:" + evt.getY() + ", metaName:'" + metaName + "'}, false);", 200);
  }
}

function openContextMenu(e, className, id, folderCode, isFolder, isWebCategory, metaName) {
  var evt = new top.O2Event(this, e);
  
  var tree = getComponentById("tree");
  var ids = folderCode.split(".");
  var topId = ids[1];
  var topObject = tree.getDragDataById(topId);
  
  if (evt.getButton() != 2) {
    return;
  }
  
  currentItem = {
    className     : className,
    id            : id,
    x             : evt.getX(),
    y             : evt.getY(),
    isFolder      : isFolder,
    isWebCategory : isWebCategory,
    metaName      : metaName
  };
  if (topObject.className === "O2CMS::Obj::Trashcan"  &&  className !== "O2CMS::Obj::Trashcan") {
    if (isFolder) {
      // valid folderCode is like .1234.2345
      if (!folderCode.match(/^[.]\d+[.]\d+$/)) {
        return;
      }
    }
    else {
      // valid folderCode is like .1234
      if (!folderCode.match(/^[.]\d+$/)) {
        return;
      }
    }
    var parentId = folderCode.substr(1);
    if (parentId.indexOf(".") != -1) {
      parentId = parentId.substr(0, parentId.indexOf("."));
    }
    setTimeout("top.middleFrame.showPropertiesMenu({className:'" + className + "', id:" + id + ", parentId:" + parentId + ", x:" + evt.getX() + ", y:" + evt.getY() + ", isFolder:" + isFolder + ", isWebCategory:" + false + ", metaName:'" + metaName + "'}, null, true);", 200);
    currentItem = null;
  }
  else if (topObject.className === "O2CMS::Obj::Trashcan"  &&  className === "O2CMS::Obj::Trashcan") {
    setTimeout("top.middleFrame.showPropertiesMenu({className:'" + className + "', id:" + id + ", x:" + evt.getX() + ", y:" + evt.getY() + ", isFolder:" + isFolder + ", isWebCategory:" + false + ", metaName:'" + metaName + "'}, null, true);", 200);
  }
  else if (isFolder) {
    o2.ajax.call({
      setClass  : "System-Class",
      setMethod : "getCanContainClasses",
      setParams : { objectId : id },
      handler   : "setNewList"
    });
  }
  else {
    setTimeout("top.middleFrame.showPropertiesMenu({className:'" + className + "', id:" + id + ", x:" + evt.getX() + ", y:" + evt.getY() + ", isFolder:" + isFolder + ", isWebCategory:" + isWebCategory + ", metaName:'" + metaName + "'}, null, false);", 200);
    currentItem = null;
  }
}

function setNewList(params) {
  top.middleFrame.showPropertiesMenu(currentItem, params);
  currentItem = null;
}

function openItem() {
  if (currentItem) {
    top.openObject(currentItem.className, currentItem.id);
  }
}

function restoreFromTrash(id, parentId, callback) {
  window.restoreFromTrashCallback = callback;
  o2.ajax.call({
    setClass  : "System-Tree",
    setMethod : "restoreFromTrash",
    setParams : { objectId : id, trashcanId : parentId },
    handler   : "restoreFromTrashHandler",
    method    : "post"
  });
}

function restoreFromTrashHandler(params) {
  top.reloadTreeFolders(params.trashcanId, params.restoredInFolderId);
  if (restoreFromTrashCallback) {
    restoreFromTrashCallback.call(this);
    restoreFromTrashCallback = null;
  }
}

function emptyTrash(trashcanId, callback) {
  window.emptyTrashCallback = callback;
  o2.ajax.call({
    setClass  : "System-Tree",
    setMethod : "emptyTrash",
    setParams : { trashcanId : trashcanId },
    handler   : "emptyTrashHandler",
    method    : "post"
  });
}

function emptyTrashHandler(params) {
  top.reloadTreeFolder(params.trashcanId);
  o2.ajax.alert( top.o2.lang.getString("o2.desktop.msgTrashEmptied"), "", "info" );
  if (emptyTrashCallback) {
    emptyTrashCallback.call(this);
    emptyTrashCallback = null;
  }
}
