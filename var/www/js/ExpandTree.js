ExpandTree.prototype = new Tree();
ExpandTree.superclass = Tree.prototype;
ExpandTree.prototype.constructor = ExpandTree;

function ExpandTree(componentId) {
  this.id = componentId;
  this.loaded = {}; // folders already loaded
  initDragContainer(document.getElementById(componentId));
}


ExpandTree.prototype.expandFolderHandler = function(args) {
  var folderCode        = args.folderCode || null;
  var fileItems         = args.fileItems;
  var replaceFolderHtml = args.numSkipped == 0;
  this.loaded[folderCode] = true;

  var folderContentElm = document.getElementById(this.id + "_c" + folderCode);
  if (folderContentElm && replaceFolderHtml) {
    folderContentElm.innerHTML = '';
  }
  else if (args.numSkipped > 0) {
    var loadMoreLinkElm = folderContentElm.childNodes[ folderContentElm.childNodes.length-1 ];
    folderContentElm.removeChild(loadMoreLinkElm);
  }

  var dontInsertNode = navigator.appName != "Microsoft Internet Explorer";
  var htmlToAdd = "";
  for (var i = 0; i < fileItems.length; i++) {
    if (fileItems[i].isContainer == 1) {
      htmlToAdd += this.addFolder(folderCode, fileItems[i], dontInsertNode);
    }
    else if (fileItems[i].isAddMoreLink) {
      var text = "<a href='javascript: getComponentById(\"" + this.id + "\").loadMoreItems(\"" + folderCode + "\");'> ... " + fileItems[i].name + "</a>";
      htmlToAdd += ExpandTree.superclass.addFile.call(this, folderCode, text, dontInsertNode, replaceFolderHtml)
    }
    else {
      htmlToAdd += this.addFile(folderCode, fileItems[i], dontInsertNode, replaceFolderHtml);
    }
  }
  if (dontInsertNode) {
    var parentElmId = !folderCode ? this.id : this.id + "_c" + folderCode; // top or sub-folder?
    var parentElm = document.getElementById(parentElmId);
    if (replaceFolderHtml) {
      parentElm.innerHTML = htmlToAdd;
    }
    else {
      parentElm.innerHTML += htmlToAdd;
    }
  }
}

ExpandTree.prototype.loadMoreItems = function(folderCode) {
  var numItemsLoaded = document.getElementById( this.id + "_c" + folderCode ).childNodes.length - 1; // Don't count the loadMoreItems link
  o2.ajax.call({
    setDispatcherPath : "o2cms",
    setClass          : "System-Tree",
    setMethod         : "expandFolder",
    setParams         : { folderCode : folderCode, numItemsLoaded : numItemsLoaded },
    handler           : "getComponentById('" + this.id + "').expandFolderHandler"
  });
}

ExpandTree.prototype.expand = function(folderCode) {
  if (folderCode) { // do not expand anything for the top level objects
    ExpandTree.superclass.expand.call(this, folderCode);
  }
  if ( !this.loaded[folderCode] ) {
    var folderContentElm = document.getElementById(this.id + "_c" + folderCode);
    var folderLevel = o2.split(/\./, folderCode).length;
    var indent = "";
    for (var i = 0; i < folderLevel; i++) {
      indent += "<img src='/images/system/tree/vertline.gif'>";
    }
    folderContentElm.innerHTML = indent + "<img src='/images/system/ajaxLoaders/indicator_bg_ffffff_fg_bababa.gif'>";
    o2.ajax.call({
      setDispatcherPath : "o2cms",
      setClass          : "System-Tree",
      setMethod         : "expandFolder",
      setParams         : { folderCode : folderCode },
      handler           : "getComponentById('" + this.id + "').expandFolderHandler",
      errorHandler      : "getComponentById('" + this.id + "').stopLoading"
    });
  }
}

ExpandTree.prototype.stopLoading = function(params) {
  if (params.errorMsg) {
    o2.ajax.alert(params.errorMsg, params.errorHeader, "error");
  }
  var folderCode = params.folderCode;
  var folderContentElm = document.getElementById(this.id + "_c" + folderCode);
  folderContentElm.innerHTML = "";  
}

ExpandTree.prototype.multiMove = function(fileIds, toFolderId, callBackFunction) {
  this.moveHandlerCallback = callBackFunction;
  o2.ajax.call({
    setDispatcherPath : "o2cms",
    setClass          : "System-Tree",
    setMethod         : "move",
    setParams         : "fileIds=" + fileIds.join(",") + "&toFolderId=" + toFolderId,
    handler           : "getComponentById('" + this.id + "').moveHandler",
    method            : "post"
  });
}

ExpandTree.prototype.move = function(fileId, toFolderId) {
  this.multiMove([fileId], toFolderId);
}

