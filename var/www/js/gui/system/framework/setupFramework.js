function getTrashcanId() {
  return trashcanId;
}

function objectComponent (className, name, id) {
  return '<img src="' + getIconUrl(className) + '"> <a href="javascript:top.openObject(\'' + className + "', " + id + ')">' + name + "</a>";
}

function getActionIconUrl(action,size) {
    var baseUrl = "/images/icons/o2default";
    if (size == null) { //for backward comp
        size = 16;
    }
    var dirs = action.split("-");
    var path = dirs.join("/");
    var iconFile = dirs.join("-") + "-" + size + ".png";
    return baseUrl + "/" + path + "/" + iconFile;
}

function getIconUrl(className, size) {
  var baseUrl = "/images/icons/o2default";
  if (size == null) { //for backward comp
    size = 16;
  }
  if (!className) {
    className = "";
  }
  var dirs = className.split("::");
  var path = dirs.join("/");
  var iconFile = dirs.join("-") + "-" + size + ".png";
  return baseUrl + "/" + path + "/" + iconFile;
}

var openedFrames   = new Array();
var openedUrls     = new Array();
var openedWindows  = new Array(); // Our window refs
var windowSequence = new Array(); // Used to remember last openend window/frame. This is purely a usability thing
var frameOrder     = new Array(); // So we can use the keyboard to switch to the frame to the left or right
var maxNFrames     = 9;

function switchToFrameId (frameId) {
  rememberThisWindow(frameId);
  //is this a popup window?
  //note: frameId is actually a url
  if (openedWindows[frameId] != null) {
    openedWindows[frameId].focus();
    bottomFrame.focusFrameSwitchButton(frameId);
    return;
  }
  
  bottomFrame.focusFrameSwitchButton(frameId);
  
  var iframes = middleFrame.right.document.getElementsByTagName("iframe");
  for (var i = 0; i <= maxNFrames; i++) {
    if (frameId !== i) {
      iframes[i].style.display = "none";
    }
  }
  iframes[frameId].style.display = "block";
}

function closeCurrentFrame(window) {
  var frame = getFrameInfoByUrl(window.location.pathname + window.location.search);
  closeFrameId(frame.frameId);
}

function closeFrame(frameName) {
  // alert(frameName);
  var frameId = parseInt( frameName.substring(1, frameName.length) );

  if (frameId == null || frameId > maxNFrames || frameId == 0) {
    alert("Error in closeFrame:\nTried to close this frameId: " + frameId);
    return;
  }

  try {
    closeFrameId(frameId);
  }
  catch(e) {
    alert("Error in closeFrame:\nTried to close this frameId : '" + frameId + "'\nCause: " + o2.getExceptionMessage(e) + "\nframeName = " + frameName);
  }
}

function closeFrameId (frameId) {
  var tmp = new Array();
  _deleteFromFrameOrder(frameId);
  openedFrames[frameId] = {inUse:false};
  try {
    middleFrame.right["c"+frameId].location.href = "about:blank";
  }
  catch (e) {
    // alert("frameId: " + frameId);
  }
  for (var key in openedUrls) {
    if (openedUrls[key].frameId != frameId) {
      tmp[key] = openedUrls[key];
    }
  }
  openedUrls = tmp;
  forgetThisWindow(frameId); //take this window out of the windowsequence

  var lastWindow = getLastWindow(); //get the last frame or window that the user had open
  var safe =0;
  while ( isNaN(parseInt(lastWindow) ) && safe++ < maxNFrames ) { //while we are talking about url's (popupwindows
//    alert(lastWindow);
    switchToFrameId(lastWindow); // XXX Maybe keep a stack so that we can shift to the last frame watched??
    lastWindow = getLastWindow(lastWindow);
  }

  switchToFrameId(lastWindow); // XXX Maybe keep a stack so that we can shift to the last frame watched??
  bottomFrame.removeFrameSwitchButton(frameId);
}

function _deleteFromFrameOrder(frameId) {
  var newOrder = new Array();
  for (var i = 0; i < frameOrder.length; i++) {
    if (frameOrder[i] != frameId) {
      newOrder.push( frameOrder[i] );
    }
  }
  frameOrder = newOrder;
}

