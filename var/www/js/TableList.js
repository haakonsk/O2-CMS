/**
  Provides a basic webpage list.
  Each item is a hash of values where "value" and "text" are mandatory. "value" is used for identifying the item (like objectId), and "text" contains the item html.
  The api is centered around the position of the items ("ix").

*/

function TableList(elementId) {
  this.id = elementId;
  this.items = [];
  this.headers = [];
}

// sets header values
TableList.prototype.setHeaders = function(headers) {
  this.headers = headers;
}

// return html for header
TableList.prototype.getHeader = function() {
  var className = document.getElementById(this.id).className;
  var headerHtml = "";
  for (var i = 0; i < this.headers.length; ++i) {
    headerHtml += "<th>" + this.headers[i] + "</th>";
  }
  return '<table class="' + className + 'Table">' + (headerHtml ? "<tr>" + headerHtml + "</tr>" : "");
}

// return html for footer
TableList.prototype.getFooter = function() {
  return "</table>";
}
TableList.prototype.addItems = function(items,noRender) {
  for (var i = 0; i < items.length; ++i) {
    this.items[this.items.length] = items[i];
  }
  if (!noRender) {
    this.redraw();
  }
}

TableList.prototype.setItems = function(items) {
  this.items = items;
}


TableList.prototype.getItems = function() {
  return this.items;
}

TableList.prototype.getIcon = function(iconType, action, title) {
  if (!iconType || !action) {
    alert("Need both iconType and action to be able to display icon");
    return false;
  }
  return '<a href="' + action + '"><img src="/images/list/' + iconType + '.gif" class="listIcon" title="' + (title ? title : "") + '" border=0></a>';
}

TableList.prototype.getMoveUpIcon = function(item, ix) {
  if (ix == 0) {
    return '<img src="/images/pix.gif" height=15 width=15>';
  }
  return '<a href="javascript:void(getComponentById(\'' + this.id + "').moveItem(" + ix + "," + (ix-1) + '))"><img src="/images/list/up.gif" border=0></a>';
}

TableList.prototype.getMoveDownIcon = function(item, ix) {
  if (ix == this.items.length-1) {
    return '<img src="/images/pix.gif" height=15 width=15>';
  }
  return '<a href="javascript:void(getComponentById(\'' + this.id + "').moveItem(" + ix + "," + (ix+1) + '))"><img src="/images/list/down.gif" border=0></a>';
}

TableList.prototype.addItem = function(item) {
  this.items[this.items.length] = item;
  this.redraw();
}

TableList.prototype.replaceItem = function(item) {
  var l = this.items.length;
  if (l > 0) {
    l = l - 1;
  }
  else {
    l = 0;
  }
  this.items[l] = item;
  this.redraw();
}

TableList.prototype.addItemAfter = function(item, ix) {
  for (var i = this.items.length; i > ix; i--) {
    this.items[i] = this.items[i-1];
  }
  if (ix < 0) {
    this.items[0] = item;
  }
  else if (ix > this.items.length-1) {
    this.items[this.items.length-1] = item;
  }
  else {
    this.items[ix+1] = item;
  }
  this.redraw();
}

TableList.prototype.moveItem = function(fromIx, toIx) {
  if (fromIx == toIx) {
    return;
  }
  var item = this.getItemAt(fromIx);
  this.removeItemAt(fromIx, 1);
  this.addItemAfter(item, toIx-1);
}

TableList.prototype.removeItemAt = function(ix, noRender) {
  var newItems = [];
  for (var i = 0; i < this.items.length; i++) {
    if (i != ix) {
      newItems[newItems.length] = this.items[i];
    }
  }
  this.items = newItems;
  if (!noRender) {
    this.redraw();
  }
}

TableList.prototype.removeItemsByValue = function(value) {
  for (var ix = 0; ix < this.items.length; ix = ix+1) {
    if (this.items[ix].value == value) {
      this.removeItemAt(ix,1);
      ix = -1;
    }
  }
  return false;
}

TableList.prototype.removeAll = function() {
  this.items = [];
  this.redraw();
}

TableList.prototype.removeSelected = function() {
  var remove = this.listSelectedValues();
  for (var i = 0; i < remove.length; i++) {
    var ix = this.getIndexByValue( remove[i] );
    this.removeItemAt(ix);
  }
}

TableList.prototype.setItemAt = function(item, ix) {
  this.items[ix] = item;
  this.redraw();
}

TableList.prototype.setAttributeAt = function(itemAttribute, value, ix) {
  this.items[ix][itemAttribute] = value;
}

TableList.prototype.getAttributeAt = function(itemAttribute, ix) {
  return this.items[ix][itemAttribute];
}

TableList.prototype.redraw = function() {
  var html = this.getHeader();
  var className = document.getElementById(this.id).className;
  for (var ix = 0; ix < this.items.length; ix++) {
    if (!this.items[ix]) {
      alert( "at " + ix + " length " + this.items.length + " " + this.items[ix] );
    }
    html += this.getRowHtml(this.items[ix], ix, className);
  }
  html += this.getFooter();
  document.getElementById(this.id).innerHTML = html;
}

TableList.prototype.getRowHtml = function(item, ix, className) {
    return '<tr id="' + this.id + "_" + ix + '" class="' + className + (item.selected ? "Selected" : "Unselected") +'" onclick="getComponentById(\'' + this.id + "').onItemClick(" + ix + ')" onmouseover="getComponentById(\'' + this.id + "').onMouseOverItem(" + ix + ')" onmouseout="getComponentById(\'' + this.id + "').onMouseOutItem(" + ix + ')">' + this.getRowCellsHtml(item, ix) + "</tr>";
}

