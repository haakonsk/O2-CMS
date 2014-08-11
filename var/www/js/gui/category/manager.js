// XXX Navigation with arrows, resizing of columns and rearranging of columns should be moved to separate js files, and be made part of a generic datagrid.

/* PRIORITIZED LIST OF TODOS;
   --------------------------
   Uparrow sometimes becomes down(?)
   Use appendChild instead of reload when dragging to the category manager.
   Filter: type of object, owner..
   Reset defaults.
   Caching of newList (context menu)
*/

o2.require("/js/util/urlMod.js");
o2.require("/js/util/string.js");
o2.require("/js/navigation.js");
o2.require("/js/DOMUtil.js");
o2.require("/js/gui/category/manager/DragReceiver.js");
o2.require("/js/gui/category/manager/DraggableObject.js");
o2.require("/js/gui/category/manager.js");
o2.require("/js/browser_detect.js");
o2.require("/js/dragDrop.js");
o2.require("/js/datadumper.js");

o2.addLoadEvent(preInit);

function preInit() {
  // We don't know which of the event types the browser supports, so initially, we add all of them. handleKeyPress removes 2.
  o2.addEvent( document, "keypress",  categoryBrowser.handleKeyPress );
  o2.addEvent( document, "keydown",   categoryBrowser.handleKeyDown  );
  o2.addEvent( document, "keyup",     categoryBrowser.handleKeyUp    );
  window.focus(); // So we don't have to click in the frame to be able to use the keyboard
}

function initCategoryBrowser() {
  if (!o2.hasBeenRequired("/js/tableSortable.js")) {
    o2.require("/js/tableSortable.js", categoryBrowser.initSortableColumns);
  }

  o2EventHandler.addEventListenerByClass( "click",       "categoryBrowserItem", categoryBrowser.markObjects         );
  o2EventHandler.addEventListenerByClass( "dblclick",    "categoryBrowserItem", categoryBrowser.onDoubleClick       );
  o2EventHandler.addEventListenerByClass( "contextmenu", "categoryBrowserItem", categoryBrowser.showItemContextMenu );
  o2.addEvent( document, "mousedown",   function(e) { window.focus(); e.preventDefault();                     } ); // Don't select any text.
  o2.addEvent( document, "contextmenu", function(e) { window.focus(); categoryBrowser.showPageContextMenu(e); } );

  categoryBrowser.setFirstElementActive();
  categoryBrowser.initRearrangableColumns();
  categoryBrowser.initResizableColumns();
  categoryBrowser.setColumnWidths();
  categoryBrowser.setViewMode();
  categoryBrowser.setFrameSwitchButtonTitle();
  categoryBrowser.setupDragDrop();
  categoryBrowser.hideLoadingIcon();
  window.focus();
}


