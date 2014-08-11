// Disable right click
document.oncontextmenu = function () {
  return false;
}

var frameSwitchButtons = new Array();

var activeFrameId;
var defaultIconSize = 22; // Padding-left value
var stringPadding   = "...";

function toggleMenu(menu) {
  top.middleFrame.toggleMenu();
}

var a = 0;
function focusFrameSwitchButton(frameId) {
  if (activeFrameId) {
    var fsbutton = document.getElementById("fsb" + activeFrameId);
    if (fsbutton) {
      fsbutton.className = "inactiveTask";
    }
  }
  var fsbutton = document.getElementById("fsb" + frameId);
  if (fsbutton) {
    fsbutton.className = "activeTask";
  }
  activeFrameId = frameId;
}

function addFrameSwitchButton(obj) {
  if (!obj || !obj.frameId || !obj.text || !obj.icon) {
    alert("Tried to add a frameSwitchButton without having sent all needed parameteres");
    return;
  }

  var taskRow = document.getElementById("taskRow");
  if (!frameSwitchButtons[obj.frameId]) {
    taskRow.appendChild(createFrameButton(obj));
  }

  frameSwitchButtons[obj.frameId] = obj;
  realignTaskButtons();
  focusFrameSwitchButton(obj.frameId);
}

function removeFrameSwitchButton(frameId) {
  document.getElementById("taskRow").removeChild( document.getElementById("fsb"+frameId) );
  frameSwitchButtons[frameId] = null;
  realignTaskButtons();
}

function updateFrameSwitchButton(obj) {
  if (!obj || !obj.frameId || !(obj.text || obj.icon)) {
    return alert("updateFrameSwitchButton: Need frameId parameter and either text or icon or both");
  }
  var button = document.getElementById("fsb" + obj.frameId); // It's a td tag
  if (!button) {
    return alert("updateFrameSwitchButton: Didn't find the button");
  }
  var div = button.childNodes[0];
  if (obj.icon) {
    div.style.backgroundImage = "url('" + obj.icon + "')";
  }
  if (obj.text) {
    div.innerHTML = "<nobr>" + obj.text + "</nobr>";
  }
  frameSwitchButtons[ obj.frameId ] = obj;
  realignTaskButtons();
  focusFrameSwitchButton(obj.frameId);
}

function createFrameButton(obj) {
  var td = document.createElement("td");
  td.setAttribute("id", "fsb" + obj.frameId);
  td.frameId = obj.frameId;
  td.onmousedown   = new Function("top.switchToFrameId('" + obj.frameId + "');");
  td.oncontextmenu = handleEvent;
  var div = document.createElement("div");
  div.frameId = obj.frameId;
  div.style.backgroundImage = "url('" + obj.icon + "')";
  div.innerHTML = "<nobr>" + obj.text + "</nobr>";
  td.title = obj.text;
  td.appendChild(div);
  return td;
}

function handleEvent(e) {
  var evt = new top.O2Event(window,e);
  var src = evt.getTarget();
  if (!src.frameId) { // The target/source element returned is a little unpredictable... (sometimes span, sometimes div, sometimes table cell)
    src = src.parentNode;
  }
  top.middleFrame.showTaskBarMenu({
    x       : evt.getX(),
    y       : evt.getY(),
    frameId : src.frameId
  });
}

function realignTaskButtons() {
  var innerWidth = top.window.innerWidth || document.documentElement.offsetWidth - 20;
  var wWidth     = innerWidth  -  (document.getElementById("toolButton").offsetWidth + document.getElementById("showDesktopButton").offsetWidth);
  var tbWidth    = document.getElementById("taskContainer").offsetWidth;

  var newWidth = wWidth;
  if (frameSwitchButtons.length > 1) {
    newWidth = parseInt(wWidth/(frameSwitchButtons.length-1));
  }

  var taskRow = document.getElementById("taskRow");

  // Calculate basic char width, this is a just a good guess alg.
  // var oldText = taskRow.childNodes[0].childNodes[0].innerHTML;
  // taskRow.childNodes[0].childNodes[0].innerHTML="a"; //widest char in Latin, next to W?
  // var charWidth=parseInt(taskRow.childNodes[0].childNodes[0].offsetWidth-defaultIconSize);
  // taskRow.childNodes[0].childNodes[0].innerHTML=oldText;
  // the above alg. didn't work in mozilla. Got wrong width out randomly
  var charWidth = 7; //there for the hard coding of pixelwidth
  
  var addPadding = "";
  if (charWidth * totChars > newWidth) {
    addPadding = stringPadding;
  }

  for (var i = 0; i < taskRow.childNodes.length; i++) {
    var text = frameSwitchButtons[taskRow.childNodes[i].frameId].text;
    var totChars = parseInt(newWidth / charWidth) - stringPadding.length;
    taskRow.childNodes[i].childNodes[0].innerHTML = "<nobr>" + (text.substring(0, totChars) + addPadding) + "</nobr>";
    taskRow.childNodes[i].style.width = newWidth;
  }
}

function Trashcan(id) {
  this.id = id;
  initDragContainer( document.getElementById(id) );
}

Trashcan.prototype.ondrop = function(source, target, event) {
  var onChange = source.window.document.getElementById(source.component.id).getAttribute("onChange");

  if (source.window.onChangeCallback) {
    source.window.onChangeCallback(onChange);
  }

  if (source.component.id.indexOf("menuTree_") == 0) { // Drag from MenuEditor
    source.component.removeItemById(source.data.id);
  }
  else if (source.component.id == "tree" ) { // Drag from treemenu
    source.component.move(source.data.id, top.getTrashcanId());
  }
  else if (source.component.id === "o2SearchResultList") { // Drag from search result
    var tree = top.frames.middleFrame.frames.left.getComponentById("tree");
    tree.move( source.data.id, top.getTrashcanId() );
    var index = source.component.getIndexByValue( source.data.id );
    if (!index && index != "0") return;
    source.component.removeItemAt(index);
  }
  else if ( source.component.id.indexOf("menuTree_") >- 1 ) { // Drag from menu editor
    source.component.removeItemById(source.data.id);
  }
  else if ( source.component.id.indexOf("slot_") == 0 ) { // Drag from a slot
    source.window.getComponentById( source.component.id ).removeSlot();
  }
  else if(source.component.id.indexOf("shortcutImage_") == 0) { // Drag from desktop to delete
    source.window.desktop.deleteShortcut(source.component.id);
  }
  else if (o2.hasClassName(source.element, "categoryBrowserItemIcon")) { // Drag from category browser
    source.window.categoryBrowser.deleteSelectedOrDragged( event, source.window.categoryBrowser.getItem( source.element ) );
  }
  else {
    var index = source.component.getIndexByValue( source.data.id );
    if (!index && index != "0") {
      return;
    }
    source.component.removeItemAt(index);
  }
}

Trashcan.prototype.getDragDataById = function(id) {
  return {
    "id"        : -1,
    "className" : "O2CMS::Obj::Trashcan"
  };
}
