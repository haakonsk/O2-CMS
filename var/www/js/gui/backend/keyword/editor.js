o2.require("/js/gui/backend/keyword/KeywordManager.js", init);

var keywordMgr;
var searchKeywordList;
var objectKeywordList;
var workingObjectId;
var tmpItem;
var tmpIx;

function init() {
  keywordMgr = new KeywordManager();
}

function initKeyword() {
  workingObjectId = document.forms.searchForm.objectId.value;
  document.forms.searchForm.keyword.focus();
  _initObjectKeywordList();
  _initSearchKeywordList();
}

function lookupKeyword(f) {
  var searchStr = f.keyword.value;
  document.getElementById( "searchKeywordListNoHits" ).style.display = "none";
  document.getElementById( "searchKeywordListEmpty"  ).style.display = "none";
  document.getElementById( "searchKeywordList"       ).style.display = "none";
  document.getElementById( "keywordSearchActive"     ).style.display = "";
  keywordMgr.searchKeywords(searchStr, "loadKeywordLookupResult");
  return false;
}

function loadKeywordLookupResult(result) {
  if (!searchKeywordList) {
    _initSearchKeywordList();
  }
  document.getElementById( "keywordSearchActive" ).style.display = "none";
  document.getElementById( "searchKeywordList"   ).style.display = "";
  var jsData = new Array();
  for (var i in result) {
    jsData.push({
      id    : result[i].id,
      value : result[i].id,
      text  : result[i].value,
      path  : result[i].path,
      name  : result[i].value
    });
  }
  if (jsData.length > 0) {
    searchKeywordList.setItems(jsData);
    searchKeywordList.redraw();
  }
  else {
    document.getElementById( "searchKeywordList"       ).style.display = "none";
    document.getElementById( "searchKeywordListNoHits" ).style.display = "";
    document.forms.searchForm.addKeyword.value=document.forms.searchForm.keyword.value;
  }
}

function addKeywordToObjectFromList(ix) {
  document.getElementById( "objectKeywordList"      ).style.display = "none";
  document.getElementById( "objectWorkingActive"    ).style.display = "";
  document.getElementById( "objectKeywordListEmpty" ).style.display = "none";
  addKeywordToObject(searchKeywordList.getItemAt(ix));
}

function addKeywordToObject(item) {
  tmpItem = item;
  keywordMgr.addKeywordIdToObjectById(item.id, workingObjectId, "addKeywordToObjectHandler");
}

function addKeywordToObjectHandler() {
  if (tmpItem) {
    objectKeywordList.addItem(tmpItem);
  }
  searchKeywordList.redraw();
  tmpItem = null;
  document.getElementById( "objectKeywordListEmpty" ).style.display = "none";
  document.getElementById( "objectWorkingActive"    ).style.display = "none";
  document.getElementById( "objectKeywordList"      ).style.display = "";
}

function removeKeywordFromObject(ix) {
  document.getElementById( "objectKeywordList"   ).style.display = "none";
  document.getElementById( "objectWorkingActive" ).style.display = "";
  tmpIx = ix;
  var item = objectKeywordList.getItemAt(ix);
  keywordMgr.delKeywordIdFromObjectById(item.id, workingObjectId, "removeKeywordFromObjectHandler");
}

function removeKeywordFromObjectHandler() {
  if (tmpIx != null) {
    objectKeywordList.removeItemAt(tmpIx);
  }
  tmpIx = null;
  document.getElementById( "objectWorkingActive" ).style.display = "none";
  document.getElementById( "objectKeywordList"   ).style.display = "";
  if (objectKeywordList.getItems().length == 0) {
    document.getElementById( "objectKeywordListEmpty" ).style.display = "";
    document.getElementById( "objectKeywordList"      ).style.display = "none";
  }
  
  searchKeywordList.redraw();
}