function openInFrame(url, icon, text) {
  // Quick fix for 24px icons
   var regExp = new RegExp("24","i");
   icon = icon.replace(regExp,"16");

  // this url has an open window
  if (openedUrls[url]) {
    switchToFrameId( openedUrls[url].frameId );
  }
  else if (fixOpenedUrlsLengthBug() >= maxNFrames) { // to many frames open
    displayError(o2.lang.getString("o2.desktop.errorTooManyOpenFrames"));
  }
  else { //lets find next free frame
    var vacantFrameId = 1;
    for (var i=1; i <= maxNFrames; i++) {
      if (!openedFrames[i] || (openedFrames[i] &&  !openedFrames[i].inUse)) {
        vacantFrameId = i;
        break;
      }
    }
    openedFrames[vacantFrameId] = {inUse:true};
    openedUrls[url] = {frameId:vacantFrameId};
    frameOrder.push(vacantFrameId);
    try {
      middleFrame.right["c"+vacantFrameId].location.href = url;
    }
    catch (e) {
    }
    bottomFrame.addFrameSwitchButton({icon:icon, text:text, frameId:vacantFrameId});
    switchToFrameId(vacantFrameId);
  }
}

function getFrameInfoByUrl(url) {
  if (openedUrls[url]) {
    return {
      frameId : openedUrls[url].frameId,
      frame   : middleFrame.right[ "c" + openedUrls[url].frameId ]
    };
  }
  return null;
}

function fixOpenedUrlsLengthBug() {
  if (openedUrls.length != 0) {
    return openedUrls.length ;
  }
  //hm, sure its zero? Its bugging in mozilla
  var length = 0;
  for (var elm in openedUrls) {
    length++;
  }
  return length;
}

function openInWindow(url,icon,text) {
  // if url not contains window props, use default
  if (typeof(url) == "string") {
    url = {url:url,width:"640",height:"480"};
  }
  if (openedWindows[url.url] ) {
    switchToFrameId(url.url);
  }
  else {
    bottomFrame.addFrameSwitchButton({icon:icon, text:text, frameId:url.url});
    openedWindows[url.url] = o2.openWindow.openWindow(url);
    //hopefully user got a good connection so 1000 millis is enough
    setTimeout("_registerOnUnLoadEvent('"+url.url+"')",1000);
  }  
}

function _registerOnUnLoadEvent(windowId) {
  if (!openedWindows[windowId]) {
    return alert("openedWindows["+windowId+"] is empty");
  }
  openedWindows[windowId].document.body.onbeforeunload = new Function("windowClosing('"+windowId+"')");
  openedWindows[windowId].onbeforeunload               = new Function("windowClosing('"+windowId+"')");  
  switchToFrameId(windowId);
}

function windowClosing(windowId) {
  if (openedWindows[windowId] != null && openedWindows[windowId].close) {
    bottomFrame.removeFrameSwitchButton(windowId);
    openedWindows[windowId] = null;
    var tmp = new Array();
    for (elm in openedWindows) {
      if (openedWindows[elm] != null) {
        tmp[elm] =openedWindows[elm];
      }
    }  
    openedWindows = tmp;
  }
  forgetThisWindow(windowId);
}

function rememberThisWindow(url) {
  if (windowSequence[windowSequence.length-1] == url) {  //same as last window
    return;
  }
  else {
   windowSequence.push(url);
  }

  if (windowSequence.length > 20) { //we don't wanna remember more than 20 windows switches
    windowSequence.shift(); //remove the first entry
  }
}

function forgetThisWindow(url) {
  var tmp = new Array();
  for (elm in windowSequence) {
    if (windowSequence[elm] != url) {
      tmp[elm] = windowSequence[elm];
    }
  }
  windowSequence = tmp;
}

function getCurrentFrame() {
  var frameId = "c" + top.windowSequence[ top.windowSequence.length-1 ];
  return top.frames.middleFrame.right[frameId];
}

function getLastWindow(butNotThisWindowId) {
  if (windowSequence.length>0){
    var popped = windowSequence.pop();
    while (popped == butNotThisWindowId) {
      popped = windowSequence.pop();
    }
    return popped;
  }
  return 0;
}

function getCustomerRoot() {
  return o2CustomerRoot;
}

function getEditUrl(className, objectId) {
  if (!classes[className]) return;
  var url = classes[className].editUrl;
  if (!url) return;
  if (url.indexOf("%%") >= 0) {
    url = subst(url, ["objectId", objectId, "className", className]);
  }
  else {
    url += objectId;
  }
  return url;
}

