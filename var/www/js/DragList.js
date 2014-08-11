/**
List of draggable objects (subclass of List.js)
DragLists should be initialized via the taglib.

Example:
<o2 use Html::DragList/>
<o2 dragList id="myDragList"/>

Other attributes available on draglist element:
allowClass="O2CMS::Obj::Article,O2::Obj::Image" - only allow drop of Article and Image objects
removeOnDragEnd="yes"                           - remove item from list when dragged to another list
reorganize="no"                                 - do not allow list to be reorganized by dragging items to a new position
unique="yes"                                    - do not add item if it already exists in list
replace="yes"                                   - replace item under mouse on drop (instead of adding)

If the id of the dragList ends with [], eg id="object.urlIds[]", then we create multiple input fields with names equal to that id. Then
$obj->getParam('object.urlIds') will return an array. If the id does not end with [], then only one input field is created and the value
is a comma separated list of values (usually object ids).
*/

o2.require("/js/ajax.js");
o2.require("/js/DOMUtil.js");

o2.addLoadEvent(initHiddenInputFields);

function initHiddenInputFields() {
  for (var elementId in LIST_OBJECTS) {
    var list = LIST_OBJECTS[elementId];
    list.updateInputFields();
  }
}

DragList.prototype = List.prototype;
DragList.prototype.superclass = List.prototype;

function DragList(elementId) {
  List.call(this, elementId); // Call constructor in super class (List)
  var dragList = document.getElementById(this.id);
  initDragContainer(dragList);
  if (!this.id.match(/\[\]$/)) {
    this.inputField = document.createElement("input");
    this.inputField.setAttribute("type", "hidden");
    this.inputField.setAttribute("name", this.id);
    dragList.parentNode.appendChild(this.inputField);
  }
}


DragList.prototype.getItemHtml = function(item,ix) {
  return '<div onmousedown="getComponentById(\''+this.id+'\').onItemDown(event,'+ix+')" onclick="getComponentById(\''+this.id+'\').onItemClick('+ix+')" dropid="'+ix+'"><nobr><img src="'+item.iconUrl+'" dragid="'+ix+'"> <span class="itemName">'+item.name+'</span></nobr></div>';
}


DragList.prototype.updateInputFields = function() {
  var dragList = document.getElementById(this.id);

  if (this.id.match(/\[\]$/)) {
    var form   = o2.getClosestAncestorByTagName(dragList, "form");
    var inputs = form.getElementsByClassName("dragListHiddenInput");
    for (var i = inputs.length-1; i >= 0; i--) {
      if (inputs[i].name === this.id) {
        inputs[i].parentNode.removeChild( inputs[i] );
      }
    }

    for (var i = 0; i < this.items.length; i++) {
      if (value !== "") {
        inputField = document.createElement("input");
        inputField.setAttribute( "type",  "hidden"         );
        inputField.setAttribute( "name",  this.id          );
        inputField.setAttribute( "value", this.items[i].id );
        o2.addClassName(inputField, "dragListHiddenInput");
        value += this.items[i].id;
        form.appendChild(inputField);
      }
    }
  }
  else {
    var value = "";
    for (var i = 0; i < this.items.length; i++) {
      if (value !== "") {
        value += ",";
      }
      value += this.items[i].id;
    }
    this.inputField.value = value;
  }
}

DragList.prototype.getDragDataById = function(ix) {
  var item = this.getItemAt(ix);
  item.ix = ix;
  return item;
}

DragList.prototype.allowObjectDrop = function(className) {
  var allowClass = document.getElementById(this.id).getAttribute("allowClass");
  if (!allowClass || allowClass.indexOf("::") === -1) {
    return true;
  }
  var classes = allowClass.split(",");
  for (var i = 0; i < classes.length; i++) {
    if (classes[i] === className) {
      return true;
    }
  }
  return false;
}

DragList.prototype.removeSelected = function() {
  // XXX Should have called removeSelected in super class, but then I got a "too much recursion" error for some reason...
  var selected = this.listSelectedValues();
  for (var i = 0; i < selected.length; i++ ) {
    this.removeItemAt(  this.getIndexByValue( selected[i] )  );
  }
  this.updateInputFields();
}

DragList.prototype.ondragstart = function(source) {
//  alert('start');// _debug('dragstart: '+source.element.id+'/'+source.data.text);
}

DragList.prototype.ondragend = function(source, target) {
  var dragList = document.getElementById(this.id);
  var onChange = dragList.getAttribute("onChange");
  if (target.data.className === "O2CMS::Obj::Trashcan") {
    this.updateInputFields();
  }
  if (!target.dropAccepted) {
    return; // the receiver didn't accept drop
  }
  eval(onChange);
  var removeOnDragEnd = dragList.getAttribute("removeOnDragEnd");
  if (!removeOnDragEnd || removeOnDragEnd.toLowerCase() !== "yes" || source.component === target.component) {
    return;
  }
  this.removeItemAt( parseInt(source.data.ix) );
}

DragList.prototype.ondrop = function(source, target) {
  var dragList = document.getElementById(this.id);
  var onChange = dragList.getAttribute("onChange");
  if (!this.allowObjectDrop(source.data.className)) {
    return alert("That object is not allowed here");
  }
  target.dropAccepted = true;
  eval(onChange);

  var iconSize = dragList.getAttribute("iconSize");
  if (iconSize) {
    if (source.data.iconUrl.match(/-16\.\w+$/)) {
      source.data.iconUrl = source.data.iconUrl.replace(/-16\./, "-" + iconSize + ".");
    }
    else if (source.data.iconUrl.match(/16x16/)) {
      source.data.iconUrl = source.data.iconUrl.replace(/16x16/, iconSize + "x" + iconSize);
    }
  }

  var index;
  if (source.component === target.component) { // reorganize
    if (!target.data) {
      return;
    }
    var reorganize = dragList.getAttribute("reorganize");
    if (!(reorganize && reorganize.toLowerCase() === "no")) {
      index = this.moveItem(source.data.ix, target.data.ix);
    }
  }
  else { // drop from somewhere else
    var unique = dragList.getAttribute("unique");
    unique = unique ? unique.toLowerCase() : "yes";
    if (unique === "yes" && this.getItemByValue(source.data.id)) {
      return;
    }

    source.data.value = source.data.id; // make sure id is used as value. XXX since it's a "hash-reference", it will modify source hash as well...
                                        // XXX this may cause problems with IE. we might store a reference that is defined in a different window, when that window closes the hash might die with it...

    if (target.data) { // hit an existing item
      var replace = dragList.getAttribute("replace");
      if (replace && replace.toLowerCase() === "yes") {
        index = this.setItemAt( source.data, parseInt(target.data.ix) );
      }
      else {
        index = this.addItemAfter( source.data, parseInt(target.data.ix) );
      }
    }
    else {
      index = this.addItem(source.data);
    }
  }
  this.updateInputFields();

  if (dragList.getAttribute("textMethodName")) {
    o2.ajax.call({
      setDispatcherPath : "o2cms",
      setClass          : "Universal",
      setMethod         : "callObjectMethod",
      setParams         : "methodName=" + dragList.getAttribute("textMethodName") + "&objectId=" + source.data.id + "&dragListId=" + this.id + "&itemIndex=" + index,
      handler           : "updateItemText"
    });
  }
}

function updateItemText(params) {
  var dragList     = getComponentById( params.dragListId );
  var itemNameNode = document.getElementById( dragList.id ).getElementsByClassName("itemName")[ params.itemIndex ];
  itemNameNode.innerHTML = params.returnValue;
}

function onChangeCallback(onChange) {
  eval(onChange);
}