function _keywordIdIsAssignedToObject(keywordId) {
  var t = objectKeywordList.getItems();
  if (t == null || t.length == 0) {
    return false;
  }
  for (var i = 0; i < t.length; i++) {
    if (t[i].id == keywordId) {
      return true;
    }
  }
  return false;
}

function getChildrenInKeywordFolder(select) {
  var folderId = select.options[select.options.selectedIndex].value;
  if (folderId && folderId > 0) {
    document.getElementById( "searchKeywordListNoHits" ).style.display = "none";
    document.getElementById( "searchKeywordListEmpty"  ).style.display = "none";
    document.getElementById( "searchKeywordList"       ).style.display = "none";
    document.getElementById( "keywordSearchActive"     ).style.display = "";
    keywordMgr.getChildrenByObjectId(folderId, "loadKeywordLookupResult");
  }
}

function addThisKeyword(f) {
  var keyword = f.addKeyword.value;
  document.getElementById("missingKeywordError").style.display = keyword == "" ? "" : "none";
  var folderId = f.addKeywordPath.options[f.addKeywordPath.options.selectedIndex].value;
  keywordMgr.addKeywordInFolder(keyword, folderId, "addThisKeywordHandler");
}

function addThisKeywordHandler(keyword) {
  getChildrenInKeywordFolder(document.forms.searchForm.addKeywordPath);
}
//---------------------------------------------------------------
// setup searchKeywordList
function _initSearchKeywordList() {
  searchKeywordList = new TableList("searchKeywordList");
  
  searchKeywordList.getRowCellsHtml = function(item,ix) {
    var html = item.name;
    if ( !_keywordIdIsAssignedToObject(item.id) ) {
      html += '<img class="toolIcon" src="/images/system/add_16.gif" onClick="addKeywordToObjectFromList(' + ix + ');">';
    }
    return '<td title="' + item.text + '"><img src="/images/system/classIcons/O2-Obj-Keyword.gif">&nbsp;' + html + "</td>";
  };
  
  searchKeywordList.getRowHtml = function(item, ix, className) {
    return '<tr id="' + this.id + "_" + ix + '" class="' + className + (item.selected ? "Selected" : "Unselected") + '" onclick="" onmouseover="" onmouseout="">' + this.getRowCellsHtml(item, ix) + "</tr>";
  };
}
//---------------------------------------------------------------
// setup searchKeywordList
function _initObjectKeywordList() {
  objectKeywordList = new TableList("objectKeywordList");
  objectKeywordList.getRowCellsHtml = function(item,ix) {
    var html = item.name;
    html += '<img class="toolIcon" src="/images/system/del_16.gif" onClick="removeKeywordFromObject(' + ix + ')">';
    
    return '<td title="' + item.text + '"><img src="/images/system/classIcons/O2-Obj-Keyword.gif">&nbsp;' + html + "</td>";
  }
  
  objectKeywordList.getRowHtml = function(item, ix, className) {
    return '<tr id="' + this.id + "_" + ix + '" class="'+ className + (item.selected ? "Selected" : "Unselected") +'" onclick="" onmouseover="" onmouseout="">' + this.getRowCellsHtml(item, ix) + "</tr>";
  }
  
  keywordMgr.getKeywordsForObjectId(workingObjectId, "_initObjectKeywordListHandler");
}

function _initObjectKeywordListHandler(keywords) {
  var jsData = new Array();
  for (var i in keywords) {
    jsData.push({
      id    : keywords[i].id,
      value : keywords[i].id,
      text  : keywords[i].value,
      path  : keywords[i].path,
      name  : keywords[i].value
    });
  }
  if (jsData.length > 0) {
    objectKeywordList.setItems(jsData);
    objectKeywordList.redraw();
    document.getElementById("objectKeywordListEmpty").style.display = "none";
  }
  else {
    document.getElementById("objectKeywordListEmpty").style.display = "";
  }
  document.getElementById("objectWorkingActive").style.display = "none";
}

//---------------------------------------------------------------