// Open an object for editing
function openObject(className, objectId, title, isTrashed) {
  if (isTrashed) {
    return top.displayError( top.o2.lang.getString("o2.desktop.errorCantOpenTrashedObject") );
  }
  if (title == null) {
    title = o2.lang.getString("o2.desktop.defaultEditTitle");
  }
  title = title.replace(/&apos;/g, "'");

  var editUrl = getEditUrl(className, objectId);
  if (editUrl) {
    if (editUrl.indexOf("javascript:") == 0) {
      var evalStr = editUrl.substring("javascript:".length);
      eval(evalStr);
    }
    else {
      openInFrame(editUrl, getIconUrl(className), title);
    }
  }
  else {
    displayError( o2.lang.getString("o2.desktop.errorNoEditUrl", { "className" : className }) );
  }
}

function getNewUrl(className, parentId, queryString) {
  if (!classes[className]) return;
  var url = classes[className].newUrl;
  if (!url) return;
  if (url.indexOf("%%") >= 0) {
    url = subst(url, ["parentId", parentId, "className", className]);
  }
  else if (url.match(/=$/)) {
    url += parentId;
  }
  if (queryString) {
    url += url.match(/[?]/) ? "&" : "?";
    url += queryString;
  }
  return url;
}

// create new object
function newObject(className, parentId, queryString) {
  var newUrl = getNewUrl(className, parentId, queryString);

  var url;
  if (className == "O2::Obj::File"||className == "O2CMS::Obj::MultiMedia::Video") {
    url = o2.urlMod.urlMod({ setClass : "File-Upload", setMethod : "popup", setParams : "folderId=" + parentId });
    openInWindow({url:url, width:450, height:350}, getIconUrl(className), o2.lang.getString("o2.desktop.newImage"));
  }
  else if (className == "O2CMS::Obj::Article") {
    url = o2.urlMod.urlMod({ setClass : "Article-Editor", setMethod : "", setParams : "catId=" + parentId + "&time=" + new Date().getTime() });
    openInFrame(url, getIconUrl(className), o2.lang.getString("o2.desktop.new") + " " + className);
  }
  else if (className == "O2CMS::Obj::Page"  ||  className == "O2CMS::Obj::Frontpage") {
    url = o2.urlMod.urlMod({ setClass : "Page-Editor", setMethod : "newPage", setParams : "parentId=" + parentId + "&className=" + className });
    openInFrame(url, getIconUrl(className), o2.lang.getString("o2.desktop.new") + " " + className);
  }
  else if (className == "O2CMS::Obj::Menu") {
    url = o2.urlMod.urlMod({ setClass : "Menu-MenuEditor", setMethod : "create", setParams : "parentId=" + parentId });
    openInFrame(url, getIconUrl(className), o2.lang.getString("o2.desktop.new") + " " + className);
  }
  else if (newUrl) {
    openInFrame(newUrl, getIconUrl(className), o2.lang.getString("o2.desktop.new") + " " + className);
  }
  else {
    url = o2.urlMod.urlMod({ setClass : "Universal", setMethod : "newObject", setParams : "parentId=" + parentId + "&class=" + className });
    openInFrame(url, getIconUrl(className), o2.lang.getString("o2.desktop.new") + " " + className);
  }
}

// open query object in search window
function editQuery(objectId) {
  var leftFrame = top.frames.middleFrame.frames.left;
  leftFrame.window.doSwitch("searchDiv", true);
  leftFrame.o2.ajax.call({
    setClass     : "System-Search",
    setMethod    : "edit",
    setParams    : { id : objectId },
    target       : "searchDiv",
    where        : "replace"
  });
}

// updates a folder in the tree component
function reloadTreeFolder(folderId) {
  window.frames.middleFrame.frames.left.getComponentById("tree").reloadFolder(folderId);
}

function reloadTreeFolders(toFolderId, fromFolderId) {
 window.frames.middleFrame.frames.left.getComponentById("tree").reloadFolders([toFolderId, fromFolderId]);
}

function reloadTree() {
  window.frames.middleFrame.frames.left.reloadTree();
}

// Returns a string version of the frame path of the given window
function resolveFramePath(window) {
  var framePath="";
  var wObj = window;
  var safeIdx=0;
  while ( wObj.parent != null  && wObj.frames.name!="" && safeIdx++ < 100 ) {
    framePath=".frames."+wObj.frames.name+framePath;
    wObj = wObj.parent;
  }
  return "top"+framePath;
}