var categoryBrowser = {

  markedObjectIds     : new Array(),
  activeObject        : null,
  viewMode            : null,
  baseIntervalObject  : null,
  modes               : new Array("listView", "thumbView"),
  draggedHeader       : null,
  draggedItem         : null,

  listViewCellPadding : 6,
  headerHeight        : 74,
  thumbHeight         : 140,
  listItemHeight      : 23,
  thumbWidth          : 160,


  onDoubleClick : function(e) {
    categoryBrowser.clearMarkedObjects();
    categoryBrowser.markObject( e.getTarget() );
    categoryBrowser.openItem();
  },

  openItem : function() {
    var elm = categoryBrowser.activeObject;
    if (elm.getAttribute("folderCode")) {
      document.location.href = o2.urlMod.urlMod({
        setParam : "catId=" + elm.id
      });
    }
    else {
      if (elm.getAttribute("isTrashed")) {
        top.displayError( top.o2.lang.getString("o2.desktop.errorCantOpenTrashedObject") );
      }
      else {
        top.openObject(elm.getAttribute("package"), elm.id);
      }
    }
  },

  navigateUp : function() {
    var parentCategoryId = categoryBrowser.getCategoryInfo("parentCategoryId");
    if (parentCategoryId) {
      document.location.href = o2.urlMod.urlMod({
        setParam : "catId=" + parentCategoryId
      });
    }
  },

  setRowWidthsForListView : function(totalWidth) {
    if (!totalWidth) {
      totalWidth = 18; // XXX Why?
      var numHeadersWithWidth = 0;
      var headers = categoryBrowser.getHeaders();
      for (var i = 0; i < headers.length; i++) {
        var header = headers[i];
        var width = parseInt( header.getAttribute("width") );
        if (width) {
          header.style.width = width + "px";
          numHeadersWithWidth++;
          totalWidth += width + 1;
        }
      }
      totalWidth += categoryBrowser.listViewCellPadding * 2 * (numHeadersWithWidth-1);
    }
    categoryBrowser.getHeaderRow().style.width = totalWidth + "px";

    var elements = categoryBrowser.getElements("listView");
    for (var i = 0; i < elements.length; i++) {
      var elm = elements[i];
      if (browser.isIE) { // Stupid ie destroys the clean code!
        elm.parentNode.style.width = totalWidth + "px";
      }
      else {
        elm.style.width = totalWidth + "px";
      }
    }
  },

  /* Category-items shouldn't have width set with javascript in thumbView mode. The css determines the width. */
  resetRowWidths : function() {
    var elements = categoryBrowser.getElements("thumbView");
    for (var i = 0; i < elements.length; i++) {
      elements[i].parentNode.style.width = "";
    }
  },

  setColumnWidths : function() {
    categoryBrowser.setRowWidthsForListView();
    // Go through headers:
    var headers = categoryBrowser.getHeaders();
    for (var i = 0; i < headers.length; i++) {
      var header = headers[i];
      var width = parseInt( header.getAttribute("width") );
      if (width) {
        header.style.width = width + "px";
      }
    }

    // Go through elements:
    var elements = categoryBrowser.getElements("listView");
    for (var i = 0; i < elements.length; i++) {
      var elm = elements[i];
      var cells = categoryBrowser.HTMLCollectionToArray( elm.getElementsByTagName("span") );
      for (var j = 0; j < cells.length; j++) {
        var cell = cells[j];
        if (headers[j].style.width) {
          cell.style.width  =  (parseInt( headers[j].style.width ) + 1)  +  "px";
        }
      }
    }
  },

  initRearrangableColumns : function() {
    var headers = categoryBrowser.getHeaders();
    for (var i = 0; i < headers.length; i++) {
      o2.addEvent(headers[i], "mousedown", categoryBrowser.startRearrangingColumns);
    }
  },

  startRearrangingColumns : function(e) {
    var draggedElm = e.getTarget();
    if (!o2.hasClassName(draggedElm.parentNode, "header")) {
      return;
    }
    categoryBrowser.draggedHeader = draggedElm;
    o2.addClassName( draggedElm,                  "drag" );
    o2.addClassName( draggedElm.parentNode, "isDragging" );
    e.preventDefault(); // Makes it possible to determine which element the mouse is over during mouseup (e.getTarget() would otherwise return the dragged element).
    o2.addEvent(document, "mouseup", categoryBrowser.doRearrangeColumns);
  },

  doRearrangeColumns : function(e) {
    var draggedElm = categoryBrowser.draggedHeader;
    o2.removeEvent(document, "mouseup", categoryBrowser.doRearrangeColumns);
    o2.removeClassName( draggedElm,                  "drag" );
    o2.removeClassName( draggedElm.parentNode, "isDragging" );
    categoryBrowser.draggedHeader = null;
    var droppedOnElm = e.getTarget();
    if (!o2.hasClassName(droppedOnElm.parentNode, "header")  ||  draggedElm === droppedOnElm) {
      return;
    }
    // Find dragging direction (left-to-right or right-to-left)
    var direction;
    for (var i = 0; i < draggedElm.parentNode.childNodes.length; i++) {
      var elm = draggedElm.parentNode.childNodes[i];
      if (elm === draggedElm || elm === droppedOnElm) {
        direction  =  elm === draggedElm  ?  "ltr"  :  "rtl";
        break;
      }
    }
    // Dragging from left to right: Insert dragged column after droppedOnElm. Right to left: Insert dragged column before droppedOnElm:
    var draggedTypeElms   = o2.getElementsByClassName( draggedElm.getAttribute("type"),   draggedElm.parentNode.parentNode, "span" );
    var droppedOnTypeElms = o2.getElementsByClassName( droppedOnElm.getAttribute("type"), draggedElm.parentNode.parentNode, "span" );
    for (var i = 0; i < draggedTypeElms.length; i++) {
      var src  = draggedTypeElms[i];
      var dest = droppedOnTypeElms[i];
      if (direction === "ltr") {
        o2.insertAfter(src, dest);
      }
      else if (direction === "rtl") {
        src.parentNode.insertBefore(src, dest);
      }
    }
    categoryBrowser.saveColumnOrder( draggedElm.parentNode );
  },

  saveColumnOrder : function(headerRow) {
    var order = new Array();
    for (var i = 0; i < headerRow.childNodes.length; i++) {
      var headerCell = headerRow.childNodes[i];
      if (headerCell.nodeName.toLowerCase() === "span") {
        order.push( headerCell.getAttribute("type") );
      }
    }
    order = order.join(",");
    categoryBrowser.headerRow = headerRow; // A hack to make headerRow available in ajax.js (see onSuccess attribute below)
    o2.ajax.call({
      setMethod : "saveColumnOrder",
      setParams : "order=" + order,
      onSuccess : "categoryBrowser.saveColumnWidths(categoryBrowser.headerRow); delete categoryBrowser.headerRow;",
      method    : "post"
    });
  },

  initResizableColumns : function() {
    var headers = categoryBrowser.getHeaders();
    for (var i = 0; i < headers.length; i++) {
      var header = headers[i];
      var resizerRight = document.createElement("div");
      o2.addClassName( resizerRight, "resizerRight" );
      header.appendChild( resizerRight );
      o2.addEvent(resizerRight, "mousedown", categoryBrowser.startResizeColumn);
      if (i > 0) {
        var resizerLeft  = document.createElement("div");
        o2.addClassName( resizerLeft,  "resizerLeft"  );
        header.appendChild( resizerLeft  );
        o2.addEvent(resizerLeft,  "mousedown", categoryBrowser.startResizeColumn);
      }
    }
  },

  startResizeColumn : function(e) {
    var resizer = e.getTarget();
    o2.addEvent( document, "mousemove", categoryBrowser.resizeColumn    );
    o2.addEvent( document, "mouseup",   categoryBrowser.resizeColumnEnd );
    var header = o2.hasClassName(resizer, "resizerRight") ? resizer.parentNode : o2.getPreviousElement(resizer.parentNode);
    categoryBrowser.resizeColumnInfo = {
      element  : header,
      x        : e.getX(),
      width    : header.style.width,
      rowWidth : parseInt( header.parentNode.style.width )
    };
  },

  resizeColumn : function(e) {
    var info = categoryBrowser.resizeColumnInfo;
    var row  = info.element.parentNode;
    var deltaWidth = e.getX() - parseInt(info.x);
    row.style.width          = ( parseInt(info.rowWidth) + deltaWidth )  +  "px";
    info.element.style.width = ( parseInt(info.width)    + deltaWidth )  +  "px";
  },

  resizeColumnEnd : function(e) {
    o2.removeEvent( document, "mousemove", categoryBrowser.resizeColumn    );
    o2.removeEvent( document, "mouseup",   categoryBrowser.resizeColumnEnd );
    var info = categoryBrowser.resizeColumnInfo;
    var newWidth = ( parseInt(info.width) + e.getX() - parseInt(info.x) + 1 )  +  "px";
    var elements = categoryBrowser.getElements("listView");
    for (var i = 0; i < elements.length; i++) {
      var elm = elements[i];
      if (o2.hasClassName(elm, "resizerLeft")  ||  o2.hasClassName(elm, "resizerRight")) {
        continue;
      }
      var column = (o2.getElementsByClassName(info.element.getAttribute("type"), elm, "span"))[0];
      column.style.width = newWidth;
    }
    categoryBrowser.setRowWidthsForListView( parseInt( categoryBrowser.getHeaderRow().style.width ) );
    categoryBrowser.resizeColumnInfo = null;
    categoryBrowser.saveColumnWidths( e.getTarget().parentNode.parentNode );
  },

  saveColumnWidths : function(headerRow) {
    var widths = new Array();
    for (var i = 0; i < headerRow.childNodes.length; i++) {
      var headerCell = headerRow.childNodes[i];
      if (headerCell.nodeName.toLowerCase() === "span") {
        widths.push( parseInt( headerCell.style.width ) );
      }
    }
    o2.ajax.call({
      setMethod : "saveColumnWidths",
      setParams : "widths=" + widths.join(","),
      method    : "post"
    });
  },

  initSortableColumns : function() {
    o2.tableSorter.addCallback( categoryBrowser.saveSortByColumn );
    o2.tableSorter.init();
  },

  saveSortByColumn : function(header, sortDirection, sortType) {
    if (!header.getAttribute("type")) {
      return;
    }
    sortDirection = sortDirection === "DESC" ? "descending" : "ascending";
    o2.ajax.call({
      setMethod : "saveSortByInfo",
      setParams : "field=" + header.getAttribute("type") + "&direction=" + sortDirection + "&sortType=" + sortType,
      method    : "post"
    });
  },

  setupDragDrop : function() {
    var elements = categoryBrowser.getElements("thumbView");
    for (var i = 0; i < elements.length; i++) {
      var parent = elements[i].parentNode;
      parent.setAttribute( "componentId", parent.id                     );
      parent.setAttribute( "component",   "CategoryBrowserDragReceiver" );
      initDragContainer(parent);
      var imgs = parent.getElementsByTagName("img");
      for (var j = 0; j < imgs.length; j++) {
        var img = imgs[j];
        if (!img.id) {
          img.id = "imageFor" + parent.id;
        }
        img.setAttribute( "componentId", img.id                           );
        img.setAttribute( "component",   "CategoryBrowserDraggableObject" );
        img.setAttribute( "dragid",      img.id                           );
        initDragContainer(img);
      }
    }
    document.body.id = "body";
    document.body.setAttribute( "componentId", "body"                        );
    document.body.setAttribute( "component",   "CategoryBrowserDragReceiver" );
    initDragContainer(document.body);
  },

  setViewMode : function(mode) {
    var isModeArgument = mode ? true : false;
    var catBrowser = document.getElementById("categoryBrowser");
    categoryBrowser.viewMode = mode = mode ? mode : catBrowser.getAttribute("initialViewMode");
    for (var i = 0; i < categoryBrowser.modes.length; i++) {
      var modeI = categoryBrowser.modes[i];
      if (modeI !== mode) {
        o2.removeClassName(catBrowser, modeI);
      }
    }
    o2.addClassName(catBrowser, mode);

    if (browser.isIE) {
      if (mode === "listView") {
        categoryBrowser.setRowWidthsForListView();
      }
      else if (mode === "thumbView") {
        categoryBrowser.resetRowWidths();
      }
    }

    if (isModeArgument) {
      o2.ajax.call({
        setMethod : "setViewMode",
        setParams : "mode=" + mode,
        method    : "post"
      });
    }
  },

  refresh : function(milliSecondsToWait) {
    if (milliSecondsToWait) {
      setTimeout("document.location.href = document.location.href;", milliSecondsToWait);
    }
    else {
      document.location.href = document.location.href;
    }
  },

  close : function() {
    top.closeFrameId( top.bottomFrame.activeFrameId );
  },

  setFirstElementActive : function() {
    var divs = o2.getElementsByClassName("categoryBrowserItem", document.getElementById("categoryBrowser"), "div");
    if (divs.length >= 1) {
      categoryBrowser.setActive( divs[0] );
    }
  },

  markObjects : function(e) {
    var elm = categoryBrowser.getItem( e.getTarget() );
    if (e.evt.shiftKey) {
      categoryBrowser.markObjectInterval(elm.id);
    }
    else if (e.evt.ctrlKey) {
      categoryBrowser.markObject(elm);
    }
    else {
      categoryBrowser.clearMarkedObjects();
      categoryBrowser.markObject(elm);
    }
    e.preventDefault();
  },

  /* If elm is the categoryBrowserItem, then returns elm. Otherwise searches parent, grand-parent etc until the item is found */
  getItem : function(elm) {
    while (elm && !o2.hasClassName(elm, "categoryBrowserItem")) {
      elm = elm.parentNode;
    }
    return elm;
  },

  /* If the parameter is a div, then just return it.
     Otherwise check parent, grand-parent etc until we find a div. */
  getDiv : function(elm) {
    while (elm) {
      if (elm.nodeName.toLowerCase() === "div") {
        break;
      }
      elm = elm.parentNode;
    }
    return elm;
  },

  setActive : function(elm) {
    elm = categoryBrowser.getDiv(elm);
    if (!elm) {
      return top.displayError("Didn't find div");
    }
    if (categoryBrowser.activeObject) {
      o2.removeClassName(categoryBrowser.activeObject, "activeItem");
    }
    o2.addClassName(elm, "activeItem");
    categoryBrowser.activeObject = elm;
  },

  markObject : function(elm) {
    if (elm.id && elm.nodeName.toLowerCase() === "div") {
      categoryBrowser.markedObjectIds.push( elm.id );
      o2.addClassName(elm, "selectedItem");
      categoryBrowser.setActive(elm);
    }
  },

  activeObjectIsMarked : function() {
    for (var i = 0; i < categoryBrowser.markedObjectIds.length; i++) {
      if (categoryBrowser.markedObjectIds[i] == categoryBrowser.activeObject.id) {
        return true;
      }
    }
    return false;
  },

  unmarkObject : function(elm) {
    elm = categoryBrowser.getItem(elm);
    var oldMarkedIds = categoryBrowser.markedObjectIds;
    categoryBrowser.markedObjectIds = new Array();
    for (var i = 0; i < oldMarkedIds.length; i++) {
      if (oldMarkedIds[i] != categoryBrowser.activeObject.id) {
        categoryBrowser.markedObjectIds.push( oldMarkedIds[i] );
      }
    }
    o2.removeClassName(elm, "selectedItem");
  },

  markObjectInterval : function(objectId1) {
    if (categoryBrowser.markedObjectIds.length > 0) {
      var parent = document.getElementById( objectId1 ).parentNode;
      var objectId2 = (categoryBrowser.baseIntervalObject || categoryBrowser.activeObject).id;
      categoryBrowser.clearMarkedObjects();
      categoryBrowser.baseIntervalObject = document.getElementById(objectId2);
      var pos1 = categoryBrowser.getObjectPosition(objectId1);
      var pos2 = categoryBrowser.getObjectPosition(objectId2);
      if (pos1 > pos2) { // Make sure pos1 < pos2
        var tmp = pos1;
        pos1 = pos2;
        pos2 = tmp;
      }
      var elm = parent.childNodes[0];
      for (var i = 1; i <= pos2; i++) {
        do {
          elm = elm.nextSibling;
        }
        while (elm && !o2.hasClassName(elm, "categoryBrowserItem"));
        if (elm  &&  i >= pos1) {
          categoryBrowser.markObject(elm);
        }
      }
      categoryBrowser.setActive( document.getElementById(objectId1) );
    }
    else {
      categoryBrowser.markObject( document.getElementById(objectId1) );
    }
  },

  getObjectPosition : function(objectId) {
    var catBrowser = document.getElementById("categoryBrowser");
    var elements = catBrowser.getElementsByTagName("div");
    var positions = new Array();
    var pos = 0;
    for (var i = 0; i < elements.length; i++) {
      var elm = elements[i];
      if (elm.getAttribute("package")) {
        pos++;
        if (elm.id == objectId) {
          return pos;
        }
      }
    }
    return null;
  },

  clearMarkedObjects : function() {
    while (categoryBrowser.markedObjectIds.length > 0) {
      var objectId = categoryBrowser.markedObjectIds[ categoryBrowser.markedObjectIds.length-1 ];
      categoryBrowser.markedObjectIds.pop();
      var elm = document.getElementById( objectId );
      if (elm) { // May have been deleted
        o2.removeClassName(elm, "selectedItem");
      }
    }
    categoryBrowser.baseIntervalObject = null;
  },

  handleKeyPress : function(e, eventType) {
    eventType = eventType || "keypress";

    // We added too many key-events (3) in initCategoryBrowser (to support different browsers), here we remove the ones we don't use:
    if (!categoryBrowser.unnecessaryEventRemoved) {
      if (eventType === "keypress"  ||  eventType === "keyup") {
        o2.removeEvent(document, "keydown", categoryBrowser.handleKeyDown);
      }
      if (eventType === "keypress"  ||  eventType === "keydown") {
        o2.removeEvent(document, "keyup", categoryBrowser.handleKeyUp);
      }
      if (eventType === "keydown"  ||  eventType === "keyup") {
        o2.removeEvent(document, "keypress", categoryBrowser.handleKeyPress);
      }
      categoryBrowser.unnecessaryEventRemoved = true;
    }

    // console.log( "KeyCode: " + e.getKeyCode() );
    switch (e.getKeyCode()) {
      case  13: categoryBrowser.openItem();         break;  // Return
      case  27: categoryBrowser.handleEscape(e);    return; // Escape
      case  32: categoryBrowser.toggleMarkActive(); break;  // Space bar
      case  33: categoryBrowser.onPageUp(e);        break;  // Page up
      case  34: categoryBrowser.onPageDown(e);      break;  // Page down
      case  35: categoryBrowser.onEnd(e);           break;  // End
      case  36: categoryBrowser.onHome(e);          break;  // Home
      case  37: categoryBrowser.onLeftArrow(e);     break;  // Left
      case  38: categoryBrowser.onUpArrow(e);       break;  // Up
      case  39: categoryBrowser.onRightArrow(e);    break;  // Right
      case  40: categoryBrowser.onDownArrow(e);     break;  // Down
      case  46: categoryBrowser.deleteSelected(e);  return; // Delete
      case 114:
      case  82: if (e.evt.ctrlKey) { categoryBrowser.refresh(); } break; // Ctrl-r
      case 119:
      case  87: if (e.evt.ctrlKey) { categoryBrowser.close();   } break; // Ctrl-w
      /* Maybe not, ctrl-u is view source in Firefox.
        case 117:
        case  85: if (e.evt.ctrlKey) { categoryBrowser.navigateUp(); e.preventDefault(); } break; // Ctrl-u
      */
      default : return;
    }
    e.preventDefault(); // Prevent scrolling, we should do the scrolling with javascript.
  },

  handleKeyDown : function(e) {
    categoryBrowser.handleKeyPress(e, "keydown");
  },

  handleKeyUp : function(e) {
    categoryBrowser.handleKeyPress(e, "keyup");
  },

  setDraggedItem : function(elm) {
    categoryBrowser.draggedItem = categoryBrowser.getItem(elm);
  },

  removeDraggedItem : function() {
    categoryBrowser.draggedItem = null;
  },

  getDraggedItems : function() {
    if (categoryBrowser.markedObjectIds.length > 0) {
      var draggedElmIsAmongMarked = false;
      var markedIds = categoryBrowser.markedObjectIds;
      for (var i = 0; i < markedIds.length; i++) {
        var id = markedIds[i];
        if (id === categoryBrowser.draggedItem.id) {
          draggedElmIsAmongMarked = true;
          break;
        }
      }
      if (draggedElmIsAmongMarked) {
        var draggedElements = new Array();
        for (var i = 0; i < categoryBrowser.markedObjectIds.length; i++) {
          draggedElements.push( document.getElementById( categoryBrowser.markedObjectIds[i] ) );
        }
        return draggedElements;
      }
    }
    return new Array( categoryBrowser.draggedItem );
  },

  /* If none is selected, then delete the element that's being dragged.
     Also if the dragged element isn't among those selected, just delete the one that's being dragged. */
  deleteSelectedOrDragged : function(e, draggedElm) {
    var items = categoryBrowser.getDraggedItems();
    if (items.length === 1) { // Dragged item may not have been marked
      categoryBrowser.clearMarkedObjects();
      categoryBrowser.markObject(draggedElm);
    }
    categoryBrowser.deleteSelected(e);
  },

  deleteSelected : function(e) {
    if (e.evt.shiftKey || e.evt.ctrlKey || e.evt.metaKey || e.evt.altKey) {
      return;
    }
    var ids = categoryBrowser.markedObjectIds;
    if (ids.length === 0) {
      return;
    }
    categoryBrowser.confirmDeleteIds = ids;
    var confirmTextKey = ids.length === 1 ? "questionConfirmDeleteOne" : "questionConfirmDeleteMany";
    top.confirmBox( o2.lang.getString("o2.Category.Manager." + confirmTextKey), categoryBrowser.deleteSelectedII );
  },

  deleteSelectedII : function(doDelete) {
    if (!doDelete) {
      return;
    }
    var ids = categoryBrowser.confirmDeleteIds;
    delete categoryBrowser.confirmDeleteIds;
    o2.ajax.call({
      setMethod : "trashObjects",
      setParams : "ids=" + ids.join(",") + "&categoryId=" + categoryBrowser.getCategoryInfo("id"),
      handler   : "categoryBrowser.deleteSelectedIII",
      method    : "post"
    });
  },

  deleteSelectedIII : function(params) {
    var ids = o2.split(/,/, params.deletedIds);
    for (var i = 0; i < ids.length; i++) {
      var elm = document.getElementById( ids[i] );
      elm.parentNode.removeChild(elm);
    }
    o2Navigation.invalidateCache();
    categoryBrowser.clearMarkedObjects();
    categoryBrowser.setFirstElementActive(); // XXX We can do better than this!
    top.reloadTreeFolders(params.categoryId, params.trashcanId);
    window.focus();
  },

  toggleMarkActive : function() {
    if (categoryBrowser.activeObjectIsMarked()) {
      categoryBrowser.unmarkObject( categoryBrowser.activeObject );
    }
    else {
      categoryBrowser.markObject( categoryBrowser.activeObject );
    }
  },

  onLeftArrow : function(e) {
    if (categoryBrowser.viewMode === "thumbView") {
      categoryBrowser.moveDelta(e, -1);
    }
  },

  onRightArrow : function(e) {
    if (categoryBrowser.viewMode === "thumbView") {
      categoryBrowser.moveDelta(e, 1);
    }
  },

  onDownArrow : function(e) {
    var delta = 0;
    if (categoryBrowser.viewMode === "listView") {
      delta = 1;
    }
    else if (categoryBrowser.viewMode === "thumbView") {
      delta = categoryBrowser.getNumHorizontalElementsPerPage();
    }
    categoryBrowser.moveDelta(e, delta);
  },

  onUpArrow : function(e) {
    var delta = 0;
    if (categoryBrowser.viewMode === "listView") {
      delta = -1;
    }
    else if (categoryBrowser.viewMode === "thumbView") {
      delta = -categoryBrowser.getNumHorizontalElementsPerPage();
    }
    categoryBrowser.moveDelta(e, delta);
  },

  onEnd : function(e) {
    categoryBrowser.updateSelected( e, categoryBrowser.getLastItem() );
  },

  onHome : function(e) {
    categoryBrowser.updateSelected( e, categoryBrowser.getFirstItem() );
  },

  hideLoadingIcon : function() {
    document.getElementById("loadingIcon").style.display = "none";
  },

  showLoadingIcon : function() {
    document.getElementById("loadingIcon").style.display = "";
  },

  handleEscape : function(e) {
    initCategoryBrowser();

    // Display a link to load the remaining items:
    var link = document.getElementById("loadMoreLink");
    if (link) {
      return link.style.display = "";
    }
    var linkHtml = "<a id='loadMoreLink' href='javascript: categoryBrowser.loadMoreItems();'>" + o2.lang.getString("o2.Category.Manager.linkLoadMoreItems") + "</a>";
    o2.htmlToDom.htmlToDom(linkHtml, document.getElementById("categoryBrowser"));
  },

  loadMoreItems : function() {
    document.getElementById("loadMoreLink").style.display = "none";
    categoryBrowser.showLoadingIcon();
    o2.ajax.call({
      setMethod : "getMoreResults",
      setParams : "catId=" + categoryBrowser.getCategoryInfo("id") + "&skip=" + categoryBrowser.getElements("listView").length,
      target    : "categoryBrowserItems",
      where     : "bottom"
    });
  },

  setFirstAndLastItem : function() {
    if (!categoryBrowser.lastItem) {
      var items = o2.getElementsByClassName("categoryBrowserItem", document.getElementById("categoryBrowser"), "div");
      categoryBrowser.lastItem  = items[ items.length-1 ];
      categoryBrowser.firstItem = items[0];
    }
  },

  getFirstItem : function() {
    categoryBrowser.setFirstAndLastItem();
    return categoryBrowser.firstItem;
  },

  getLastItem : function() {
    categoryBrowser.setFirstAndLastItem();
    return categoryBrowser.lastItem;
  },

  onPageUp : function(e) {
    var delta = -categoryBrowser.getNumVerticalElementsPerPage();
    if (categoryBrowser.viewMode === "thumbView") {
      delta *= categoryBrowser.getNumHorizontalElementsPerPage();
    }
    categoryBrowser.moveDelta(e, delta);
  },

  onPageDown : function(e) {
    var delta = categoryBrowser.getNumVerticalElementsPerPage();
    if (categoryBrowser.viewMode === "thumbView") {
      delta *= categoryBrowser.getNumHorizontalElementsPerPage();
    }
    categoryBrowser.moveDelta(e, delta);
  },

  moveDelta : function(e, delta) {
    var factor = delta > 0 ? 1 : -1;
    var elm = categoryBrowser.activeObject;
    while (delta != 0) {
      do {
        var newElm = o2Navigation.nextTag(elm, factor, document.getElementById("categoryBrowser"), true);
        if (elm === newElm) {
          if (o2.hasClassName(elm, "header")) {
            elm = categoryBrowser.getFirstItem();
          }
          else {
            elm = categoryBrowser.getLastItem();
          }
          categoryBrowser.updateSelected(e, elm);
          return;
        }
        elm = newElm;
      }
      while (!o2.hasClassName(elm, "categoryBrowserItem"));
      delta -= factor;
    }
    categoryBrowser.updateSelected(e, elm);
    if (factor > 0) {
      categoryBrowser.scrollDownIfNecessary(e);
    }
    else if (factor < 0) {
      categoryBrowser.scrollUpIfNecessary(e);
    }
  },

  scrollDownIfNecessary : function(e) {
    var yPos         = categoryBrowser.headerHeight + categoryBrowser.getItemHeight() * categoryBrowser.getVerticalPositionOfActiveObject();
    var windowHeight = window.innerHeight || document.body.offsetHeight;
    if (yPos > categoryBrowser.getScrollTop() + windowHeight) {
      scrollBy(0, yPos-windowHeight);
    }
  },

  scrollUpIfNecessary : function(e) {
    var yPos      = categoryBrowser.headerHeight   +   categoryBrowser.getItemHeight() * (categoryBrowser.getVerticalPositionOfActiveObject()-1);
    if (yPos < categoryBrowser.getScrollTop()) {
      scrollBy(0, yPos-categoryBrowser.getScrollTop()-20);
      if (categoryBrowser.getScrollTop() < categoryBrowser.getItemHeight() + categoryBrowser.headerHeight) {
        scrollBy(0, -categoryBrowser.getScrollTop());
      }
    }
  },

  getScrollTop : function() {
    return parseInt( document.body.scrollTop || window.pageYOffset || 0 );
  },

  getItemHeight : function() {
    if (categoryBrowser.viewMode === "thumbView") {
      return categoryBrowser.thumbHeight;
    }
    if (categoryBrowser.viewMode === "listView") {
      return categoryBrowser.listItemHeight;
    }
  },

  /* Called after some keyboard key has been pressed. elm is the new active object. */
  updateSelected : function(e, elm) {
    if (e.evt.shiftKey) {
      categoryBrowser.markObjectInterval(elm.id);
    }
    else if (e.evt.ctrlKey) {
      // Just update active object
      categoryBrowser.setActive(elm);
    }
    else {
      categoryBrowser.clearMarkedObjects();
      categoryBrowser.markObject(elm);
    }
  },

  getNumVerticalElementsPerPage : function() {
    var windowHeight = window.innerHeight || document.body.offsetHeight;
    if (categoryBrowser.viewMode === "thumbView") {
      return parseInt((windowHeight-categoryBrowser.headerHeight) / categoryBrowser.thumbHeight);
    }
    if (categoryBrowser.viewMode === "listView") {
      return parseInt((windowHeight-categoryBrowser.headerHeight) / categoryBrowser.listItemHeight);
    }
  },

  getNumHorizontalElementsPerPage : function() {
    var windowWidth = window.innerWidth || document.body.offsetWidth;
    if (categoryBrowser.viewMode === "thumbView") {
      return parseInt((windowWidth-2) / categoryBrowser.thumbWidth);
    }
    if (categoryBrowser.viewMode === "listView") {
      return 1;
    }
  },

  getVerticalPositionOfActiveObject : function() {
    var pos = 0;
    for (var i = 0; i < categoryBrowser.activeObject.parentNode.childNodes.length; i++) {
      var elm = categoryBrowser.activeObject.parentNode.childNodes[i];
      if (elm === categoryBrowser.activeObject) {
        return parseInt(pos/categoryBrowser.getNumHorizontalElementsPerPage())+1;
      }
      if (o2.hasClassName(elm, "categoryBrowserItem")) {
        pos++;
      }
    }
    top.displayError("getVerticalPositionOfActiveObject: Didn't find it");
  },

  getHeaderRow : function() {
    if (!categoryBrowser.headerElm) {
      categoryBrowser.headerElm = (o2.getElementsByClassName("header", document.getElementById("categoryBrowser"), "div"))[0];
    }
    return categoryBrowser.headerElm;
  },

  getHeaders : function() {
    var header = categoryBrowser.getHeaderRow();
    var headers = new Array();
    for (var i = 0; i < header.childNodes.length; i++) {
      var child = header.childNodes[i];
      if (child.nodeName.toLowerCase() === "span") {
        headers.push(child);
      }
    }
    return headers;
  },

  getElements : function(view) {
    var elms = document.getElementById("categoryBrowser").getElementsByTagName("div"); // Returns an HTMLCollection, not an array
    var elements = new Array();
    for (var i = 1; i < elms.length; i++) { // Skip the first element, which is the header
      var elm = elms[i];
      if (o2.hasClassName(elm, "row")) {
        for (var j = 0; j < elm.childNodes.length; j++) {
          var child = elm.childNodes[j];
          if (child.nodeName.toLowerCase() === "div"  &&  o2.hasClassName(child, view)) {
            elements.push(child);
            break;
          }
        }
      }
    }
    return elements;
  },

  HTMLCollectionToArray : function(collection) {
    var array = new Array();
    for (var i = 0; i < collection.length; i++) {
      array.push( collection[i] );
    }
    return array;
  },

  setFrameSwitchButtonTitle : function() {
    top.bottomFrame.updateFrameSwitchButton({
      frameId : top.bottomFrame.activeFrameId,
      icon    : "/images/system/classIcons/" + categoryBrowser.getCategoryInfo("metaClassName").replace(/::/g, "-") + ".gif",
      text    : categoryBrowser.getCategoryInfo("metaName")
    });
  },

  getCategoryInfo : function(key) {
    var input = document.forms.categoryInfo[key];
    if (!input) {
      return top.displayError("There's no category info with name '" + key + "'");
    }
    return input.value;
  },

  handleDrop : function(source, target) {
    var targetElm = categoryBrowser.getItem( target.element );
    var receivingCategoryId  =  targetElm && document.getElementById( targetElm.id ).getAttribute("folderCode")  ?  targetElm.id  :  categoryBrowser.getCategoryInfo("id");
    if (o2.hasClassName(source.element, "categoryBrowserItemIcon")) {
      var draggedElms = categoryBrowser.getDraggedItems();
      var ids = new Array();
      for (var i = 0; i < draggedElms.length; i++) {
        ids.push( draggedElms[i].id );
      }
      top.moveObjects( ids, receivingCategoryId, top.resolveFramePath(window) + ".categoryBrowser.dropCallback(args)" );
    }
    else {
      top.moveObject( source.data.id, receivingCategoryId, top.resolveFramePath(window) + ".categoryBrowser.dropCallback(args)" );
    }
  },

  // Callback from drop event
  dropCallback : function(args) {
    var currentCategoryId = categoryBrowser.getCategoryInfo("id");
    if (args.toFolderId == currentCategoryId  ||  args.fromFolderId == currentCategoryId) {
      categoryBrowser.refresh();
    }
  },

  showPageContextMenu : function(e) {
    e.preventDefault();
    e.stopPropagation();
    categoryBrowser.currentItem = {
      className     : categoryBrowser.getCategoryInfo("metaClassName"),
      id            : categoryBrowser.getCategoryInfo("id"),
      x             : e.getX(),
      y             : e.getY(),
      isFolder      : true,
      isWebCategory : categoryBrowser.getCategoryInfo("isWebCategory"),
      metaName      : categoryBrowser.getCategoryInfo("metaName"),
      isTrashed     : categoryBrowser.getCategoryInfo("isTrashed"),
      isRestorable  : categoryBrowser.getCategoryInfo("isRestorable")
    };
    if (categoryBrowser.currentItem.className === "O2CMS::Obj::Trashcan") {
      categoryBrowser.showContextMenu(categoryBrowser.currentItem);
      categoryBrowser.currentItem = null;
    }
    else {
      o2.ajax.call({
        setClass  : "System-Class",
        setMethod : "getCanContainClasses",
        setParams : { objectId : categoryBrowser.getCategoryInfo("id") },
        handler   : "categoryBrowser.showPageContextMenuII"
      });
    }
  },

  showPageContextMenuII : function(params) {
    categoryBrowser.showContextMenu(categoryBrowser.currentItem, params, false);
  },

  showItemContextMenu : function(e) {
    var item = categoryBrowser.getItem( e.getTarget() );
    e.preventDefault();
    e.stopPropagation();
    var isFolder = item.getAttribute("folderCode") ? true : false;
    categoryBrowser.currentItem = {
      className     : item.getAttribute("package"),
      id            : item.id,
      x             : e.getX(),
      y             : e.getY(),
      isFolder      : isFolder,
      isWebCategory : item.getAttribute("isWebCategory"),
      metaName      : item.getAttribute("metaName"),
      htmlElement   : item,
      isTrashed     : item.getAttribute("isTrashed"),
      isRestorable  : item.getAttribute("isRestorable")
    };
    if (isFolder) {
      o2.ajax.call({
        setClass  : "System-Class",
        setMethod : "getCanContainClasses",
        setParams : { objectId : item.id },
        handler   : "categoryBrowser.showItemContextMenuII"
      });
    }
    else {
      categoryBrowser.showContextMenu(categoryBrowser.currentItem, null, true);
      categoryBrowser.currentItem = null;
    }
  },

  showItemContextMenuII : function(params) {
    categoryBrowser.showContextMenu(categoryBrowser.currentItem, params, true);
    categoryBrowser.currentItem = null;
  },


  treeContextMenu : null,

  showContextMenu : function(currentItem, newList, isItemContextMenu) {
    if (categoryBrowser.treeContextMenu) {
      categoryBrowser.treeContextMenu.flush();
    }
    categoryBrowser.treeContextMenu = new DOMPopupMenu(currentItem.htmlElement, true);
    if (currentItem.className === "O2CMS::Obj::Trashcan") {
      var contextMenuEmptyTrash = categoryBrowser.treeContextMenu.addMenuItem(
        [top.o2.lang.getString("o2.desktop.treeContextMenu.emptyTrash"), '/images/system/classIcons/O2CMS-Obj-Trashcan.gif'],
        "top.frames.middleFrame.frames.left.emptyTrash(" + currentItem.id + ", categoryBrowser.refresh);"
      );
    }
    else if (currentItem.isTrashed  &&  currentItem.isRestorable) {
      var contextMenuRestore = categoryBrowser.treeContextMenu.addMenuItem(
        [top.o2.lang.getString("o2.desktop.treeContextMenu.restore"), '/images/system/up_16.gif'],
        "top.frames.middleFrame.frames.left.restoreFromTrash(" + currentItem.id + ", " + top.getTrashcanId() + ", categoryBrowser.refresh);"
      );
      categoryBrowser.treeContextMenu.showMenu(currentItem.y+20, currentItem.x);
      return;
    }
    else if (currentItem.isTrashed) {
      return;
    }

    if (isItemContextMenu) {
      var contextMenu_1 = categoryBrowser.treeContextMenu.addMenuItem([top.o2.lang.getString('o2.desktop.treeContextMenu.open'),'/images/system/classIcons/O2-Obj-Class.gif'],
        "top.openObject('"+currentItem.className+"',"+currentItem.id+");");
    }
    if (newList) {
      var contextMenuNewItem = categoryBrowser.treeContextMenu.addMenuItem([top.o2.lang.getString('o2.desktop.treeContextMenu.new'),'/images/system/classIcons/O2-Obj-Class.gif']);
      var didAddNewItem = false;
      for (var elm in newList.classNames) {
        didAddNewItem = true;
        var name = newList.classNames[elm].metaName.split("::");

        contextMenuNewItem.addMenuItem([ name[name.length-1],
                                         top.getIconUrl(newList.classNames[elm].className)],
                                       "top.newObject('"+newList.classNames[elm].className+"',"+currentItem.id+");"
                                      );
      }
      if (!didAddNewItem) {
        contextMenuNewItem.addMenuItem([top.o2.lang.getString('o2.desktop.treeContextMenu.notPermitted'),'/images/system/cancl_16.gif']);
      }
      categoryBrowser.treeContextMenu.addSeperator();
    }
    var contextMenu_properties = categoryBrowser.treeContextMenu.addMenuItem([top.o2.lang.getString('o2.desktop.treeContextMenu.properties'), '/images/system/addrecord_16.gif'],
      "top.showPropertiesDialog("+currentItem.id+");");
    var contextMenu_revision = categoryBrowser.treeContextMenu.addMenuItem([top.o2.lang.getString('o2.desktop.treeContextMenu.revisions'), '/images/system/addrecord_16.gif'],
      "top.showRevisionDialog("+currentItem.id+");");

    if (isItemContextMenu) {
      categoryBrowser.treeContextMenu.addSeperator();
      var trashcanId = top.getTrashcanId();
      var contextMenu_moveToTrash = categoryBrowser.treeContextMenu.addMenuItem([top.o2.lang.getString('o2.desktop.treeContextMenu.moveToTrash'), '/images/system/classIcons/O2CMS-Obj-Trashcan.gif'],
        "if (confirm(top.o2.lang.getString('o2.Category.Manager.questionConfirmDeleteOne'))) { top.moveObject(" + currentItem.id + ", " + trashcanId + ", '" + top.resolveFramePath(window) + ".categoryBrowser.refresh();'); }"
        );
    }
    if (currentItem.isWebCategory) {
      var contextMenu_publisherSettings = categoryBrowser.treeContextMenu.addMenuItem([top.o2.lang.getString('o2.desktop.treeContextMenu.publisherSettings'), "/images/system/confg_16.gif"],
        "top.openInFrame('/o2cms/Category-PublisherSettings/edit?categoryId=" + currentItem.id + "', top.getIconUrl('" + currentItem.className + "'), '" + o2.lang.getString('o2.Category.PublisherSettings.frameTitle') + " " + currentItem.metaName + "');"
        );
    }
    if (currentItem.className == 'O2CMS::Obj::Site') {
      var contextMenu_linkChecker = categoryBrowser.treeContextMenu.addMenuItem([top.o2.lang.getString('o2.desktop.treeContextMenu.checkForBrokenLinks'), "/images/system/find_16.gif"],
        "top.openInFrame('/o2cms/Site-LinkChecker?siteId=" + currentItem.id + "', top.getIconUrl('" + currentItem.className + "'), '" + o2.lang.getString('o2.Site.LinkChecker.frameTitleShort') + "');"
        );
    }

    categoryBrowser.treeContextMenu.showMenu(currentItem.y+20, currentItem.x);
  }

};
