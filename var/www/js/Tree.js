/*
This component represents a basic tree (without drag and drop etc).

HTML layout of a folder:
  <div id="_f{folderId}">
    {indentImages}<img id="_x{folderId}">{folderName}<br>
    <span id="_c{folderId}">
      <div>{indentImages}{folder1}</div>
      <div>{indentImages}{folder2}</div>
      <div>{indentImages}{folder..}</div>
    </span>
  </div>
  xfr
id="_x..." - expand collapse button
id="_f..." - whole folder
id="_c..." - content/files in folder
*/


function Tree(componentId) {
  this.id = componentId;
  this.items = {};
  this.openFolders = {};
}

Tree.prototype.redraw = function() {}

// Set whole tree based on a the "tree-structure"
Tree.prototype.setTree = function(folderItems) {
  var treeElm = document.getElementById(this.id);
  var html = this._folderHtml(folderItems,'');
  treeElm.innerHTML = html;
}

// Generate content html for a folder based on a "tree-structure"
Tree.prototype._folderHtml = function(folderItems, indent) {
  var html = '';
  for( var i=0; i<folderItems.length; i++ ) {
    var item = folderItems[i];
    if( item ) {
      if( item['items'] ) { // folders have sub-items
        html += '<div id="'+this.id+'_f'+item['id']+'" class="treeFolder">';
        html += indent+'<img src="/images/system/tree/expandFolder.gif" id="'+this.id+'_x'+item['id']+'" onclick="getComponentById(\''+this.id+'\').toggleExpand(\''+item['id']+'\')">';
        html += item['text']+'<br>';
        html += '<span id="'+this.id+'_c'+item['id']+'" style="display:none">';
        html += this._folderHtml(item['items'], indent+'<img src="/images/system/tree/vertline.gif">');
        html += '</span>';
        html += '</div>';
      } else { // file item
        html += indent+'<img src="/images/system/tree/connect_trb.gif">'+item['text']+'<br>';
      }
    }
  }
  return html;
}

// Add folder to a folder dynamically
Tree.prototype.addFolder = function(parentFolderId, folderId, text, dontInsertNode) {
  var parentElmId = !parentFolderId ? this.id : this.id+'_c'+parentFolderId; // top or sub-folder?
  var parentElm = document.getElementById(parentElmId);
  if (!parentElm) {
    alert("Can't find element " + parentElmId);
  }

  var html = "";
  var elm;
  if (dontInsertNode) {
    html += "<div id='" + this.id + "_f" + folderId + "' class='" + document.getElementById(this.id).className + "Folder'>";
  }
  else {
    elm = document.createElement('div');
    elm.setAttribute('id', this.id+'_f'+folderId);
    elm.className = document.getElementById(this.id).className + 'Folder';
  }

  html += "<nobr>";
  var depth = this._nodeDepth(parentElm);
  for (var i = 0; i < depth; i++) {
    html += '<img src="/images/system/tree/vertline.gif">';
  }
  html += '<img src="/images/system/tree/expandFolder.gif" id="'+this.id+'_x'+folderId+'" onclick="getComponentById(\''+this.id+'\').toggleExpand(\''+folderId+'\')">';
  html += '<span id="'+this.id+'_t'+folderId+'">'+text+'</span></nobr><br>';
  html += '<span id="'+this.id+'_c'+folderId+'" style="display:none"></span>';
  if (dontInsertNode) {
    html += "</div>";
    return html;
  }
  elm.innerHTML = html;
  parentElm.appendChild(elm);
}

// Add file to a folder dynamically
Tree.prototype.addFile = function(folderId, text, dontInsertNode) {
  var contentElm = document.getElementById(folderId==null ? this.id : this.id+'_c'+folderId); // top or sub-folder?

  var html = "";
  var elm;
  if (dontInsertNode) {
    html = "<div class='" + document.getElementById(this.id).className + "File'>";
  }
  else {
    var elm = document.createElement('div');
    elm.className = document.getElementById(this.id).className+'File';
  }

  html += "<nobr>";
  var depth = this._nodeDepth(contentElm);
  for (var i = 0; i < depth; i++) {
    html += '<img src="/images/system/tree/vertline.gif">';
  }
  html += '<img src="/images/system/tree/connect_trb.gif">';
  html += text+'</nobr><br>';
  if (dontInsertNode) {
    html += "</div>";
    return html;
  }
  elm.innerHTML = html;
  contentElm.appendChild(elm);
}

// Expand a folder if it's collapsed, or vice versa.
Tree.prototype.toggleExpand = function(folderId) {
  this.isExpanded(folderId) ? this.collapse(folderId) : this.expand(folderId);
}

// Returns true if folder is expanded
Tree.prototype.isExpanded = function(folderId) {
  return this.openFolders[folderId];
}

// Collapse (close) a folder
Tree.prototype.collapse = function(folderId) {
  document.getElementById(this.id+'_c'+folderId).style.display = 'none';
  document.getElementById(this.id+'_x'+folderId).src = '/images/system/tree/expandFolder.gif';
  delete this.openFolders[folderId];
}

// Expand (open) a folder
Tree.prototype.expand = function(folderId) {
  document.getElementById(this.id+'_c'+folderId).style.display = 'block';
  document.getElementById(this.id+'_x'+folderId).src = '/images/system/tree/collapseFolder.gif';
  this.openFolders[folderId] = 1;
}

// Returns thread indenting html for a file node(?)
Tree.prototype._fileIndentHtml = function(elm) {
  var html = '';
  var depth = this._nodeDepth(elm);
  for( var i=0; i<depth; i++ ) {
     html += '<img src="/images/system/tree/vertline.gif">';
  }
  html += '<img src="/images/system/tree/connect_trb.gif">';
  return html;
}

// Count number of folder tags outside an element
Tree.prototype._nodeDepth = function(elm) {
  var depth = 0;
  if( !elm ) return 0;
  while(elm.getAttribute('id')!=this.id) {
    if( elm.getAttribute('id').indexOf(this.id+'_f')==0 ) depth++;
    elm = elm.parentNode;
  }
  return depth;
}

// Replace the content of a folder
Tree.prototype.setFolderContent = function(folderId, html) {
  if( !folderId>0 ) return;
  var elm = document.getElementById(this.id+'_c'+folderId);
  elm.innerHTML = this._fileIndentHtml(elm)+html;
}



Tree.prototype.listExpandedFolderIds = function() {
  var ids = [];
  for( var id in this.openFolders ) {
    ids[ids.length] = id;
  }
  return ids;
}
