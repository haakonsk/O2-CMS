/**
  The keyword manage allows you to work with keywords for/on objects via only JS.
  It uses ajax to perform action on the serverside.
 */

o2.require("/js/ajax.js");

function KeywordManager() {
  return this;    
}

KeywordManager.prototype.getKeywordsForObjectId = function(objectId, callBack) {
  o2.ajax.call({
    setMethod : "getKeywordsByObjectId",
    setParams : "objectId=" + objectId + "&myCallBack=" + callBack,
    handler   : this.getKeywordsForObjectIdHandler
  });
}

KeywordManager.prototype.getKeywordsForObjectIdHandler = function(data) {
  if (data.result === "ok") {
    if (data.myCallBack) {
      try {
        eval(data.myCallBack + "(data.keywords)");
      }
      catch(e) {
        alert( "ERROR\nCould not perform callback : " + data.myCallBack + "\nReason: " + e.toString() );
      }
    }
  }
}

KeywordManager.prototype.searchKeywords = function(searchString, callBack) {
  o2.ajax.call({
    setMethod : "searchKeywords",
    setParams : "keyword=" + (searchString != "" ? searchString : "*") + "&myCallBack=" + callBack,
    handler   : this.searchKeywordsHandler
  });
}

KeywordManager.prototype.searchKeywordsHandler = function(data) {
  if (data.result === "ok") {
    if (data.myCallBack) {
      try {
        eval(data.myCallBack + "(data.keywords)");
      }
      catch(e) {
        alert( "ERROR\nCould not perform callback : " + data.myCallBack + "\nReason: " + e.toString() );
      }
    }
  }
}

KeywordManager.prototype.addKeywordIdToObjectById = function(keywordId, objectId, callBack) {
  o2.ajax.call({
    setMethod : "addKeywordIdToObjectId",
    setParams : "keywordId=" + keywordId + "&objectId=" + objectId + "&myCallBack=" + callBack,
    handler   : this.addKeywordIdToObjectByIdHandler,
    method    : "post"
  });
}

KeywordManager.prototype.addKeywordIdToObjectByIdHandler = function(data) {
  if (data.result === "ok") {
    if (data.myCallBack) {
      try {
        eval(data.myCallBack + "()");
      }
      catch(e) {
        alert( "ERROR\nCould not perform callback : " + data.myCallBack + "\nReason: " + e.toString() );
      }
    }
  }
}

KeywordManager.prototype.delKeywordIdFromObjectById = function(keywordId, objectId, callBack) {
  o2.ajax.call({
    setMethod : "delKeywordIdFromObjectId",
    setParams : "keywordId=" + keywordId + "&objectId=" + objectId + "&myCallBack=" + callBack,
    handler   : this.delKeywordIdFromObjectByIdHandler,
    method    : "post"
  });
}

KeywordManager.prototype.delKeywordIdFromObjectByIdHandler = function(data) {
  if (data.result === "ok") {
    if (data.myCallBack) {
      try {
        eval(data.myCallBack + "()");
      }
      catch(e) {
        alert( "ERROR\nCould not perform callback : " + data.myCallBack + "\nReason: " + e.toString() );
      }
    }
  }
}

KeywordManager.prototype.getChildrenByObjectId = function(objectId, callBack) {
  o2.ajax.call({
    setMethod : "getChildrenByObjectId",
    setParams : "objectId=" + objectId + "&myCallBack=" + callBack,
    handler   : this.getChildrenByObjectIdHandler
  });
}

KeywordManager.prototype.getChildrenByObjectIdHandler = function(data) {
  if (data.result === "ok") {
    if (data.myCallBack) {
      try {
        eval(data.myCallBack + "(data.keywords)");
      }
      catch(e) {
        alert( "ERROR\nCould not perform callback : " + data.myCallBack + "\nReason: " + e.toString() );
      }
    }
  }
}

KeywordManager.prototype.addKeywordInFolder = function(keyword, parentId, callBack) {
  o2.ajax.call({
    setMethod : "addKeywordInFolder",
    setParams : "&keyword=" + keyword + "&parentId=" + parentId + "&myCallBack=" + callBack,
    handler   : this.addKeywordInFolderHandler,
    method    : "post"
  });
}

KeywordManager.prototype.addKeywordInFolderHandler = function(data) {
  if (data.result === "ok") {
    if (data.myCallBack) {
      try {
        eval(data.myCallBack + "(data.keyword)");
      }
      catch(e) {
        alert( "ERROR\nCould not perform callback : " + data.myCallBack + "\nReason: " + e.toString() );
      }
    }
  }
}

KeywordManager.prototype.test = function() {
  if (window.console) {
    console.log("test called");
  }
}
