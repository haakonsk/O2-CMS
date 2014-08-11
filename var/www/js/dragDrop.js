o2.require("/js/componentBase.js");
o2.require("/js/windowUtil.js");

if (!top.isDragging) {
  top.isDragging    = false;  // true if we're dragging right now
  top.source        = null;   // hash with data about the source of the dragging
  top.currentWindow = null;   // contains window where mouse is currently over
  top.dragIconHtml  = null;
}
self.dragElement = null; // div element for drag icon

//align the dragItem in the middle of the dragElement
top.alignDragItemCenter = false;
//detect click and not exec drag and drop events
top.avoidClick = true;

o2.addLoadEvent(initDragDrop);

function initDragDrop(e) {
  o2.addEvent( document, "mousedown", mouseDown );
  o2.addEvent( document, "mousemove", mouseMove );
  o2.addEvent( document, "mouseup",   mouseUp   );
}

function debug(type, msg) {
  return;
  console.log(type + ": " + msg);
}

// setup mouse events for an element containing 
function initDragContainer(dragContainerElement, options) {
  if (!dragContainerElement || !dragContainerElement.nodeType == 1) {
    return alert("initDragContainer() called without element");
  }
  dragContainerElement.setAttribute( "ondragstart", "void()" ); // mozilla doesn't see "element.handler = function()"...
  dragContainerElement.setAttribute( "ondrop",      "void()" );
  dragContainerElement.ondragstart   = function() { return false; }; // .. and ie doesn't respect "element.setAttribute(handler)"
  dragContainerElement.ondrop        = function() { return false; };
  dragContainerElement.ondragenter   = function() { return false; };
  dragContainerElement.ondragover    = function() { return false; };
  dragContainerElement.onselectstart = function() { return false; };

  if (!options) {
    options = {};
  }
  if (!options.allowTextSelect) {
    dragContainerElement.onmousedown = function(evt) { // avoid text select
      evt && evt.preventDefault ? evt.preventDefault() : 0;
    };
  }
}

// handle visual part of drag start
function mouseDown(event) {
  //used to guess for a click or drag
  top.ALLOWED_EDITOR = null;
  if (top.avoidClick) {
    top.lastX = event.getX();
    top.lastY = event.getY();
  }
  debug( "dragdrop", "mousedown triggered :" + top.isDragging + " " + event.getX() + " " + event.getY() );
   
  if (top.isDragging) {
    // we didn't receive the mouseup event! clean up.
    top.isDragging = false;
    return;
  }

  // do not trigger drag event with other buttons than left mouse button
  debug("dragdrop", "got event button :" + event.getButton());
  if (event.getButton() != 0) {
    return true;
  }
  
  debug("dragdrop", "mouseDown isDragging: " + top.isDragging);

  if (event.getTarget().tagName != "IMG") {
    return true; // ignore events to non-images
  }

  addMouseEventsToIframes(top);
  event.preventDefault();

  if (dragStart( self, event.getTarget() )) {
    var dragIconUrl = top.source.data.dragIconUrl != null  ?  top.source.data.dragIconUrl                    :  top.getIconUrl(top.source.data.className);
    var dragIconCSS = top.source.data.dragIconCSS != null  ?  'style="' + top.source.data.dragIconCSS + '"'  :  ""; 

    var icon = new Image();
    icon.src = dragIconUrl;
    top.dragElmOffset = getDragItemOffset(icon);

    var win = event.getWindow();
    createDragElement("<img " + dragIconCSS + ' src="' + dragIconUrl + '">', event, win);
    top.currentWindow = win;
  }
  deactivateEditors(); // We're doing this because designMode="on" deactivates scripting.
}

