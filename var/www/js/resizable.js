var o2Resizable = {

  initialMouseX   : null,
  initialMouseY   : null,
  currentEdge     : null,

  instances       : new Array(), // Got to support multiple draggable elements at the same time (although it's just possible to drag one at a time).
  currentInstance : null,
  autoId          : 0,

  setupResizable : function(params) {
    var elm = params.element;

    if (params.top    !== undefined) { elm.style.top    = params.top    + "px"; }
    if (params.right  !== undefined) { elm.style.right  = params.right  + "px"; }
    if (params.bottom !== undefined) { elm.style.bottom = params.bottom + "px"; }
    if (params.left   !== undefined) { elm.style.left   = params.left   + "px"; }
    if (params.width  !== undefined) { elm.style.width  = params.width  + "px"; }
    if (params.height !== undefined) { elm.style.height = params.height + "px"; }

    var directions = params.allowedDirections  ?  params.allowedDirections.split(",")  :  new Array("n", "ne", "e", "se", "s", "sw", "w", "nw", "n");
    var elmId = elm.id || "o2Resizable_" + (o2Resizable.autoId++);


    o2Resizable.instances[elmId] = {
        "resizeElement"     : elm,
        "initialStyles"     : new Array(),
        "allowedDirections" : new Array(),
        "edgeThickness"     : params.edgeThickness     || 3,
        "resizeEndCallBack" : params.resizeEndCallBack || null
    };

    o2Resizable.currentInstance = o2Resizable.instances[elmId];
    for (var i = 0; i < directions.length; i++) {
      o2Resizable.currentInstance.allowedDirections[ directions[i] ] = 1;
    }
    o2Resizable.createEdgeDivs();
  },

  startResize : function(e) {
    e.stopPropagation();
    o2.addEvent(document, "mousemove", o2Resizable.handleResize);
    o2.addEvent(document, "mouseup",   o2Resizable.endResize);
    o2Resizable.initialMouseX = parseInt( e.getX() );
    o2Resizable.initialMouseY = parseInt( e.getY() );
    o2Resizable.currentEdge = e.getTarget();

    o2Resizable.currentInstance = o2Resizable.instances[ o2Resizable.currentEdge.parentNode.id ];

    // We can't just do it in setupResizable, because the window may have been dragged in the meantime.
    var elmGeom = o2Resizable._elementGeometry(o2Resizable.currentInstance.resizeElement);
    o2Resizable.currentInstance.initialStyles.top    = elmGeom.top;
    o2Resizable.currentInstance.initialStyles.left   = elmGeom.left;
    o2Resizable.currentInstance.initialStyles.bottom = elmGeom.bottom;
    o2Resizable.currentInstance.initialStyles.right  = elmGeom.right;
    o2Resizable.currentInstance.initialStyles.width  = elmGeom.width;
    o2Resizable.currentInstance.initialStyles.height = elmGeom.height;

    
    //iframe support to avoid laggy mouse mouse

    var div =  document.createElement("div");
    div.id = "__o2ResizAble_dialogResizeDiv";
    div.style.position   = "absolute";
    div.style.left       = elmGeom.left   + "px";
    div.style.width      = elmGeom.width  + "px";
    div.style.top        = elmGeom.top    + "px";
    div.style.height     = elmGeom.height + "px";
    div.style.opacity    = 0.5;
    div.style.zIndex     = 10000;
    div.style.background = "lightgray";
    div.style.border     = "1px dotted black";
    document.body.appendChild(div);

    o2Resizable.resizeDiv = div;
    return false;
  },

  handleResize : function(e) {
    e.stopPropagation();
    var deltaX = e.getX() - o2Resizable.initialMouseX;
    var deltaY = e.getY() - o2Resizable.initialMouseY;
    var elm = o2Resizable.resizeDiv;
    var className = o2Resizable.currentEdge.className;

    if (className == "resizableBottom" || className == "resizableBottomLeft" || className == "resizableBottomRight") {
      if (o2Resizable.currentInstance.initialStyles.height) {
        elm.style.height = (parseInt(o2Resizable.currentInstance.initialStyles.height) + deltaY) + "px";
      }
      else if (o2Resizable.currentInstance.initialStyles.bottom) {
        elm.style.bottom = (parseInt(o2Resizable.currentInstance.initialStyles.bottom) - deltaY) + "px";
      }
    }

    if (className == "resizableTop" || className == "resizableTopLeft" || className == "resizableTopRight") {
      if (o2Resizable.currentInstance.initialStyles.top) {
        elm.style.top = (parseInt(o2Resizable.currentInstance.initialStyles.top) + deltaY) + "px";
        if (o2Resizable.currentInstance.initialStyles.height) {
          elm.style.height = (parseInt(o2Resizable.currentInstance.initialStyles.height) - deltaY) + "px";
        }
      }
    }

    if (className == "resizableRight" || className == "resizableTopRight" || className == "resizableBottomRight") {
      if (o2Resizable.currentInstance.initialStyles.width) {
        elm.style.width = (parseInt(o2Resizable.currentInstance.initialStyles.width) + deltaX) + "px";
      }
      else if (o2Resizable.currentInstance.initialStyles.right) {
        elm.style.right = (parseInt(o2Resizable.currentInstance.initialStyles.right) - deltaX) + "px";
      }
    }

    if (className == "resizableLeft" || className == "resizableTopLeft" || className == "resizableBottomLeft") {
      if (o2Resizable.currentInstance.initialStyles.left) {
        elm.style.left = (parseInt(o2Resizable.currentInstance.initialStyles.left) + deltaX) + "px";
        if (o2Resizable.currentInstance.initialStyles.width) {
          elm.style.width = (parseInt(o2Resizable.currentInstance.initialStyles.width) - deltaX) + "px";
        }
      }
    }
  },

  endResize : function(e) {
    e.stopPropagation();
    o2.removeEvent( document, "mousemove", o2Resizable.handleResize );
    o2.removeEvent( document, "mouseup",   o2Resizable.endResize    );

    var elm  = o2Resizable.currentInstance.resizeElement;
    var rElm = o2Resizable.resizeDiv;
    elm.style.left   = rElm.style.left;
    elm.style.top    = rElm.style.top;
    elm.style.height = rElm.style.height;
    elm.style.width  = rElm.style.width;
    
    document.body.removeChild(rElm);
    o2Resizable.resizeDiv = null;

    if (o2Resizable.currentInstance.resizeEndCallBack) {
      try {
        o2Resizable.currentInstance.dragEndCallback.call(this, e, o2Resizable.currentInstance);
      }
      catch (error) {
        if (window.console) {
          console.error( "Error performing callback on:", o2Resizable.currentInstance, o2.getExceptionMessage(error) );
        }
      }
    }
  },

  createEdgeDivs : function() {
    var a = o2Resizable.currentInstance.edgeThickness;
    if (o2Resizable.currentInstance.allowedDirections.n)  { o2Resizable.createEdgeDiv(0, a, null, a, null, a, "n-resize",          "resizableTop"); }
    if (o2Resizable.currentInstance.allowedDirections.w)  { o2Resizable.createEdgeDiv(a, null, a, 0, a, null, "w-resize",         "resizableLeft"); }
    if (o2Resizable.currentInstance.allowedDirections.e)  { o2Resizable.createEdgeDiv(a, 0, a, null, a, null, "e-resize",        "resizableRight"); }
    if (o2Resizable.currentInstance.allowedDirections.s)  { o2Resizable.createEdgeDiv(null, a, 0, a, null, a, "s-resize",       "resizableBottom"); }
    if (o2Resizable.currentInstance.allowedDirections.nw) { o2Resizable.createEdgeDiv(0, null, null, 0, a, a, "nw-resize",     "resizableTopLeft"); }
    if (o2Resizable.currentInstance.allowedDirections.ne) { o2Resizable.createEdgeDiv(0, 0, null, null, a, a, "ne-resize",    "resizableTopRight"); }
    if (o2Resizable.currentInstance.allowedDirections.sw) { o2Resizable.createEdgeDiv(null, null, 0, 0, a, a, "sw-resize",  "resizableBottomLeft"); }
    if (o2Resizable.currentInstance.allowedDirections.se) { o2Resizable.createEdgeDiv(null, 0, 0, null, a, a, "se-resize", "resizableBottomRight"); }
  },

  createEdgeDiv : function(top, right, bottom, left, width, height, cursor, className, background) {
    var div = document.createElement("div");
    div.style.position = "absolute";
    if (top    !== null) { div.style.top    = top    + "px"; }
    if (right  !== null) { div.style.right  = right  + "px"; }
    if (bottom !== null) { div.style.bottom = bottom + "px"; }
    if (left   !== null) { div.style.left   = left   + "px"; }
    if (width  !== null) { div.style.width  = width  + "px"; }
    if (height !== null) { div.style.height = height + "px"; }
    div.style.cursor = cursor;
    div.className = className;
    o2Resizable.currentInstance.resizeElement.appendChild(div);
    o2.addEvent(div, "mousedown", o2Resizable.startResize);
  },

 
  _elementGeometry : function(elm) {
    if (!elm) return null;
    var x = 0, y = 0, width = elm.offsetWidth, height = elm.offsetHeight, bottom = y+height, right = x+width;
    while (elm.offsetParent) {
      x  += elm.offsetLeft;
      y  += elm.offsetTop;
      elm = elm.offsetParent;
    }
    
    return {
      left   : x,
      top    : y,
      width  : width,
      height : height,
      bottom : y+height,
      right  : x+width
    };
  }

};
