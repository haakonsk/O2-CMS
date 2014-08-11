function DesktopDraggableObject(elmId) {
  this.id = elmId;
  return this;
}

DesktopDraggableObject.prototype.getDragDataById = function(id) {
  var dragIconUrl = document.getElementById("shortcutImage_"+id).src;
  return {
    'id'          : id,
    'className'   : 'O2CMS::Obj::Desktop::Shortcut',
    'dragIconUrl' : dragIconUrl
  };
}

DesktopDraggableObject.prototype.ondragstart = function(source) {
}

DesktopDraggableObject.prototype.ondragend = function(source, target) {
}

DesktopDraggableObject.prototype.ondrop = function(source, target, event) {
  desktop.handleOnDropEvent(source, target, event);                                     
}
