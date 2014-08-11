function CategoryBrowserDraggableObject(elmId) {
  this.id = elmId;
  return this;
}

CategoryBrowserDraggableObject.prototype.getDragDataById = function(id) {
  id = id.replace(/imageFor/, "");
  var categoryBrowserItem = document.getElementById(id);
  return {
    'id'        : id,
    'className' : categoryBrowserItem.getAttribute("package")
  };
}

CategoryBrowserDraggableObject.prototype.ondragstart = function(source) {
  categoryBrowser.setDraggedItem(source.element);
}

CategoryBrowserDraggableObject.prototype.ondragend = function(source, target) {
  categoryBrowser.removeDraggedItem();
}

CategoryBrowserDraggableObject.prototype.ondrop = function(source, target) {
  categoryBrowser.handleDrop(source, target);
}
