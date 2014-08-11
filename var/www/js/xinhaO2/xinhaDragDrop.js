o2.require("/js/windowUtil.js");
o2.require("/js/selection.js");
o2.require("/js/browser_detect.js");
o2.require("/js/htmlToDom.js");

var imagePreview = '/o2cms/Image-Editor/previewCommands?cmds=resize,200,200&reasonableSize=1&id=';

function richText_initDragDrop(editorId) {
  if (!top.xinhaEditors) {
    top.xinhaEditors = new Array();
  }
  _richText_initDragDrop(editorId);
}

var INITIALIZING_EDITOR_QUEUE = new Array();
var INITIALIZING_EDITOR;
function _richText_initDragDrop(editorId) {
  if (INITIALIZING_EDITOR  &&  INITIALIZING_EDITOR !== editorId) {
    return INITIALIZING_EDITOR_QUEUE.push(editorId);
  }
  INITIALIZING_EDITOR = editorId;
  try { // try again later if richtextarea isn't ready
    top.xinhaEditors[editorId] = {
      editor        : null,
      isInitialized : false
    };
    if (!xinha_editors[editorId]) {
      throw new O2Exception("Waiting for " + editorId + " to initialize");
    }
    top.ALLOWED_EDITOR = editorId;
    var editor = xinha_editors[editorId];
    editor.activateEditor();
  }
  catch (e) {
    return setTimeout("_richText_initDragDrop('" + editorId + "')", 500);
  }
  INITIALIZING_EDITOR = null;
  top.xinhaEditors[editorId].isInitialized = true; // Editors can only be (de)activated after they've been initialized.
  top.xinhaEditors[editorId].editor        = xinha_editors[editorId];
  if (INITIALIZING_EDITOR_QUEUE.length) {
    editorId = INITIALIZING_EDITOR_QUEUE.pop();
    top.ALLOWED_EDITOR = editorId;
    _richText_initDragDrop(editorId);
    if (INITIALIZING_EDITOR_QUEUE.length === 0) {
      setTimeout("top.ALLOWED_EDITOR = null;", 1000); // Is this safe? Or may the textareas start "blinking" (continuously changing focus)?
    }
  }
}


// drop event
function richText_onDrop(editorId, params) {
  if (!xinha_editors || !xinha_editors[editorId]) {
    return alert('xinha_editors['+editorId+'] not found!');
  }
  window._currentXinhaEditor = xinha_editors[editorId];

  var droppedObject = top.source.data; // get hold of dropped object info
  if (!droppedObject) {
    return alert("Can't get hold of dropped object");
  }

  richText_addObject(droppedObject, params);
}

function richText_addObject(o2object, params) { // params: target, event
 // Make sure we insert at the right place
  var selectedHtml = getSelectedHtml();
  if (selectedHtml) {
    restoreSelection( window._currentXinhaEditor );
  }
  window.replacementText = selectedHtml || ".";
  updateHtml('<span class="insertHere">', ".", "</span>");

  if (o2object.className == 'O2::Obj::Image') {
    richText_addImage(o2object, params);
  }
  else if (o2object.className == 'O2CMS::Obj::Flash') {
    richText_addFlash(o2object, params);
  }
  else {
    richText_addLink(o2object, params);
  }
}

// handle images dropped on textarea
function richText_addImage(o2object, params) {
  var addImage = new Image();
  addImage.src = imagePreview + o2object.id;

  var event = params.event;
  var args = {
    objectId   : o2object.id,
    objectType : "image",
    x          : event ? event.getX() : 200,
    y          : 200 // event.getY() doesn't return correct y position.. :( Don't know why.
  };
  o2.ajax.call({
    setClass  : "System-Publisher",
    setMethod : "getAvailableMicroObjectTemplates",
    setParams : args,
    handler   : "richText_addImagePartII"
  });
}

function richText_addImagePartII(params) {
  if (params.availableTemplates.length > 0) {
    // Choose micro template
    richText_showMicroTemplateSelector(params);
  }
  else {
    // Make an ajax call to get the html to insert (microObjects):
    o2.ajax.call({
      setClass  : "System-Publisher",
      setMethod : "getImageHtml",
      setParams : { objectId : params.objectId },
      handler   : "richText_addImagePartIII"
    });
  }
}

function richText_showMicroTemplateSelector(args) {
  restoreSelection( window._currentXinhaEditor );
  var selectorId = "microTemplateSelector_" + args.objectId;
  if (document.getElementById(selectorId)) {
    var elm = document.getElementById(selectorId);
    elm.style.top     = args.y;
    elm.style.left    = args.x;
    elm.style.display = "";
    return;
  }
  var html = "<form id='" + selectorId + "' style='position: absolute; top: " + args.y + "px; left: " + args.x + "px; border: 1px solid black; background: #ddd;'>\n";
  html    += "  <p style='margin: 0; padding: 0; font-weight: bold;'>" + o2.lang.getString("o2.richTextArea.lblChooseMicroObjectTemplate") + "</p>";
  html    += "  <select name='microTemplate' multiple='multiple' onChange='setMicroTemplate(this.value, this.form.id);'>\n";
  html    += "    <option value=''>" + o2.lang.getString("o2.richTextArea.optionNoObjectTemplate") + "</option>\n";
  for (var i = 0; i < args.availableTemplates.length; i++) {
    html  += "    <option value='" + args.availableTemplates[i] + "'>" + args.availableTemplates[i] + "</option>\n";
  }
  html    += "  </select>\n";
  html    += "</form>\n";

  o2.htmlToDom.htmlToDom(html, document.body);
}