function addMouseEventsToIframes(win) {
  var doc;
  try {
    doc = win.contentWindow  ?  win.contentWindow.document  :  win.contentDocument || win.document;
  }
  catch (error) {
    if (window.console) {
      console.warn( "addMouseEventsToIframes (1):" + o2.getExceptionMessage(error) );
    }
    return false;
  }
  var iframes = doc.getElementsByTagName("iframe");
  for (var i = 0; i < iframes.length; i++) {
    var iframeDoc;
    try {
      iframeDoc = iframes[i].contentDocument  ||  iframes[i].contentWindow.document;
    }
    catch (error) {
      console.warn( "addMouseEventsToIframes (2):" + o2.getExceptionMessage(error) );
    }
    if (iframes[i].getAttribute("isIframe") !== true) {
      iframes[i].setAttribute("isIframe", true);
      o2.addEvent( iframeDoc, "mousemove", mouseMove );
      o2.addEvent( iframeDoc, "mouseup",   mouseUp   );
    }
  }
  for (var i = 0; win.frames && i < win.frames.length; i++) {
    addMouseEventsToIframes( win.frames[i] );
  }
  return true;
}

// handle visual part of dragging
function mouseMove(event) {
  if (!top.isDragging) return;

  debug("dragdrop", "currentwindow: " + top.currentWindow + " " + (top.currentWindow == window) + " " + window.id + " " + window.name);
  var target = event.getTarget();
  var canGetAttribute = false;
  try {
    target.getAttribute("ondrop");
    canGetAttribute = true;
  }
  catch (e) {}
  if (target && canGetAttribute && target.getAttribute("ondrop")) {
    debug("dragdrop", "mouseMove currentTarget:" + target);
  }
  var win = event.getWindow();
  if (top.currentWindow != win) {
    debug("dragdrop: Moved to next frame");
    var dragHtml = top.currentWindow.dragElement.innerHTML;

    debug("dragdrop : " + dragHtml);
    removeDragElement();
    debug( "mouseMove + Moving...." + event.getX() + " " + event.getY() );

    top.currentWindow = win;
    createDragElement(dragHtml, event, top.currentWindow);
  }
  else {
    win = top.currentWindow;
    
    var elementOffsetX,elementOffsetY = 0;
    
    if (!top.alignDragItemCenter) {
      // Actually a hack, but since getScrollOffset moves the element directly to the mouse cursor,
      // we need to move the object a little bit because it blocks dropping.
      // In my opinion half of dragElmOffset is just about right.
      elementOffsetX = (getScrollOffset("X", win) - top.dragElmOffset.x/2);
      elementOffsetY = (getScrollOffset("Y", win) - top.dragElmOffset.y/2);
    }
    else {
      // If it is ok that the element is placed at the cursor, we can just add the getScrollOffset
      elementOffsetX = top.dragElmOffset.x + getScrollOffset("X", win);
      elementOffsetY = top.dragElmOffset.y + getScrollOffset("Y", win);
    }
    var iconWidth = o2.getComputedStyle(top.currentWindow.dragElement, "width");
    win.dragElement.style.left = ((event.getX() ? event.getX() : 0) + elementOffsetX - iconWidth) + "px";
    win.dragElement.style.top  = ((event.getY() ? event.getY() : 0) + elementOffsetY            ) + "px";
    
    win.dragElement.style.display = "block";
  }
  event.stopPropagation(); // Only handle mouseMove in lowest frame
}

function handleDropEvent(event) {
  if (top.isDragging || !top.isDropping) {
    return;
  }
  top.isDropping = false;
  if (event.getTarget().getAttribute("ondrop") != null) {
    debug( "dragdrop: mouseMove currentTarget:" + event.getTarget().id + " " + top.isDragging + " " + top.isDropping );
  }
  dragEnd( self, event.getTarget(), event );
  // Setting dragElement.style.display to none didn't work when an object was dropped in the xinha editor (ie7). Fixing it:
  var win = top.currentWindow;
  win.dragElement.parentNode.removeChild( win.dragElement );
  win.dragElement = null;

  top.currentWindow = null;
}

