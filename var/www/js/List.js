/**
  Provides a basic webpage list.
  Each item is a hash of values where "value" and "text" are mandatory. "value" is used for identifying the item (like objectId), and "text" contains the item html.
  The api are centered around the position of the items ("ix").
*/

var LIST_OBJECTS = {};
var UNNECESSARY_EVENTS_REMOVED = false;

function listHandleKeyPress(e, eventType) {
  eventType = eventType || "keypress";

  // We added too many key-events (3) in List constructor (to support different browsers), here we remove the ones we don't use:
  if (!UNNECESSARY_EVENTS_REMOVED) {
    if (eventType !== "keydown") {
      o2.removeEvent(document, "keydown", listHandleKeyDown);
    }
    if (eventType !== "keyup") {
      o2.removeEvent(document, "keyup", listHandleKeyUp);
    }
    if (eventType !== "keypress") {
      o2.removeEvent(document, "keypress", listHandleKeyPress);
    }
    UNNECESSARY_EVENTS_REMOVED = true;
  }

  for (var elementId in LIST_OBJECTS) {
    var list = LIST_OBJECTS[elementId];

    if (e.getKeyCode() === 46) { // Delete
      list.removeSelected();
    }
  }
}

function listHandleKeyDown(e) {
  listHandleKeyPress(e, "keydown");
}

function listHandleKeyUp(e) {
  listHandleKeyPress(e, "keyup");
}

function List(elementId) {
  this.id = elementId;
  this.items = [];
  LIST_OBJECTS[elementId] = this;

  // We don't know which of the event types the browser supports, so initially, we add all of them. listHandleKeyPress removes 2.
  o2.addEvent( document, "keypress",  listHandleKeyPress );
  o2.addEvent( document, "keydown",   listHandleKeyDown  );
  o2.addEvent( document, "keyup",     listHandleKeyUp    );
}

List.prototype.addItem = function(item) {
  var elm = document.createElement('div');
  elm.setAttribute('id', this.id+'_'+this.items.length);
  elm.className = document.getElementById(this.id).className + (item.selected ? 'Selected' : 'Unselected');
  document.getElementById(this.id).appendChild(elm);
  this.items.push(item);
  elm.innerHTML = this.getItemHtml(item, this.items.length-1);
  return this.items.length-1;
}

List.prototype.addItemAfter = function(item, ix) {
  for (var i = this.items.length; i > ix; i--) {
    this.items[i] = this.items[i-1];
  }
  var realIndex = ix;
  if (ix < 0) {
    realIndex = 0;
  }
  else if (ix > this.items.length-1) {
    realIndex = this.items.length-1;
  }
  else {
    realIndex = ix+1;
  }
  this.items[realIndex] = item;
  this.redraw();
  return realIndex;
}

List.prototype.moveItem = function(fromIx, toIx) {
  if( fromIx==toIx ) return toIx;
  var item = this.getItemAt(fromIx);
  this.removeItemAt(fromIx);
  this.addItemAfter(item, toIx-1);
  return toIx;
}

List.prototype.removeItemAt = function(ix) {
  var newItems = [];
  for( var i=0; i<this.items.length; i++ ) {
    if( i!=ix ) newItems[newItems.length] = this.items[i];
  }
  this.items = newItems;
  this.redraw();
}

List.prototype.removeAll = function() {
  this.items = [];
  this.redraw();
}

List.prototype.removeSelected = function() {
  var remove = this.listSelectedValues();
  for( var i=0; i<remove.length; i++ ) {
    var ix = this.getIndexByValue(remove[i]);
    this.removeItemAt(ix);
  }
}


List.prototype.setItemAt = function(item, ix) {
  this.items[ix] = item;
  this.redraw();
  return ix;
}

List.prototype.redraw = function() {
  var html = '';
  var className = document.getElementById(this.id).className;
  for( var i=0; i<this.items.length; i++ ) {
    if( !this.items[i] ) alert('at '+i+' length '+this.items.length+' '+this.items[i]);
    html += '<div id="'+this.id+'_'+i+'" class="'+ className + (this.items[i].selected ? 'Selected' : 'Unselected') +'">'+this.getItemHtml(this.items[i], i)+'</div>';
  }
  document.getElementById(this.id).innerHTML = html;
}

List.prototype.getItemHtml = function(item, ix) {
  return '<div onclick="getComponentById(\''+this.id+'\').onItemClick('+ix+')">'+item.text+'</div>';
}


List.prototype.selectItem = function(ix) {
  this.items[ix].selected = true;
  document.getElementById(this.id+'_'+ix).className = document.getElementById(this.id).className+'Selected';
}

List.prototype.unselectItem = function(ix) {
  this.items[ix].selected = false;
  document.getElementById(this.id+'_'+ix).className = document.getElementById(this.id).className+'Unselected';
}

List.prototype.selectAll = function() {
  var className = document.getElementById(this.id).className+'Selected';
  for( var i=0; i<this.items.length; i++ ) {
    this.items[i].selected = true;
    document.getElementById(this.id+'_'+i).className = className;
  }
}

List.prototype.unselectAll = function() {
  var className = document.getElementById(this.id).className+'Unselected';
  for( var i=0; i<this.items.length; i++ ) {
    this.items[i].selected = false;
    document.getElementById(this.id+'_'+i).className = className;
  }
}

List.prototype.listSelectedValues = function() {
  var values = [];
  for( var i=0; i<this.items.length; i++ ) {
    if( this.items[i].selected==true ) values[values.length] = this.items[i].value;
  }
  return values;
}

List.prototype.listValues = function() {
  var values = [];
  for( var i=0; i<this.items.length; i++ ) {
    values[values.length] = this.items[i].value;
  }
  return values;
}

// override to sort on different key(s)
List.prototype.sort = function() {
  this.items.sort(function(a,b) {
    return a.text>b.text ? 1 : -1;
  });
  this.redraw();
}

// called when an item is clicked
List.prototype.onItemClick = function(ix) {
  this.items[ix].selected ? this.unselectItem(ix) : this.selectItem(ix);
}

// returns item hash based on ix
List.prototype.getItemAt = function(ix) {
   return this.items[ix];
}

// returns item hash based on value
List.prototype.getItemByValue = function(value) {
  var ix = this.getIndexByValue(value);
  return this.items[ix];
}

List.prototype.getIndexByValue = function(value) {
  for( var ix=0; ix<this.items.length; ix++ ) {
    if( this.items[ix].value == value ) return ix;
  }
}


// number of items in the list
List.prototype.length = function() {
  return this.items.length;
}