function setMicroTemplate(template, formId) {
  var objectId = formId.replace(/^microTemplateSelector_/, "");
  var form = document.getElementById(formId);
  var options = form.getElementsByTagName("option");
  for (var i = 0; i < options.length; i++) {
    options[i].selected = false;
  }
  form.style.display = "none";
  o2.getWindowByDocument( window._currentXinhaEditor._doc ).focus(); // Make sure the window with the editor has focus
  o2.ajax.call({
    setClass  : "System-Publisher",
    setMethod : "getImageHtml",
    setParams : { objectId : params.objectId, microObjectTemplate : template },
    handler   : "richText_addImagePartIII"
  });
}

function richText_addImagePartIII(params) {
  richText_replaceText( params.html );
}

function richText_replaceText(insertHtml) {
  var editor = window._currentXinhaEditor;
  var originalHtml = editor.getHTML();
  var newHtml      = originalHtml.replace('<span class="insertHere">' + window.replacementText + "</span>", insertHtml);
  editor.setHTML(newHtml);
}

// handle flashes dropped on textarea
function richText_addFlash(o2object, params) {
  o2.ajax.call({
    setClass  : "System-Publisher",
    setMethod : "getObjectUrl",
    setParams : { objectId : o2object.id },
    handler   : "richText_addFlashCallback"
  });
}

function richText_addFlashCallback(params) {
  var html = "<table width='200' height='100'>";
  html    += "  <tr>";
  html    += "    <td>";
  html    += "      <div style=\"width: 100%; height: 100%; background: gray;\">";
  html    += "        <object classid=\"clsid:D27CDB6E-AE6D-11cf-96B8-444553540000\"";
  html    += "          codebase=\"http://download.macromedia.com/pub/shockwave/cabs/flash/swflash.cab#version=6,0,40,0\"";
  html    += "          width=\"100%\" height=\"100%\" id=\"" + params.name + "\">";
  html    += "          <param name=\"movie\"   value=\"" + params.url + "\">";
  html    += "          <param name=\"quality\" value=\"high\">";
  html    += "          <param name=\"bgcolor\" value=\"#ffffff\">";
  html    += "          <embed src=\"" + params.url + "\" quality=\"high\" bgcolor=\"#ffffff\" width=\"100%\" height=\"100%\"";
  html    += "            name=\"" + params.name + "\" align=\"\" type=\"application/x-shockwave-flash\"";
  html    += "            pluginspage=\"http://www.macromedia.com/go/getflashplayer\">";
  html    += "          </embed>";
  html    += "        </object>";
  html    += "      </div>";
  html    += "    </td>";
  html    += "  </tr>";
  html    += "</table>";
  richText_replaceText(html);
}

// handle objects dropped on textarea
function richText_addLink(o2object, params) {
  o2.ajax.call({
    setClass  : "System-Publisher",
    setMethod : "getObjectUrl",
    setParams : { objectId : o2object.id, target : params.target },
    handler   : "richText_addLinkCallback"
  });
}

function richText_addLinkCallback(params) {
  var target  =  params.target  ?  'target="' + params.target + '"'  :  "";
  var html = '<a href="' + params.url + '" ' + target + ">"  +  (window.replacementText !== "." ? window.replacementText : params.name)  +  "</a>";
  richText_replaceText(html);
}

function updateHtml(html1, html2, html3) {
  html2 = html2 || "";
  html3 = html3 || "";
  var oldCurrentEditor = Xinha._currentlyActiveEditor;
  var editor = Xinha._currentlyActiveEditor = window._currentXinhaEditor;
  if (editor.getSelectedHTML() && html3) {
    editor.surroundHTML(html1, html3);
  }
  else {
    editor.insertHTML(html1 + html2 + html3);
  }
  _makeEditorEditable(editor);
  Xinha._currentlyActiveEditor = oldCurrentEditor;
}

function getSelectedHtml() {
  var oldCurrentEditor = Xinha._currentlyActiveEditor;
  var editor = Xinha._currentlyActiveEditor = window._currentXinhaEditor;
  var html = editor.getSelectedHTML();
  Xinha._currentlyActiveEditor = oldCurrentEditor;
  return html;
}

function restoreSelection(editor) {
  if (!getSelectedHtml() && editor.o2CurrentSelection) {
    editor.restoreSelection( editor.o2CurrentSelection );
  }
}

function _makeEditorEditable(editor) {
  if (browser.isIE) {
    editor._doc.body.contentEditable = true;
  }
  else {
    var selection = editor.saveSelection();
    editor._doc.designMode = "on"; // Turning designMode on removes the current selection...
    editor.restoreSelection(selection);
  }
}