TableList.prototype.getRowCellsHtml = function(item, ix) {
  return ("<td>you need to create a custom getRowCellsHtml method</td><td> to display the content you wish</td>");
}

// set item selected or unselected
TableList.prototype.setIsSelectedAt = function(isSelected, ix) {
  isSelected != false ? this.selectItemAt(ix) : this.unselectItemAt(ix);
}

TableList.prototype.selectItemAt = function(ix) {
  this.items[ix].selected = true;
  document.getElementById(this.id + "_" + ix).className = document.getElementById(this.id).className + "Selected";
}

TableList.prototype.unselectItemAt = function(ix) {
  this.items[ix].selected = false;
  document.getElementById(this.id + "_" + ix).className = document.getElementById(this.id).className + "Unselected";
}

TableList.prototype.onMouseOverItem = function(ix) {
  document.getElementById(this.id + "_" + ix).className = document.getElementById(this.id).className + "Hover";
}

TableList.prototype.onMouseOutItem = function(ix) {
  var className = document.getElementById(this.id).className + (this.items[ix].selected ? "Selected" : "Unselected");
  document.getElementById(this.id + "_" + ix).className = className;
}

TableList.prototype.selectAll = function() {
  var className = document.getElementById(this.id).className + "Selected";
  for (var i = 0; i < this.items.length; i++) {
    this.items[i].selected = true;
    document.getElementById(this.id + "_" + i).className = className;
  }
}

TableList.prototype.unselectAll = function() {
  var className = document.getElementById(this.id).className+"Unselected";
  for (var i = 0; i < this.items.length; i++) {
    this.items[i].selected = false;
    document.getElementById(this.id + "_" + i).className = className;
  }
}

TableList.prototype.listItems = function() {
  return this.items;
}
TableList.prototype.listSelectedItems = function() {
  var itemList = [];
  for (var i = 0; i < this.items.length; i++) {
    if (this.items[i].selected == true) {
      itemList[itemList.length] = this.items[i];
    }
  }
  return itemList;
}

TableList.prototype.listSelectedValues = function() {
  var values = [];
  for (var i = 0; i < this.items.length; i++) {
    if (this.items[i].selected == true) {
      values[values.length] = this.items[i].value;
    }
  }
  return values;
}

TableList.prototype.listValues = function() {
  var values = [];
  for (var i = 0; i < this.items.length; i++) {
    values[values.length] = this.items[i].value;
  }
  return values;
}

// override to sort on different key(s)
TableList.prototype.sort = function() {
  this.items.sort(function(a,b) {
    return a.text>b.text ? 1 : -1;
  });
  this.redraw();
}

// called when an item is clicked
TableList.prototype.onItemClick = function(ix) {
}

// called when the pointer is over an item
TableList.prototype.onItemMouseOver = function(ix) {
}

// returns item hash based on ix
TableList.prototype.getItemAt = function(ix) {
  return this.items[ix];
}

// returns item hash based on value
TableList.prototype.getItemByValue = function(value) {
  return this.items[ this.getIndexByValue(value) ];
}

TableList.prototype.getIndexByValue = function(value) {
  for (var ix = 0; ix < this.items.length; ix++) {
    if (this.items[ix].value == value) {
      return ix;
    }
  }
  return false;
}

// return number of items in list
TableList.prototype.length = function() {
  return this.items.length;
}

TableList.prototype.isSubmitCandidate = function(ix) {
    return this.items[ix].selected; 
}

TableList.prototype.toString = function() {
  var string = "";
  for (var ix = 0; ix < this.items.length; ix++) {
    string += "items[" + ix + "]=(";
    for ( var key in this.items[ix] ) {
      string += key + ":" + this.items[ix][key];
    }
    string += "),";
  }
  return string;
}

TableList.prototype.onSubmit = function(formElement) {
  document.getElementById(this.id + "_submitInputFields").innerHTML = this.createSubmitInputFieldsHtml();
}

// Create <input type="hidden"> fields suitable for parsing with O2::Cgi::getStructure() of the list.
// Fields are determined by submitType="" and submitItemFields="" attributes
TableList.prototype.createSubmitInputFieldsHtml = function() {
  var submitType = document.getElementById(this.id).getAttribute("submitType");
  var submitItemFields = document.getElementById(this.id).getAttribute("submitItemFields");
  if (!submitItemFields) {
    submitItemFields = "value";
  }
  var fieldNames = submitItemFields.split(/\s*,\s*/);
  var html = "";
  var doFilter = submitType != "all" ? true : false;
  var counter = 0;
  for (var ix = 0; ix < this.items.length; ix++) {
    var filterResult = doFilter ? this.isSubmitCandidate(ix) : true;
    if (filterResult) {
      if (fieldNames.length == 1) { // submit just an array of strings
        html += '<input type="hidden" name="' + this.id + "[" + counter + ']" value="' + this.items[ix][ fieldNames[0] ] + '">\n';
      } 
      else {  // submit an array of hashes
        for (var fieldI = 0; fieldI < fieldNames.length; fieldI++) {
          html += '<input type="hidden" name="' + this.id + "[" + counter + "]." + fieldNames[fieldI] + '" value="' + this.items[ix][ fieldNames[fieldI] ] + '">\n';
        }
      }
      ++counter;
    }
  }

  // ensure O2::Cgi::getStructure() parses list as an array
  var parts = this.id.split(".");
  html += '<input type="hidden" name="' + parts[0] + "._dataType." + parts[1] + '" value="array">';
  return html;
}