function moveObject(objectId, containerId,callBackFunction) {
  window.frames.middleFrame.frames.left.getComponentById("tree").moveObject(objectId,containerId,callBackFunction);
}

function moveObjects(objectIds, containerId, callBackFunction) {
  window.frames.middleFrame.frames.left.getComponentById("tree").multiMove(objectIds, containerId, callBackFunction);
}

function showNewCategoryDialog() {}

var _callBackFrames = new Array();
function saveAsDialogWindow(ownerFrame,folderId,filename) {
  // framePath is also used as a unique id for this callBack requst
  var framePath = resolveFramePath(ownerFrame);
  _callBackFrames[framePath] = ownerFrame;
  top.o2.openWindow.openWindow({
    url        : "/o2cms/System-FileDialog/saveAsDialog?callBackId=" + framePath + "&folderId=" + folderId + "&filename=" + escape(filename),
    scrollbars : "no",
    status     : "no",
    height     : "300"                
  });
}

function _globalSaveAsDialogCallback(callBackId,folderId,filename) {
  if (_callBackFrames[callBackId] == null) {
    alert("An error occured, the saveAsDialog could not be callback'ed!");
    return false;
  }
  _callBackFrames[callBackId].setApplicationFrameHeaderCurrentPath( folderId );
  _callBackFrames[callBackId].setApplicationFrameHeaderExtraPath(   filename );
  _callBackFrames[callBackId].saveAsDialogCallback(folderId,filename);
  _callBackFrames[callBackId] = null;
  return true;
}

function confirmBox(question,callback, properties) {
  top.frames.middleFrame.showConfirmBox(question,callback,properties);
}

function messageBox(message, properties,callback) {
  top.frames.middleFrame.showMessageBox(message,properties,callback);
}

function errorBox(message,properties,callback) {
  top.frames.middleFrame.showErrorBox(message,properties,callback);
}

// For backward compatibility
function displayMessage(text) {
  var messageDiv = top.frames.topFrame.document.getElementById("message");
  messageDiv.innerHTML = text;
  messageDiv.className = "info";
  setTimeout("removeDisplayMessage();", 3000);
}

function removeDisplayMessage() {
  var messageDiv = top.frames.topFrame.document.getElementById("message");
  messageDiv.innerHTML = "";
  messageDiv.className = "";
}

function displayError(text) {
  var messageDiv = top.frames.topFrame.document.getElementById("message");
  var textParts = o2.split(/<br>/, text, 2);
  if (textParts[0].length > 100) {
    textParts[0] = textParts[0].substring(0, 80) + "...";
    textParts[1] = textParts[0].substring(80) + textParts[1];
  }
  messageDiv.innerHTML = textParts[0];
  if (textParts[1]) {
    text = text.replace( /&/g,      "&amp;"  );
    text = text.replace( /\'/g,     "\\'"    );
    text = text.replace( /\"/g,     "&quot;" );
    text = text.replace( /<br>\n/g, "<br>"   );
    text = text.replace( /\n/g,     "<br>"   );
    messageDiv.innerHTML += " [<a href=\"javascript: top.frames.middleFrame.showErrorBox('" + text + "')\">" + o2.lang.getString("o2.desktop.linkMoreInfo") + "</a>]";
  }
  messageDiv.innerHTML += " [<a href=\"javascript: top.removeDisplayMessage()\">" + o2.lang.getString("o2.desktop.linkHide") + "</a>]";
  messageDiv.className = "error";
}

function showPropertiesDialog(objectId) {
  top.frames.middleFrame.showPropertiesDialog(objectId);
}

function showPropertyEditor(objectId) {
  openInFrame("/o2cms/System-PropertyEditor/editProperties?objectId="+objectId,getIconUrl("O2::Obj::PropertyDefinition"), "-");
}

function showRevisionDialog(objectId,callBackWindow) {
  return top.frames.middleFrame.showRevisionDialog(objectId,callBackWindow);
}

function hideRevisionDialog() {
  top.frames.middleFrame.o2.popupDialog.hide();
}

function restoreDone() {
  return top.frames.middleFrame.restoreDone();
}

function showKeywordDialog(objectId,callBackWindow) {
  return top.frames.middleFrame.showKeywordDialog(objectId,callBackWindow);
}

function hideKeywordDialog() {
  return top.frames.middleFrame.keywordDialog.hideDialog();
}
