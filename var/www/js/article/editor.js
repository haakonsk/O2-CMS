function saveDraft() {
  if (formIsChanged()) {
    clearMSOfficeTags();
    document.forms.article.draftId.value = DRAFT_ID;
    document.getElementById("saveDraftBtn").click();
    setFormChanged(false);
  }
  setTimeout("saveDraft();", 5*60000);
}

function previewPart1() {
  document.forms.article.draftId.value = DRAFT_ID;
  document.getElementById("saveDraftForPreviewBtn").click(); // Save draft
}

function draftForPreviewSaved(params) {
  draftSaved(params);
  previewPart2();
}

function previewPart2() {
  document.forms.previewForm.draftId.value = DRAFT_ID;
  document.forms.previewForm.submit();
}

function draftSaved(params) {
  if (params.draftId) {
    DRAFT_ID = params.draftId;
  }
  setStatusBar( o2.lang.getString("o2.article.editor.message.draftSaved") + " (" + (new Date()).toString() + ")" );
}

function clearMSOfficeTags() {
  xinha_editors.editor.execCommand("killWord");
}

function resetDates() {
  var publishDateField   = document.getElementById("article_publishDateText");
  var unPublishDateField = document.getElementById("article_unPublishDateText");

  if ( publishDateField.value || unPublishDateField.value ) {
    var confirmed = confirm( o2.lang.getString("resetPublishDateMessage") );
    if (confirmed) {
      publishDateField.value   = "";
      unPublishDateField.value = "";
    }
  }
}

function resizeArticleEditor() {
  // We need to manually set the height of the editor container when window is resized so editor will expand to 100% height
  var applicationHeight = window.innerHeight ? window.innerHeight : document.documentElement.clientHeight ? document.documentElement.clientHeight : document.body.clientHeight; //The current height of browser window

  //Height of browser - (height of header + height of footer) = height of article editor
  var footerHeight   = parseInt(document.getElementById("applicationFrameFooterStatusBar").offsetHeight + 3); //3 is the extra padding from #bodyFrame
  var frameTopHeight = document.getElementById("editorPane").offsetTop;
  var articleHeight = parseInt(applicationHeight - frameTopHeight - footerHeight); //Actual space for the editor without getting scrollbars
  
  var articleBoxHeight = parseInt(document.getElementById("articleBox").offsetHeight); 
  if (articleHeight <= articleBoxHeight) { //If the box menu to the right is higher than the browser window we need vertical scrolling anyways, so let's make the editor as tall as the box menu 
    articleHeight = articleBoxHeight;
  }
  
  document.getElementById("editorPane").style.height = articleHeight + "px"; // Editor now takes up as much room as possible
}

function setDirectPublishData(data) {
  var approvedElm = document.getElementById("approved");
  if( approvedElm && !approvedElm.checked && data && data.length() > 0 ) { // trying to publish something (data!=''), before article is approved
    alert( o2.lang.getString("o2.article.editor.notPossibleToDirectPublishWhenNotApproved") );
  }
  document.getElementById("directPublishData").value = data;
}

// Toggle simple and advanced keywords
function toggleKeywordForm(hide,show) {
  document.getElementById( show + "KeywordsLbl" ).style.display = "block";
  document.getElementById( show + "Keywords"    ).style.display = "block";
  document.getElementById( hide + "KeywordsLbl" ).style.display = "none";
  document.getElementById( hide + "Keywords"    ).style.display = "none";
}

var currTextArea = "section_frontPageText";
var firstSwitch = true;
document.onselectstart = function() {return false};

function init() {
  if (HAS_NEWER_DRAFT && !IS_UNDO && confirm( o2.lang.getString("o2.article.editor.qstShowDraft") )) {
    document.location.href = DRAFT_URL;
  }
  try {
    document.getElementById(ARTICLE_STATUS).checked = true;
  }
  catch (e) {
    // XXX Add more statuses to the HTML document later
  }
  document.getElementById("editorPane").ondrop = function() {
    alert("ok");
  };
}

function swapTab(tabName) {
  storeText();
  var textAreaRef = eval("document.forms.article." + tabName);
  if (tabName == "section_articleText" && firstSwitch && document.forms.article.articleId.value == "") {
    firstSwitch = false;
  }
  xinha_editors.editor.setHTML(textAreaRef.value);
  currTextArea = tabName;
  return true;
}

function storeText() {
  if (currTextArea == null) {
    alert("error: could not store text");
    return;
  }
  if (!xinha_editors || !xinha_editors.editor) {
    return;
  }

  xinha_editors.editor.whenDocReady( function() { // delay call to editor methods until editor is ready (fix for "this._doc" errors)
    var textAreaRef = eval("document.forms.article." + currTextArea);
    var oldValue = textAreaRef.value;
    textAreaRef.value = xinha_editors.editor.getHTML();
    document.getElementById( _getLocaleHiddenFieldName(currTextArea, o2.multilingualController.currentActiveLocaleCode) ).value = textAreaRef.value;
  });
}

