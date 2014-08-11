MenuEditorTree.prototype = new Tree();
MenuEditorTree.superclass = Tree.prototype;
MenuEditorTree.prototype.constructor = MenuEditorTree;

function MenuEditorTree(componentId) {
  this.id = componentId;
  this.items = {};
  initDragContainer(document.getElementById(componentId));
}

MenuEditorTree.prototype.setTopLevelId = function(topLevelId) {
  this.topLevelId = topLevelId;
}

MenuEditorTree.prototype.addObjectFolder = function(folderItem) {
  var text = this.getObjectFolderHtml(folderItem);
  var parentId = (folderItem.parentId==this.topLevelId) ? null : folderItem.parentId;
  this.addFolder(parentId, folderItem.id, text);
  this.items[folderItem.id] = folderItem;
  this.changeExpandable(folderItem.id, folderItem.expandable);
}


MenuEditorTree.prototype.getObjectFolderHtml = function(folderItem) {
  var className = folderItem.visible ? 'treeItemVisible' : 'treeItemHidden';
  return '<span dropid="'+folderItem['id']+'" class="'+className+'"><img src="'+folderItem['iconUrl']+'" dragid="'+folderItem['id']+'" style="vertical-align:middle;">'
       + '<span onclick="getComponentById(\''+this.id+'\').nameClick('+folderItem.id+')">&nbsp;'+folderItem.name+'</span>';
}




MenuEditorTree.prototype.getDragDataById = function(dragId) {
  _debug('getDragDataById() called');
  return this.items[dragId];
}

MenuEditorTree.prototype.getItems = function(dragId) {
  return this.items;
}

MenuEditorTree.prototype.changeVisible = function(id, value) {
  this.items[id].visible = value ? 1 : 0;
  document.getElementById(this.id+'_t'+id).innerHTML = this.getObjectFolderHtml(this.items[id]);
}

MenuEditorTree.prototype.changeExpandable = function(id, value) {
  this.items[id].expandable = value==true ? 1 : 0;
  document.getElementById(this.id+'_x'+id).style.visibility = value ? 'visible' : 'hidden';
}

MenuEditorTree.prototype.changeDescription = function(id, value) {
  this.items[id].description = value;
}

MenuEditorTree.prototype.nameClick = function(id) {
//  if( currentItemInfoId>0 ) {
//    document.getElementById('itemInfo_'+currentItemInfoId).style.display = 'none';
//  }
//  currentItemInfoId = id;

  var item = this.items[id];
  if( !item ) return;
  var html = '<table padding=2 width=100%><tr><td colspan=2><font style="font-weight:bold;color:#777;">' + o2.lang.getString('o2.menuEditor.headerOptions') + ' : "'+item.name+'" (id:'+item.id+')</font></td></tr>';
  html += '<tr><td width=3%><input type="checkbox" onchange="getComponentById(\''+this.id+'\').changeVisible('+id+',this.checked)" '+(item.visible==1?'checked':'')+'"></td><td width=97%> ' + o2.lang.getString('o2.menuEditor.visible') + '<td<font style="color:#777;"></tr>';
  html += '<tr><td width=3%><input type="checkbox" onchange="getComponentById(\''+this.id+'\').changeExpandable('+id+',this.checked)" '+(item.expandable==1?'checked':'')+'"></td><td width=97%<font style="color:#777;"> ' + o2.lang.getString('o2.menuEditor.expandable') + '<td></tr>';
  html += '<tr><td colspan=2<font style="color:#777;">' + o2.lang.getString('o2.menuEditor.description') + '</td></tr><tr><td colspan=2><textarea onchange="getComponentById(\''+this.id+'\').changeDescription('+id+',this.value)" class="descriptionTextArea">'+item.description+'</textarea><td></tr></table>';
  var elm = document.getElementById('itemInfo_'+this.id);
  elm.innerHTML = html;
  elm.style.display = 'inline';
}

MenuEditorTree.prototype.ondragstart = function(source) {
   _debug('dragstart: '+source.element.id+'/'+source.data.name);
}

MenuEditorTree.prototype.ondragend = function(source, target) {
//  if( target && target.component && target.component.id=='trashcan' ) {
//    alert('trashed');
//  }
//  if( source && target ) _debug('dragend: '+source.element.id+'/'+source.data.name+' to '+target.element.id+'/'+target.data.name);
}
MenuEditorTree.prototype.ondrop = function(source, target) {
  if( source.element==target.element && target.data ) { 
    // rearrange same tree
    this.move(source.data.id, target.data.id);
  } else {
    // add item from other source
    var data = o2.cloneObject(source.data);
    data.description = '';
    data.visible = 1;
    if( this.items[data.id] ) return alert('Item already in menu');

//    this.addItemToOtherLocales(data);

    // count items in same category as the new item, use it as position (place at bottom)
    data.position = 0;
    for( var itemId in this.items ) {
      if( this.items[itemId].parentId==data.parentId ) data.position++;
    }

    this.addObjectFolder(data);
  }
//alert('drop: '+source.element.id+'/'+source.data.text+' to '+target.element.id+'/'+target.data.text);
}

MenuEditorTree.prototype.move = function(sourceId, targetId) {
  var source = this.getDragDataById(sourceId);
  var target = this.getDragDataById(targetId);
  if( source.parentId!=target.parentId ) {
    return alert('Can only move objects within the same folder');
  }

  var sourceElm = document.getElementById(this.id+'_f'+sourceId);
  var targetElm = document.getElementById(this.id+'_f'+targetId);

  // move folder content
  var tmpHtml = sourceElm.innerHTML;
  sourceElm.innerHTML = targetElm.innerHTML;
  targetElm.innerHTML = tmpHtml;

  // swap id's
  sourceElm.setAttribute('id', this.id+'_f'+targetId);
  targetElm.setAttribute('id', this.id+'_f'+sourceId);
  
  // swap parentIds
  var tmpId = source.parentId;
  source.parentId = target.parentId;
  target.parentId = tmpId;
  
  // update position of items
  var tmpPos = source.position;
  source.position = target.position;
  target.position = tmpPos;
}

MenuEditorTree.prototype.removeItemById = function(id) {
  var elm = document.getElementById(this.id+'_f'+ id);
  elm.style.display = 'none';
//  delete this.items[id];
  this.items[id].deleted = 1; // insert "deleted" flag in menu item structure
}

function _debug(msg) {
  var elm = document.getElementById('debug');
  if( elm ) elm.innerHTML += msg+'<br>';
}
