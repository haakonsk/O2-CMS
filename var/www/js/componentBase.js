var _components = {};

function getComponentById(id) {
  if (_components[id] != null) {
    return _components[id];
  }
  if (id == null) {
    return null;
  }
  var elm = document.getElementById(id);
  if (elm == null) {
    return null;
  }
  var componentClass = elm.getAttribute("component");
  if (componentClass == null) {
    return null;
  }
  var object = eval("new " + componentClass + '("' + id + '")');
  _components[id] = object;
  return _components[id];
}

function serializeAllComponents() {
  var serialized = "";
  for (var id in _components) {
    var component = _components[id];
    if (component != null) {
      serialized += '<component id="' + id + '">' + component.getSerialized() + "</component>";
    }
  }
  return serialized;
}