var _closeUponSaving = false;
function saveArticle(closeUponSaving) {
  if (closeUponSaving) {
    _closeUponSaving = true;
  }
  clearMSOfficeTags();
  storeText();
  
  //o2.rules.submitForm(document.forms.article);
  if (o2.rules.checkForm(document.forms.article)) {
    document.getElementById("articleSubmitButton").click();
  }
  
  setStatusBar( o2.lang.getString("o2.article.editor.message.saveInProgress") );
  setFormChanged(false);
}

function setStatusBar(text) {
  document.getElementById("statusLabel").innerHTML = text;
}

function onArticleSaved(params) {
  saveDone( params.articleId );
}

function saveDone(artId) {
  document.forms.article.articleId.value = artId;

  try {
    top.displayMessage( o2.lang.getString("o2.article.editor.message.saveDone") );
  }
  catch (e) {}
  if (!_closeUponSaving) {
    setStatusBar( o2.lang.getString("o2.article.editor.message.saveDone") + " (" + (new Date).toString() + ")" );
  }

  // reload tree folder where article resides
  var categoryId = document.forms.article.category.value;
  setApplicationFrameHeaderCurrentPath(artId);
  top.reloadTreeFolder(categoryId);
  if (_closeUponSaving) {
    top.closeFrame(window.name);
  }
}

function saveAs() {
  top.saveAsDialogWindow(this, article.category.value, "Copy of " + article.articleTitle.value);
}

function saveAsDialogCallback(folderId, fileName) {
  document.forms.article.articleId.value    = "";
  document.forms.article.parentId.value     = folderId;
  document.forms.article.ownerId.value      = "";
  document.forms.article.articleTitle.value = fileName;
  saveArticle();
}

function copyFromHiddenLocaleInputToTextarea() {
  try {
    if (currTextArea == "section_frontPageText") {
      // document.getElementById("section_frontPageText").value = document.getElementById("section_frontPageText." + o2.multilingualController.currentActiveLocaleCode).value;
      document.getElementById("section_frontPageText").value = document.getElementById( _getLocaleHiddenFieldName("section_frontPageText", o2.multilingualController.currentActiveLocaleCode) ).value;
      xinha_editors.editor.setHTML(document.getElementById("section_frontPageText").value);
    }
    else {
      // document.getElementById("section_articleText").value = document.getElementById("section_articleText." + o2.multilingualController.currentActiveLocaleCode).value;
      document.getElementById("section_articleText").value = document.getElementById( _getLocaleHiddenFieldName("section_articleText", o2.multilingualController.currentActiveLocaleCode) ).value;
      xinha_editors.editor.setHTML(document.getElementById("section_articleText").value);
    }
  }
  catch (e) {
    setTimeout("copyFromHiddenLocaleInputToTextarea();", 100);
  }
}

function _getLocaleHiddenFieldName(name, locale) {
  // (Same algorithm as in Form.pm)
  if (name.match(/\./)) { // Contains a dot
    name = name.replace(/^([^.]+)[.](.*)$/, "$1." + locale + ".$2");
  }
  else {
    name = locale + "." + name;
  }
  return name;
}

//callBack function for this revision manager
function restoreDone(objectId) {
  location.href=location.href;
  top.restoreDone();
}

function getParentId() {
  return ARTICLE_PARENT_ID;
}

function generateOptionList(options, selectedId) {
  var html = '';
  for( var i=0; i<options.length; i++ ) {
    html += '<option value="'+options[i].id+'"'+(options[i].id==selectedId?' selected':'')+'>'+options[i].name;
  }
  return html;
}

function addKeyword() {
  var keyword = _getKeyword(document.getElementById('simpleKeyword'));
  getComponentById('object.keywordIds').addKeyword({keyword:keyword});
}

function advancedAddKeyword() {
  var args = {};
  args.keyword = _getKeyword(document.getElementById('advancedKeyword'));
  args.addFolder = document.getElementById('advancedAddFolder').checked ? 1 : 0;
  var elm = document.getElementById('advancedKeywordParent');
  args.parentId =  elm.options[elm.selectedIndex].value;
  getComponentById('object.keywordIds').addKeyword(args);
}

function _getKeyword(elm) {
  var keyword = elm.value;
  if( !keyword.match(/\w/) ) return null;
  elm.value = '';
  elm.focus();
  return keyword;
}

function loadParentKeywords() {
  o2.ajax.call({
    setClass  : "Keyword-KeywordEditor",
    setMethod : "getFolderKeywords",
    handler   : "loadParentKeywordsHandler"
  });
}

function loadParentKeywordsHandler(params) {
  setFolderKeywordOptions(params.folderKeywords);
}

function setFolderKeywordOptions(options) {
  var elm = document.getElementById('advancedKeywordParent');
  elm.options.length = 0;
  for( var i=0; i<options.length; i++ ) {
    elm.options[i]=new Option(options[i].name, options[i].id);
  }
}
