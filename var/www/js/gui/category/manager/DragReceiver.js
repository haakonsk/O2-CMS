function CategoryBrowserDragReceiver(elmId) {}

CategoryBrowserDragReceiver.prototype.ondrop = function(source, target) {
  categoryBrowser.handleDrop(source, target);
}

CategoryBrowserDragReceiver.prototype.getDragDataById = function(id) {
  id = id.replace(/imageFor/, "");
  var categoryBrowserItem = document.getElementById(id);
  return {
    'id'        : id,
    'className' : categoryBrowserItem.getAttribute("package")
  };
}