ExpandTree.prototype.moveHandler = function(args) {
  this.reloadFolders( [args.toFolderId, args.fromFolderId] );
  if (this.moveHandlerCallback) {
    try {
      eval( this.moveHandlerCallback );
    }
    catch (e) {
      top.displayError("moveHandler: Could not eval '" + this.moveHandlerCallback + "': " + o2.getExceptionMessage(e));
    }
    this.moveHandlerCallback = null;
  }
  if (args.errorMessages) {
    top.displayError(args.errorMessages);
  }
}

ExpandTree.prototype.moveObject = function(objectId, containerId, callBackFunction) {
  this.moveHandlerCallback = callBackFunction;
  this.move(objectId, containerId);
}

ExpandTree.prototype.addFolder = function(parentFolderCode, folderItem, dontInsertNode) {
  this.updateTrashedFolders(parentFolderCode, folderItem);
  var itemName        = folderItem.name.toString();
  var itemNameEscaped = itemName.replace(/\'/g, '&amp;apos;');
  itemNameEscaped     = itemNameEscaped.replace(/\"/g, '&amp;quot;');
  var text = '<span onmousedown="openContextMenu(event,\''+folderItem.className+'\',\''+folderItem.id+'\',\''+folderItem.folderCode+'\',true,\''+folderItem.isWebCategory+'\',\''+itemNameEscaped+'\')"'
    + ' dropid="' +folderItem.id+'"><img src="'+folderItem.iconUrl+'" dragid="'+folderItem.id+'" style="vertical-align:middle;">'
    + '&nbsp;<a href="javascript:top.openObject(\''+folderItem.className+'\',\''+folderItem.id+'\',\''+itemNameEscaped+'\')"> '+folderItem.name+'</a></span>';
  var html = ExpandTree.superclass.addFolder.call(this,parentFolderCode, folderItem.folderCode, text, dontInsertNode);
  // register folder element id (and keep existing in case of symlinks etc)
  folderItem.folderIds = this.items[folderItem.id] ? this.items[folderItem.id].folderIds : {};
  folderItem.folderIds[folderItem.folderCode] = 1;
  this.items[folderItem.id] = folderItem;
  return html;
}

ExpandTree.prototype.updateTrashedFolders = function(folderCode, item) {
  var parentId = "";
  if (folderCode) {
    var parentId = folderCode.substring( folderCode.lastIndexOf(".")+1 );
  }
  if (!this.trashedFolders) {
    this.trashedFolders = new Array();
  }
  if (parentId == top.getTrashcanId()  ||  this.trashedFolders[parentId]) {
    this.trashedFolders[item.id] = true;
  }
}

ExpandTree.prototype.isTrashed = function(folderCode) {
  if (!this.trashedFolders) {
    return false;
  }
  var parentId = folderCode.substring( folderCode.lastIndexOf(".")+1 );
  return this.trashedFolders[parentId] ? true : false;
}

function showPreviewImage(imageUrl) {
  var elm = document.getElementById('imagePreview');
  elm.src = imageUrl;
  elm.style.display = 'block';
}
function hidePreviewImage() {
  document.getElementById('imagePreview').style.display = 'none';
}

ExpandTree.prototype.addFile = function(folderCode, fileItem, dontInsertNode) {
  var itemName        = fileItem.name.toString();
  var itemNameEscaped = itemName.replace(/\'/g, '&amp;apos;');
  itemNameEscaped     = itemNameEscaped.replace(/\"/g, '&amp;quot;');
  var attr = '';
  if (fileItem.imagePreviewUrl) {
    attr = 'onmouseover="showPreviewImage(\''+fileItem.imagePreviewUrl+'\')" onmouseout="hidePreviewImage()" ';
  }

  var text = '<span '+attr+'onmousedown="openContextMenu(event,\''+fileItem.className+'\',\''+fileItem.id+'\', \''+folderCode+'\', false)"  dropid="'+fileItem.id+'"><img src="'+fileItem.iconUrl+'" dragid="'+fileItem.id+'">';
  text    += '<a href="javascript:top.openObject(\''+fileItem.className+'\',\''+fileItem.id+'\',\''+itemNameEscaped+'\', ' + this.isTrashed(folderCode) + ')"> ';
  text    += fileItem.name+'</a></span>';
  var html = ExpandTree.superclass.addFile.call(this, folderCode, text, dontInsertNode);
  this.items[fileItem.id] = fileItem;
  return html;
}


// init a reload of multiple folders.
// sorts folderCodes by number of dots. This will prevent a folder reload from clearing the content of a previously reloaded folder.
ExpandTree.prototype._setReloadFolderQueue = function(folderCodes) {
  // remove duplicates via a hash
  var unique = {};
  for (var i = 0; i < folderCodes.length; i++) {
    unique[ folderCodes[i] ] = 1;
  }
  
  folderCodes = [];
  for (var folderCode in unique) {
    folderCodes[ folderCodes.length ] = folderCode == 'null' ? null : folderCode;
  }
  
  // count number of dots in each folderCode
  var dots = {};
  for (var i = 0; i < folderCodes.length; i++) {
    if (folderCodes[i]) {
      var d = folderCodes[i].split('.');
      dots[ folderCodes[i] ] = d.length;
    }
  }
  folderCodes.sort(function(a,b) {
    if (a == null) return -1;
    if (b == null) return  1;

    if (dots[a] > dots[b]) return  1;
    if (dots[a] < dots[b]) return -1;
    return 0;
  });
  this.reloadFolderQueue = folderCodes;
  this.reloadNextFolderInQueue();
}

ExpandTree.prototype.reloadFolder = function(folderId) {
  this.reloadFolders([folderId]);
}

// reload the content of one or more folders. This will reload all loaded folders below this folder. Will also reload all other instances of the folder in case of symlinks etc.
ExpandTree.prototype.reloadFolders = function(folderIds) {
  var reloadFolders = [];
  for( var folderIx=0; folderIx<folderIds.length; folderIx++ ) {
    var folderId = folderIds[folderIx];
    // add "aliases" for this folder
    if( !this.items[folderId] ) continue;
    for( var folderCode in this.items[folderId].folderIds ) {
      if( this.loaded[folderCode] ) reloadFolders[reloadFolders.length] = folderCode;
    }
    // add all loaded folders below the folders we want to reload
    var reloadLength = reloadFolders.length;
    for( var reloadIx=0; reloadIx<reloadLength; reloadIx++ ) {
      var matchCode = reloadFolders[reloadIx];
      for( var folderCode in this.loaded ) {
        if( folderCode.indexOf(matchCode)==0 ) {
          reloadFolders[reloadFolders.length] = folderCode;
        }
      }
    }
  }
  this._setReloadFolderQueue(reloadFolders);
}

// Callback for reloadNextFolderInQueue(). "loop" to next folder in this.reloadFolderQueue array when done.
ExpandTree.prototype.reloadNextFolderInQueueHandler = function(args) {
  this.expandFolderHandler(args);
  if (this.openFolders[ args.folderCode ]) {
    this.expand(args.folderCode);
  }
  this.reloadNextFolderInQueue();
}

// "loop" for reloading all folders in this.reloadFolderQueue array. uses reloadNextFolderInQueueHandler() as callback instead of the regular expandFolderHandler()
ExpandTree.prototype.reloadNextFolderInQueue = function() {
  if (!this.reloadFolderQueue || this.reloadFolderQueue.length == 0) {
    return;
  }
  var folderCode = this.reloadFolderQueue.shift() || "";
  var folderContentElm = document.getElementById(this.id + '_c' + folderCode);
  if ( !folderCode || (this.loaded[folderCode] && folderContentElm) ) {
    _debug('Call ajax to reload folder');
    if (folderContentElm) {
      folderContentElm.innerHTML = top.o2.lang.getString('o2.desktop.reloading');
    }
    o2.ajax.call({
      setDispatcherPath : "o2cms",
      setClass          : "System-Tree",
      setMethod         : "expandFolder",
      setParams         : { folderCode : folderCode },
      handler           : "getComponentById('" + this.id + "').reloadNextFolderInQueueHandler",
      errorHandler      : "getComponentById('" + this.id + "').stopLoading"
    });
  }
  else {
    _debug('Folder not yet open');
  }
}

// load and expand several folders
ExpandTree.prototype.expandFolders = function(folderCodes) {
  // pretend the folders are open...
  for (var i = 0; i < folderCodes.length; i++) {
    if (folderCodes[i]) {
      this.openFolders[ folderCodes[i] ] = true;
      this.loaded[      folderCodes[i] ] = true;
    }
  }
  // ...and reload them
  this._setReloadFolderQueue(folderCodes);
}

ExpandTree.prototype.getDragDataById = function(dragId) {
  return this.items[dragId];
}


ExpandTree.prototype.ondragstart = function(source) {
// _debug('dragstart: '+source.element.id+'/'+source.data.text);
}
ExpandTree.prototype.ondragend = function(source, target) {
//  _debug('dragend: '+source.element.id+'/'+source.data.text+' to '+target.element.id+'/'+target.data.text);
}
ExpandTree.prototype.ondrop = function(source, target, event) {
  if ((source.element == target.element || o2.hasClassName(source.element, "categoryBrowserItemIcon"))  &&  target.data) { // drop from tree to tree or categoryBrowser to tree, and we hit an object

    if (o2.hasClassName(source.element, "categoryBrowserItemIcon")) {
      var categoryBrowser = source.window.categoryBrowser;
      var draggedElms = categoryBrowser.getDraggedItems();
      var ids = new Array();
      for (var i = 0; i < draggedElms.length; i++) {
        ids.push( draggedElms[i].id );
      }
      this.multiMove(ids, target.data.id);
      categoryBrowser.refresh(200);
    }
    else {
      this.move(source.data.id, target.data.id);
    }
  }
}


function _debug(msg) {
  var elm = document.getElementById('debug');
  if( elm ) elm.innerHTML += msg+'<br>';
}
