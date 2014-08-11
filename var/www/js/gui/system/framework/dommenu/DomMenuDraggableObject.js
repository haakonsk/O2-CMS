function DomMenuDraggableObject(elmId) {
  this.id = elmId;
  return this;
}

DomMenuDraggableObject.prototype.getDragDataById = function(id) {
  var dragIcon = document.getElementById("dragIcon_"+id);
  return {
    'id'        : id,
    'className' : 'O2CMS::Obj::DomMenu::MenuItem',
    'dragIconUrl' : dragIcon.src,
    'iconUrl'     : dragIcon.src,
    'menuAction'  : dragIcon.getAttribute('menuAction')
  };
}

DomMenuDraggableObject.prototype.ondragstart = function(source) {
//  categoryBrowser.setDraggedItem(source.element);
}

DomMenuDraggableObject.prototype.ondragend = function(source, target) {
//  categoryBrowser.removeDraggedItem();
}

DomMenuDraggableObject.prototype.ondrop = function(source, target) {
  alert(source+" "+target);
// categoryBrowser.handleDrop(source, target);
}