// handle visual part of drag end
function mouseUp(event) {
  var editorId;
  var iframe = o2.getFrameElement( event.getTarget() );
  var isXinhaIframe = iframe && o2.hasClassName(iframe, "xinha_iframe");
  if (isXinhaIframe) {
    editorId = iframe.id.replace(/^XinhaIFrame_/, "");
  }
  if (!top.isDragging && editorId) {
    var editor = top.xinhaEditors[editorId].editor;
    editor.o2CurrentSelection = editor.saveSelection();
  }
  if (!top.isDragging) {
    return;
  }

  removeDragElement();

  top.isDropping = false;
  debug( "dragdrop", "mouseUp : " + top.isDragging + " " + top.lastX + " == " + event.getX() + "|" + top.lastY + " == " + event.getY() );
  //is a click not a drag action, so we cancel the thing

  if (top.avoidClick &&  top.lastX == event.getX() && top.lastY == event.getY()) { 
    top.isDragging = false;
    top.lastX = top.lastY = -1;
    return true; 
  } 

  // If it's a xinha editor and richText_onDrop exists, then call richText_onDrop:
  if (isXinhaIframe) {
    if (event.getWindow().parent.richText_onDrop) {
      event.getWindow().parent.richText_onDrop(editorId, {event : event});
      activateEditors();
    }
  }

  top.isDragging = false;
  top.isDropping = true;
  debug( "dragdrop", "mouseUp isDropped: " + top.isDragging + " " + event.getX() + " " + event.getY() );
  if (top.alignDragItemCenter) {
    top.lastX = event.getX();
  }
  handleDropEvent(event);
}

// handle non-visual part of drag start (events and data transfers)
function dragStart(targetWin, targetElm) {
  if (top.isDragging) {
    return;
  }
  var dragElm = findParentElmByAttr(targetElm, "dragid");
  if (!dragElm) {
    return false;
  }
  var dragId = dragElm.getAttribute("dragid");
  var componentElm = findParentElmByAttr(targetElm, "ondragstart");

  if (!componentElm) {
    return false;
  }
  if (!componentElm.id) {
    alert("Component element with ondragstart must have id set");
    return false;
  }
  var component = targetWin.getComponentById(componentElm.id);
  if (!component) {
    alert("Can't find component with id \"" + componentElm.id + '"');
    return false;
  }
    
  var data = component.getDragDataById(dragId);
  if (!data) {
    return false; // component says we didn't hit a drag item
  }
  var source = {
    data      : data,
    component : component,
    element   : componentElm,
    window    : targetWin
  };
  if (component.ondragstart) {
    component.ondragstart(source);
  }
  if (componentElm.getAttribute("xondragstart")) {
    eval(componentElm.getAttribute("xondragstart"));
  }
  top.source = source;
  top.isDragging = true;

  debug("dragStart", "done");
  return true;
}

// handle non-visual part of drag end (events data transfers)
function dragEnd(targetWin, targetElm, event) {
  top.isDragging = false;
  var componentElm = findParentElmByAttr(targetElm, "ondrop");
  if (componentElm) {
    var component = targetWin.getComponentById(componentElm.id);
    if (!component) {
      alert("Can't find component with id \"" + componentElm.id + '"');
      return false;
    }
    var data = null;
    var dropElm = findParentElmByAttr(targetElm, "dropid");
    if (dropElm) {
      var dropId = dropElm.getAttribute("dropId");
      data = dropId!=null ? component.getDragDataById(dropId) : null;
    }
    var target = {
      data      : data,
      component : component,
      element   : componentElm,
      window    : targetWin
    };
    var source = top.source;
    if (component.ondrop) {
      component.ondrop(source, target, event);
    }
    if (source && source.component.ondragend) {
      source.component.ondragend(source, target, event); // XXX if-test to avoid text drag
    }
    if (target.element.getAttribute("xondrop")) {
      eval( target.element.getAttribute("xondrop") );
    }
    if (source.element.getAttribute("xondragend")) {
      eval( source.element.getAttribute("xondragend") );
    }
    return true;
  }
  return false;
}

// Create drag div in current frame.
function createDragElement(content, event, win) {
  var x = (event.getX() || 0) + top.dragElmOffset.x;
  var y = (event.getY() || 0) + top.dragElmOffset.y;
  debug("createDragElement", "x : " + x + " y: " + y + " content:" + content);
  
  if (!win.dragElement) {
    win.dragElement = win.document.createElement("div"); // window-local elements may be reused
    win.dragElement.style.display = "none";
    win.dragElement.id            = "dragElement";
    var body = win.document.getElementsByTagName("body");
    body[0].appendChild(win.dragElement);
  }
  _initDragElement(win.dragElement, content, x, y);
}

function _initDragElement(elm, content, x, y) {
  elm.innerHTML        = content;
  elm.style["z-index"] = 1200;
  elm.style.zIndex     = 1200;
  elm.style.position   = "absolute";
  elm.style.left       = x + "px";
  elm.style.top        = y + "px";
  elm.style.border     = "0px";
  elm.style.float      = "none";
}

// hide drag div
function removeDragElement() {
  var win = top.currentWindow;
  debug("dragdrop1: removeDragElement if ->" + win.dragElement);
  if (win.dragElement) {
    win.dragElement.style.display = "none";
    debug("dragdrop: removeDragElement if ->" + win.dragElement.style.display);
  }
}

// recursivly search for element with a specific attribute
function findParentElmByAttr(elm, attrName, value) {
  while (elm != null) {
    if (elm.nodeType == 1) {
      var attr = elm.getAttribute(attrName); // XXX hasAttribute() instead?
      if (value == null) {
        if (attr) {
          return elm;
        }
      }
      else if (attr == value) {
        return elm;
      }
    }
    elm = elm.parentNode;
  }
  return null;
}

//20070904 nilschd added to calculate where the dragItem should be placed against the cursor
// The tip of the cursor must not be "hidden" on top of the dragged image.
function getDragItemOffset(elm) {
  var w = elm.width  || elm.offsetWidth;
  var h = elm.height || elm.offsetHeight;
  if (!w || !h) {
    return { x:4, y:4 };
  }
  var x = 0, y = 0;
  if (!elm || !top.alignDragItemCenter) {
    x = (w*-1)-1;
    y = (h*-1)-1;
  }
  else {
    x = (w/2)*-1;
    y = (h/2)*-1;
  }
  return { x:x, y:y };
}

function deactivateEditors() {
  activateEditors(false);
}

function activateEditors(activate) {
  if (typeof(activate) === "undefined") {
    activate = true;
  }

  // Activate
  if (activate) {
    var editor = window._currentXinhaEditor;
    if (!editor) {
      return;
    }
    editor.activateEditor();
    var divs = editor._doc.getElementsByTagName("div");
    for (var i = 0; i < divs.length; i++) {
      if (divs[i].id && divs[i].id == "dragElement") {
        var p = divs[i].parentNode;
        p.removeChild( divs[i] );
      }
    }
    return;
  }

  // Deactivate
  for (var editorName in top.xinhaEditors) {
    var editor = top.xinhaEditors[editorName].editor;
    if (editor == null  ||  typeof(editor) !== "object" ||  !top.xinhaEditors[editorName].isInitialized) {
      continue;
    }
    editor.deactivateEditor();
  }
}

function getScrollOffset(dimension, window){
  // Will return offset based on scroll - dimension decides which axis to return
  // example getScrollOffset("X") will return scrollX
  // Note, window must be passed in case we are dragging into iframes - yuck
  
  var scrollX, scrollY;
  
  if ( typeof(window.pageYOffset) == "number" ) {
    scrollX = window.pageXOffset;
    scrollY = window.pageYOffset;
  }
  
  // return scroll position
  if (dimension == "X") {
    return scrollX;
  }
  else {
    return scrollY;
  }
}
