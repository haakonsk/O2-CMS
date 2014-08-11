var slotList      = new SlotList();
var slotsToReload = {};
var REVERT        = {};

function Slot(componentId) {
  this.id = componentId;
  this.slotId = this.id.substring(5); // remove 'slot_'
  initDragContainer(document.getElementById(this.id), {allowTextSelect:1});
}

// set what kind of objects this slot will accept
Slot.prototype.setAccepts = function(accepts) {
  this.accepts = accepts;
}

Slot.prototype.removeSlot = function() {
  slotList.removeSlot(this.slotId);
  this.reloadSlot();
}

function chopString(text, len, addon) {
  text += '';
  if (text.length <= len) {
    return text;
  }
  return text.substr(0,len) + addon;
}

Slot.prototype.redraw = function() {
  var headerElm = document.getElementById('slotHeader_' + this.slotId);
  if (!headerElm) {
    return alert('Error: Element for slot ' + this.slotId + ' not found!');
  }

  if (this.isDisabled) {
    headerElm.style.visibility = 'hidden';
    return;
  }

  var html = '<table cellpadding=0 cellspacing=0 border=0 width="100%"><tr>';
  if (slotList.getOverride(this.slotId, '_isInherited') == 1) {
    // html += 'inherited';
    //    headerElm.className = 'o2InheritedSlotHeader';
  }

  if (!slotList.isEmpty(this.slotId)) {
    // object-icon + title
    html += '<td align="left" width="18"><img src="' + top.getIconUrl(this.className) + '" dragId="' + slotList.getContentId(this.slotId) + '" title="' + this.name+'"></td>';
    html += '<td valign="middle" style="width:120px;">' + chopString(this.name, 12, '...');

    // edit object icon
    var objectId = slotList.getContentId(this.slotId);
    if (this.className != 'O2CMS::Obj::Template::Grid' && top.getEditUrl(this.className, objectId)) {
      html += '<a style="margin-left:4px" href="javascript:void(top.openObject(\'' + this.className + "'," + objectId + ",'" + this.name + '\'))"><img src="/images/system/edit_16.gif" title="' + o2.lang.getString("o2.pageEditor.helpTextEditObject") + '" border="0"></a>';
    }
    html += '</td>';

    // select template drop-down
    html += '<td align="right">';
    if (slotList.getTemplateId(this.slotId) && this.templateOptions && this.templateOptions.length > 1) { // select template only when more than one
      html += "<form style='display: inline;'>";
      html += '<img src="' + top.getIconUrl("O2CMS::Obj::Template") + '" onClick="getComponentById(\'' + this.id + '\').toggleDisplayTemplateSelectMenu();" title="' + o2.lang.getString("o2.pageEditor.helpTextTemplate") + '">';
      html += '<div id="slotTemplateDiv_' + this.id + '" class="o2SlotDropdown" style="display:none;">';
      html += '<div class="o2DropdownHeader">' + o2.lang.getString("o2.pageEditor.lblChooseTemplate") + ':</div>';
      html += '<select name="slotTemplate_' + this.id + '" id="slotTemplate_' + this.id + '" multiple="multiple" onchange="getComponentById(\'' + this.id + '\').templateSelectChanged(this);" class="templateDropDown">';
      for (var i = 0; i < this.templateOptions.length; i++) {
        var selected = this.templateOptions[i].id==slotList.getTemplateId(this.slotId) ? ' selected' : '';
        html += '<option value="' + this.templateOptions[i].id + '"' + selected + '>' + this.templateOptions[i].name;
      }
      html += '</select>';
      html += '</div>';
      html += "</form>";
    }

    html += '<a href="javascript:getComponentById(\'' + this.id + '\').reloadSlot()" title="' + o2.lang.getString("o2.pageEditor.helpTextReloadSlot") + '"><img border="0" src="/images/system/ref_16.gif"></a>';

    // we are inside a list. show lock icon
    if ( slotList.getOverride(this.slotId, '_isListItemSlot')==1 ) {
      html += '<a href="javascript:getComponentById(\'' + this.id + '\').toggleLocked()" title="' + o2.lang.getString("o2.pageEditor.helpTextLockSlot") + '"><img border="0" id="lockedIcon_' + this.slotId + '" src="/images/system/';
      html += slotList.getOverride(this.slotId, '_isLocked') ? 'lock_16.gif' : 'ulock_16.gif';
      html += '"></a>';
    }

    // this slot is a list. show +/- buttons
    if (slotList.getOverride(this.slotId, '_isListSlot') == 1) {
      headerElm.className = 'o2StaticSlotHeader';
      var maxItems = slotList.getOverride(this.slotId, '_maxItems');
      if ( ! maxItems>0 ) {
        maxItems = 0;
      }
      if (maxItems > 0) {
        html += '<img title="' + o2.lang.getString("o2.pageEditor.helpTextShortenList") + '" src="/images/system/remov_16.gif" onclick="getComponentById(\''+this.id+'\').changeMaxItems(-1)">';
      }
      html += '<img title="' + o2.lang.getString("o2.pageEditor.helpTextAddToList") + '" src="/images/system/add_16.gif" onclick="getComponentById(\''+this.id+'\').changeMaxItems(+1)">';
    }
    html += '<a href="javascript:getComponentById(\''+this.id+'\').removeSlot()" title="' + o2.lang.getString("o2.pageEditor.helpTextRemoveSlot") + '"><img border="0" src="/images/system/close_16.gif"></a>';

  }
  else {
    // This might be called "too often" here. Added to make sure empty slots get drop events. Without it the event goes to parent...
    // XXX Could call it at start of Editor->renderSlotContent(), where slot.redraw() is called...
    initDragContainer(document.getElementById(this.id), {allowTextSelect:1});
    html += "<td align='left'>" + o2.lang.getString("o2.pageEditor.msgSlotDropContentHere") + "</td>";
    if (this.grids && this.grids.length > 0) {
      html += this.getInsertGridHtml();
    }
    if (this.includes && this.includes.length > 0) {
      html += this.getInsertIncludeHtml();
    }
    document.getElementById('slotContent_'+this.slotId).innerHTML
      = this.emptyText   ?   this.emptyText   :   "<div class='emptySlotMsg'>[" + o2.lang.getString("o2.pageEditor.msgSlotEmpty") + "]</div><div class='emptySlotId'>" + this.slotId + "</div>";
  }

  // Set next-attributes (slot-chain)
  if (slotList.getOverride(this.slotId, '_isListSlot') == 1) {
    var i = 0;
    while (1) {
      var slotListElmId = this.slotId + ".slot" + i;
      var slot = getComponentById("slot_" + slotListElmId);
      var nextSlotListElmId = this.slotId + ".slot" + (i+1);
      if (!slotList.exists(nextSlotListElmId)) {
        break;
      }
      slot.nextSlot = nextSlotListElmId;
      i++;
    }
  }
  else if (slotList.getOverride(this.slotId, '_isListItemSlot') == 1) {
    if (!this.nextSlot) {
      var match = /[^\d](\d+)$/.exec(this.slotId);
      var origNum = parseInt(match[1]);
      var newNum  = origNum + 1;
      var nextSlotListElmId = this.slotId.replace(new RegExp(origNum + "$"), newNum);
      if (slotList.exists(nextSlotListElmId)) {
        this.nextSlot = nextSlotListElmId;
      }
    }
  }
  if (!this.defaultTemplate && slotList.getOverride(this.slotId, 'defaultTemplateId')) {
    var templateId         = slotList.getOverride(this.slotId, 'defaultTemplateId');
    this.defaultTemplate   = slotList.getOverride(this.slotId, 'defaultTemplateId');
    this.changeTemplate(templateId);
  }

  html += '</tr></table>';
  headerElm.innerHTML = html;
  if (!slotList.isEmpty(this.slotId) && !this.isPublishable) {
    o2.addClassName(headerElm.parentNode, "notPublishable");
  }
  else {
    o2.removeClassName(headerElm.parentNode, "notPublishable");
  }
}


Slot.prototype.changeMaxItems = function(add) {
  var newValue = (slotList.getOverride(this.slotId, '_maxItems')*1)+add;
  slotList.setOverride(this.slotId, '_maxItems', newValue);
  this.reloadSlot();
}

Slot.prototype.toggleLocked = function() {
  var isLocked = slotList.getOverride(this.slotId, '_isLocked') ? 0 : 1;
  slotList.setOverride(this.slotId, '_isLocked', isLocked);
  document.getElementById('lockedIcon_'+this.slotId).src = '/images/system/'+(isLocked ? 'lock_16.gif' : 'ulock_16.gif');
}

Slot.prototype.templateSelectChanged = function(elm) { // templateId) {
  // var templateId = elm.options[elm.selectedIndex].value;
  var templateId = unescape( o2.getSelectValuesAsString(elm.form, elm.name) );
  this.changeTemplate(templateId);
}

Slot.prototype.changeTemplate = function(templateId) {
  var slotTemplateElm = document.getElementById("slotTemplate_" + this.id);
  if (slotTemplateElm && slotTemplateElm.style.display != "none") {
    getComponentById(this.id).toggleDisplayTemplateSelectMenu(); // Hide template select
  }
  slotList.setTemplateId(this.slotId, templateId);
  this.reloadSlot();
}

Slot.prototype.getInsertGridHtml = function() {
  return this.getInsertIconHtml("Grid", {
    "title"   : o2.lang.getString("o2.pageEditor.helpTextGrid"),
    "label"   : o2.lang.getString("o2.pageEditor.lblChooseGrid"),
    "iconUrl" : top.getIconUrl("O2CMS::Obj::Template::Grid")
  });
}

Slot.prototype.getInsertIncludeHtml = function() {
  return this.getInsertIconHtml("Include", {
    "title"   : o2.lang.getString("o2.pageEditor.helpTextInclude"),
    "label"   : o2.lang.getString("o2.pageEditor.lblChooseInclude"),
    "iconUrl" : top.getIconUrl("O2CMS::Obj::Template::Include")
  });
}

Slot.prototype.getInsertIconHtml = function(Type, params) {
  var type = Type.toLowerCase();
  eval("var templates = this." + type + "s;");
  var html = "";
  html += "<td align='right' width='20'>";
  html += "<form style='display: inline;'>";
  html += "<img src='" + params.iconUrl + "' onClick='getComponentById(\"" + this.id + "\").toggleDisplay" + Type + "SelectMenu();' title='" + params.title + "'>";
  html += '<div id="' + type + 'Div_' + this.id + '" class="o2SlotDropdown" style="display:none;">';
  html += '<div class="o2DropdownHeader">' + params.label + ':</div>';
  html += '<select name="' + type + '_' + this.id + '" id="' + type + '_' + this.id + '" multiple="multiple" onchange="getComponentById(\''+this.id+'\').' + type + 'Inserted(this);" class="' + type + 'Selector" class="templateDropdown">';
  for (var i = 0; i < templates.length; i++) {
    html += '<option value="'+templates[i].id+'_'+templates[i].name+'">' + templates[i].name + '</option>';
  }
  html += '</select>';
  html += '</div>';
  html += "</form>";
  html += "</td>";
  return html;
}

Slot.prototype.includeInserted = function(elm) {
  this.includeOrGridInserted('Include', elm);
}

Slot.prototype.gridInserted = function(elm) {
  this.includeOrGridInserted('Grid', elm);
}

Slot.prototype.includeOrGridInserted = function(Type, elm) {
  var type = Type.toLowerCase();
  var selectElm = document.getElementById(type + "_" + this.id);
  if (selectElm && selectElm.style.display != "none") {
    // Hide select menu
    eval("getComponentById(this.id).toggleDisplay" + Type + "SelectMenu();");
  }
  var idAndName = unescape( o2.getSelectValuesAsString(elm.form, elm.name) );
  idAndName = idAndName.split("_");
  var id   = idAndName[0];
  var name = idAndName[1];
  this.updateContent(id, name, "O2CMS::Obj::Template::" + Type);
  this.reloadSlot();
}

Slot.prototype.reloadSlot = function(notYet) {
  if (notYet) {
    slotsToReload[ this.slotId ] = {
      'slotId'          : this.slotId,
      'templateMatch'   : this.templateMatch,
      'defaultTemplate' : this.defaultTemplate,
      'nextSlot'        : this.nextSlot
    };
  }
  else {
    var params = {
      id              : PAGE_EDITOR_GLOBALS.objectInfo.id,
      className       : PAGE_EDITOR_GLOBALS.objectInfo.className,
      title           : PAGE_EDITOR_GLOBALS.objectInfo.title,
      slotId          : this.slotId,
      templateMatch   : this.templateMatch,
      defaultTemplate : this.defaultTemplate,
      nextSlot        : this.nextSlot,
      slots           : slotList.getSlots(),
      defaultSlots    : slotList.listDefaultSlots()
    };
    o2.ajax.call({
      setClass     : "Page-Editor",
      setMethod    : "renderSlot",
      setParams    : params,
      onSuccess    : "REVERT = {};",
      handler      : "getComponentById('" + this.id + "').reloadSlotHandler",
      errorHandler : "revertSlotList"
    });
  }
}

function revertSlotList(result) {
  for (var key in REVERT) {
    slotList.setContentId( key, REVERT[key] );
  }
  REVERT = {};
  top.displayError(result.errorMsg);
}

function reloadSlots() {
  var params = {
    slotsToReload : slotsToReload,
    id            : PAGE_EDITOR_GLOBALS.objectInfo.id,
    className     : PAGE_EDITOR_GLOBALS.objectInfo.className,
    title         : PAGE_EDITOR_GLOBALS.objectInfo.title,
    slots         : slotList.getSlots(),
    defaultSlots  : slotList.listDefaultSlots()
  };
  o2.ajax.call({
    setClass     : "Page-Editor",
    setMethod    : "renderSlots",
    setParams    : params,
    onSuccess    : "REVERT = {};",
    handler      : "reloadSlotsHandler",
    errorHandler : "revertSlotList"
  })
  slotsToReload = {}; // Reset
}

function reloadSlotsHandler(params) {
  for (var i = 0; i < params.slots.length; i++) {
    var slotStruct = params.slots[i];
    var slotId     = slotStruct.id;
    var slot       = getComponentById("slot_" + slotId);
    slot.reloadSlotHandler(slotStruct);
  }
}

Slot.prototype.reloadSlotHandler = function (params) {
  var elm = document.getElementById('slotContent_' + this.slotId);
  elm.innerHTML = unescape(params.content);
  var jsFiles = o2.split(/,\s*/, params.jsFiles);
  var head = document.getElementsByTagName("head").item(0);
  for (var i = 0; i < jsFiles.length; i++) {
    // Doesn't work to append to head.innerHTML here! (Firefox, at least)
    var jsElm = document.createElement("script");
    jsElm.setAttribute( "type", "text/javascript" );
    jsElm.setAttribute( "src",  jsFiles[i]        );
    head.appendChild(jsElm);
  }
  var cssFiles = o2.split(/,\s*/, params.cssFiles);
  for (var i = 0; i < cssFiles.length; i++) {
    var cssElm = document.createElement("link");
    cssElm.setAttribute( "rel",  "stylesheet" );
    cssElm.setAttribute( "type", "text/css"   );
    cssElm.setAttribute( "href", cssFiles[i]  );
    head.appendChild(cssElm);
  }
  try {
    eval(params.execute);
  }
  catch (e) {
    alert( "reloadSlotHandler error in expression " + params.execute + ": " + o2.getExceptionMessage(e) );
  }
  this.redraw();
}

var ONDROP_SOURCE, ONDROP_TARGET, ONDROP_EVENT;
Slot.prototype.ondrop = function(source, target, event) {
  ONDROP_SOURCE = source;
  ONDROP_TARGET = target;
  ONDROP_EVENT  = event;
  var params = {
    objectId  : source.data.id,
    slotId    : target.component.id,
    pageUrl   : PAGE_EDITOR_GLOBALS.objectInfo.pageUrl
  };
  o2.ajax.call({
    setClass  : "Page-Editor",
    setMethod : "checkDroppedObject",
    setParams : params,
    handler   : "getComponentById('" + target.component.id + "').ondrop2"
  });
}

Slot.prototype.ondrop2 = function(params) {
  this.updateContent(ONDROP_SOURCE.data.id, ONDROP_SOURCE.data.name, ONDROP_SOURCE.data.className, ONDROP_SOURCE.component.id, ONDROP_TARGET);
  reloadSlots();
  ONDROP_EVENT.cancelBubble = true;
  ONDROP_SOURCE = null;
  ONDROP_TARGET = null;
  ONDROP_EVENT  = null;
}

Slot.prototype.updateContent = function(sourceDataId, sourceDataName, sourceDataClassName, sourceComponentId, target) {
  // not allowed to drop content on a disabled slot
  if( this.isDisabled ) return;
  // alert(sourceDataId + " " + sourceDataName + " " + sourceDataClassName + " " + sourceComponentId);

  if (target && !target.data) {
    target.data = getComponentById(target.component.id).getDragDataById();
  }

  // Slot-chain stuff:
  if (this.nextSlot && sourceComponentId && sourceComponentId == 'tree' && !slotList.isEmpty(this.slotId)) {
    var nextSlotIds = this.nextSlot.split(",");
    for (var i = 0; i < nextSlotIds.length; i++) {
      var nextSlotId = nextSlotIds[i];
      nextSlotId = nextSlotId.replace(/^\s+/, ""); // trim
      nextSlotId = nextSlotId.replace(/\s+$/, ""); // trim
      var componentId = "slot_" + nextSlotId;

      // Try different scopes
      var parents = this.slotId.split(".");
      parents.pop();    // The text after the last "." is the id of the slot - not part of scope.
      parents.push(""); // Wanna try without scoping first
      parents = parents.reverse();
      var scope = "";
      var componentFound = false;
      for (var j = 0; j < parents.length; j++) {
        scope  =  scope  ?  scope + "." + parents[j]  :  parents[j];
        var componentId = "slot_" + (scope ? scope + "." : "") + nextSlotId;
        if (getComponentById(componentId)) {
          getComponentById(componentId).updateContent(slotList.getContentId(this.slotId), this.name, this.className, sourceComponentId); // Recursive call
          componentFound = true;
          break;
        }
      }
      if (!componentFound) {
        alert("getComponentById('" + componentId + "') failed.");
      }
    }
  }

  // check if this slot accepts the dropped class
  var accepted = this.accepts.length == 0; // accept anything if array is empty
  var acceptedNames = '';
  for (var i = 0; i < this.accepts.length; i++) {
    acceptedNames  +=  (acceptedNames ? ',' : '')  +  this.accepts[i];
    if (sourceDataClassName.indexOf( this.accepts[i] )  >=  0) {
      accepted = true;
    }
  }
  if (!accepted) {
    return top.displayError( o2.lang.getString('o2.pageEditor.errorSlotInvalidObject', { 'acceptedNames' : acceptedNames }) );
  }

  REVERT[this.slotId] = slotList.getContentId(this.slotId);
  slotList.setContentId(this.slotId, sourceDataId);
  this.name       = sourceDataName;
  this.className  = sourceDataClassName;
  this.reloadSlot(true);

  if (sourceComponentId && sourceComponentId.indexOf('slot_') == 0 && target) {
    // Switch content in the two slots
    getComponentById(sourceComponentId).updateContent(target.data.id, target.data.name, target.data.className, target.component.id);
  }
}

Slot.prototype.ondragend = function(source,target) {
  if (source.component.id.indexOf('slot_') != 0 || !target) {
    slotList.setContentId(this.slotId, null);
    slotList.setTemplateId(this.slotId, null);
    this.reloadSlot();
  }
}

Slot.prototype.getDragDataById = function(dragId) {
  return {
    name      : this.name,
    className : this.className,
    id        : slotList.getContentId(this.slotId),
    slotId    : this.slotId
  };
}


// called from taglib to change slotcontent
Slot.prototype.setContentInfo = function(info) {
  //  if( info.contentId>0 ) slotList.setTemplateId(this.slotId, info.templateId);

  //this.contentId = info.contentId;

  //if( this.slotId=='right.slot1' ) alert(info.localSlot.override['_isListItemSlot']);
  
  if (info.localSlot.contentId > 0) {
    var localSlot = slotList.getCreatedSlotById(this.slotId);
    localSlot.contentId  = info.localSlot.contentId;
    localSlot.templateId = info.localSlot.templateId;
    localSlot.override   = info.localSlot.override;
  }
  if (info.externalSlot.contentId > 0) {
    var externalSlot        = slotList.getCreatedDefaultSlotById(this.slotId);
    externalSlot.contentId  = info.externalSlot.contentId;
    externalSlot.templateId = info.externalSlot.templateId;
    externalSlot.override   = info.externalSlot.override;
  }

  // html set via ajax may contain slots. update eventhandlers for drag and drop.
  initDragContainer(document.getElementById(this.id), {allowTextSelect:1});

  
  this.name             = info.name;
  this.className        = info.className;
  this.templateOptions  = info.templateOptions;
  this.grids            = info.grids;
  this.includes         = info.includes;
  this.templateMatch    = info.templateMatch;
  this.defaultTemplate  = info.defaultTemplate;
  this.isDisabled       = info.isDisabled==1 ? 1 : 0;
  this.emptyText        = info.emptyText;
  this.nextSlot         = info.nextSlot;
  this.isPublishable    = info.isPublishable;
  this.redraw();
}

Slot.prototype.toggleDisplayTemplateSelectMenu = function() {
  this.toggleDisplaySelectMenu("slotTemplate", this.templateOptions.length);
}

Slot.prototype.toggleDisplayIncludeSelectMenu = function() {
  this.toggleDisplaySelectMenu("include", this.includes.length);
}

Slot.prototype.toggleDisplayGridSelectMenu = function() {
  this.toggleDisplaySelectMenu("grid", this.grids.length);
}

Slot.prototype.toggleDisplaySelectMenu = function(type, numOptions) {
  // hide the "others"
  var types = new Array("slotTemplate", "include", "grid");
  var slotContentElm = document.getElementById('slotContent_' + this.slotId);
  for (var i = 0; i < types.length; i++) {
    if (type !== types[i]) { // hide it
      var div = document.getElementById(types[i] + "Div_"  + this.id);
      if (div) {
        div.style.display              = "none";
        slotContentElm.style.minHeight = "";
        slotContentElm.style.height    = "";
      }
    }
  }
  
  var div = document.getElementById(type + "Div_"  + this.id);
  var elm = document.getElementById(type + "_"     + this.id);
  
  elm.size = numOptions;
  if (div.style.display == "none") {
    div.style.display = "";
  }
  else {
    div.style.display = "none";
  }
}

// represents an overrideable image
function ImageField(componentId) {
  this.id     = componentId;
  this.slotId = componentId.substring(11);
  var dotIx     = this.slotId.lastIndexOf('.');
  this.property = this.slotId.substring(dotIx+1);
  this.slotId   = this.slotId.substring(0,dotIx);
  initDragContainer( document.getElementById(this.id) );
}

ImageField.prototype.setImageId = function(imageId) {
  o2.ajax.call({
    setClass  : "Page-Editor",
    setMethod : "getImageInfo",
    setParams : { imageId : imageId, width : this.width, height : this.height },
    handler   : "getComponentById('"+this.id+"').setImageIdHandler"
  });
}

ImageField.prototype.setImageIdHandler = function(params) {
  this.setImageInfo(params);
}


ImageField.prototype.ondrop = function(source, target) {
  slotList.setOverride(this.slotId, this.property, source.data.id);
  this.setImageId(source.data.id);
  this.redraw();
}

ImageField.prototype.redraw = function() {
  var elm = document.getElementById(this.id);
  if (this.imageId) {
    elm.innerHTML = '<img src="'+this.imageUrl+'" alt="'+this.name+'" title="'+this.name+'">';
  }
  else {
    elm.innerHTML = "<div class='emptySlotMsg'>[" + o2.lang.getString("o2.pageEditor.msgSlotEmpty") + "]</div><div class='emptySlotId'>" + this.slotId + "</div>";
  }
}

ImageField.prototype.setImageInfo = function(info) {
  this.imageId   = info.imageId;
  this.name      = info.name;
  this.imageUrl  = info.imageUrl;
  this.width     = info.width;
  this.height    = info.height;
  this.redraw();
}


function SlotList() {
  this.slots = {};
  this.defaultSlots = {};
}

SlotList.prototype.setSlots = function(slots) {
  this._setSlots(slots, this.slots);
}
SlotList.prototype.setDefaultSlots = function(slots) {
  this._setSlots(slots, this.defaultSlots);
}

SlotList.prototype._setSlots = function(slots,slotHash) {
  for (var slotId in slots) {
    slotHash[slotId] = slots[slotId];
  }
}
// remove all default slots below a slot
SlotList.prototype.removeDefaultSlot = function(slotId) {
  for( var defaultSlotId in this.defaultSlots ) {
    if( defaultSlotId.indexOf(slotId+'.')==0 || defaultSlotId==slotId) {
      delete this.defaultSlots[defaultSlotId];
    }
  }
}

// returns true if this slot gets it's content from a default slot
SlotList.prototype.usingDefaultSlot = function(slotId) {
  return (this.slots[slotId] && this.slots[slotId].contentId > 0);
}


// make sure we have a slot called slotId, and return it
SlotList.prototype.getCreatedSlotById = function(slotId) {
  if( !this.slots[slotId] ) {
    this.slots[slotId] = {
      contentId  : null,
      templateId : null,
      override   : {}
    };
  }
  return this.slots[slotId];
}
// make sure we have a default slot called slotId, and return it
SlotList.prototype.getCreatedDefaultSlotById = function(slotId) {
  if( !this.defaultSlots[slotId] ) {
    this.defaultSlots[slotId] = {
      contentId  : null,
      templateId : null,
      override   : {}
    };
  }
  return this.defaultSlots[slotId];
}
SlotList.prototype.setContentId = function(slotId,contentId) {
  var slot = this.getCreatedSlotById(slotId);
  slot.contentId = contentId;
}
SlotList.prototype.setTemplateId = function(slotId,templateId) {
  var slot = this.getCreatedSlotById(slotId);
  slot.templateId = templateId;
}
SlotList.prototype.setOverride = function(slotId,name,value) {
  var slot = this.getCreatedSlotById(slotId);
  slot.override[name] = value;
}
SlotList.prototype.getOverride = function(slotId,name) {
  //  var slot = this.getCreatedSlotById(slotId);
  var slot = this.resolveSlotById(slotId); // use slot, or fallback to external slot. vonheim@20061123
  if (!slot) {
    return;
  }
  return slot.override[name];
}

// find slot in use. Will look in slots first, then defaultSlots.
SlotList.prototype.resolveSlotById = function(slotId) {
  if (this.slots[slotId] && this.slots[slotId].contentId > 0) {
    return this.slots[slotId];
  }
  if (this.defaultSlots[slotId]) {
    return this.defaultSlots[slotId];
  }
  return;
}

SlotList.prototype.getContentId = function(slotId) {
  var slot = this.resolveSlotById(slotId);
  return slot ? slot.contentId : null;
}

SlotList.prototype.getTemplateId = function(slotId) {
  var slot = this.resolveSlotById(slotId);
  return slot ? slot.templateId : null;
}


// return true if slot has local content
SlotList.prototype.isLocal = function(slotId) {
  return (this.slots[slotId] && this.slots[slotId].contentId > 0);
}

// return true if slot has external content
SlotList.prototype.isExternal = function(slotId) {
  return !this.isLocal(slotId) && (this.defaultSlots[slotId] && this.defaultSlots[slotId].contentId > 0);
}

// returns true if slot is empty
SlotList.prototype.isEmpty = function(slotId) {
  return !this.isLocal(slotId) && !this.isExternal(slotId);
}

SlotList.prototype.exists = function(slotId) {
  var id = "slot_" + slotId;
  var slot = getComponentById(id);
  return slot ? true : false;
}

SlotList.prototype.removeSlot = function(slotId) {
  delete(this.slots[slotId]);
}

SlotList.prototype.getSlots = function() {
  return this.slots;
}
SlotList.prototype.listDefaultSlots = function() {
  return this.defaultSlots;
}

SlotList.prototype.toString = function() {
  var str = '';
  str += 'Slots\n'        + this._slotsToString(this.slots);
  str += 'DefaultSlots\n' + this._slotsToString(this.defaultSlots);
  return str;
}
SlotList.prototype._slotsToString = function(slots) {
  var slotIds = [];
  for (var slotId in slots) {
    slotIds[slotIds.length] = slotId;
  }
  slotIds.sort();
  var str = '';
  for (var i = 0; i < slotIds.length; i++) {
    var slot = slots[ slotIds[i] ];
    str += '\t' + slotIds[i] + ': c' + slot.contentId + '/t' + slot.templateId + ' [';
    for (var name in slot.override) {
      str += name + ':"'+slot.override[name] + '" ';
    }
    str += ']\n';
  }
  return str;
}


var IS_SAVE_AND_CLOSE = false;

function o2Save() {
  if (PAGE_EDITOR_GLOBALS.objectInfo.id) { // existing object?
    o2DoSave();
  }
  else {
    o2.openWindow.openWindow({ url : PAGE_EDITOR_GLOBALS.saveUrl });
  }
}

function saveAsDialogCallback(folderId, filename, objectId) {
  PAGE_EDITOR_GLOBALS.objectInfo.parentId = folderId;
  PAGE_EDITOR_GLOBALS.objectInfo.name = filename;
  o2DoSave();
  return true;
}

function o2DoSave() {
  // hack for getting hold of localized titles
  if (o2LocalesAvailable.length > 0) {
    var localeCode = o2.multilingualController.currentActiveLocaleCode;
    o2.multilingualController.switchToLocale( o2LocalesAvailable[0].localeCode );
    var localizedTitles = {}; // hash for holding title in all languages
    if (PAGE_EDITOR_GLOBALS.pageObjIsaO2ObjPage) {
      for (var i = 0; i < o2LocalesAvailable.length; i++) {
        var locale = o2LocalesAvailable[i].localeCode;
        var title  = document.getElementById(locale + '.title').value;
        localizedTitles[locale] = title;
        PAGE_EDITOR_GLOBALS.objectInfo.title[locale] = title;
      }
    }
    o2.multilingualController.switchToLocale(localeCode); // Switch back
  }

  var params = {
    id            : PAGE_EDITOR_GLOBALS.objectInfo.id,
    name          : PAGE_EDITOR_GLOBALS.objectInfo.name,
    parentId      : PAGE_EDITOR_GLOBALS.objectInfo.parentId,
    className     : PAGE_EDITOR_GLOBALS.objectInfo.className,
    title         : localizedTitles,
    templateId    : PAGE_EDITOR_GLOBALS.objectInfo.templateId,
    slots         : slotList.getSlots(),
    cacheThisPage : PAGE_EDITOR_GLOBALS.objectInfo.cacheThisPage
  };
  o2.ajax.call({
    setClass  : "Page-Editor",
    setMethod : "save",
    setParams : params,
    handler   : "o2DoSavePageHandler",
    method    : "post"
  });
}

function o2DoSavePageHandler(params) {
  top.displayMessage('"' + params.name + '" was saved');
  PAGE_EDITOR_GLOBALS.objectInfo.id = params.id;
  top.reloadTreeFolder(params.parentId);
  if (IS_SAVE_AND_CLOSE) {
    top.closeFrame(window.name);
  }
}

function slotFocus(slotId) {
  var slotHeader = document.getElementById( 'slotHeader_' + slotId );
  
  if ( slotHeader.style.display == 'block'  ||  slotList.isExternal(slotId) ) {
    return;
  }
  
  slotHeader.style.display = 'block';
  
  if ( PAGE_EDITOR_GLOBALS.alwaysShowEntireSlotContent ) {
    var extraPadding = parseInt( slotHeader.offsetHeight );
    var slotContent  = document.getElementById( 'slotContent_' + slotId );
    var oldPadding   = slotContent.style.paddingTop ? parseInt(slotContent.style.paddingTop) : 0;
    
    slotContent.style.paddingTop = (oldPadding + extraPadding)  +  "px";
  }
}

function slotUnfocus(slotId) {
  if (slotList.isExternal(slotId)) {
    return;
  }
  // var slotTemplateElm = document.getElementById("slotTemplate_slot_" + slotId);
  // if (slotTemplateElm && slotTemplateElm.style.display != "none") {
  //   getComponentById("slot_" + slotId).toggleDisplayTemplateSelectMenu();
  // }
  if (PAGE_EDITOR_GLOBALS.alwaysShowEntireSlotContent) {
    var slotContent  = document.getElementById('slotContent_' + slotId);
    var oldPadding   = slotContent.style.paddingTop ? parseInt(slotContent.style.paddingTop) : 0;
    var extraPadding = parseInt(document.getElementById('slotHeader_' + slotId).offsetHeight);
    slotContent.style.paddingTop = (oldPadding - extraPadding)  +  "px";
  }
  document.getElementById('slotHeader_'+slotId).style.display = 'none';
}



function setNewTemplateId(templateId) {
  // 20070731 nilschd feilen som oppstår her, problmer med objectInfo?
  try {
    PAGE_EDITOR_GLOBALS.objectInfo.templateId = templateId;
    reloadPage();
  }
  catch (e) {
    alert( o2.getExceptionMessage(e, true) );
  }
  //20070731 end change nilschd
}

// reload page without loosing added modifications
function reloadPage() {
  var pageData = {
    id         : PAGE_EDITOR_GLOBALS.objectInfo.id,
    name       : PAGE_EDITOR_GLOBALS.objectInfo.name,
    parentId   : PAGE_EDITOR_GLOBALS.objectInfo.parentId,
    className  : PAGE_EDITOR_GLOBALS.objectInfo.className,
    title      : PAGE_EDITOR_GLOBALS.objectInfo.title,
    templateId : PAGE_EDITOR_GLOBALS.objectInfo.templateId,
    slots      : slotList.getSlots()
  };
  document.forms.o2ReloadPageForm.pageData.value = o2.dumpXml(pageData);
  document.forms.o2ReloadPageForm.submit();
}

// Show page as it would look frontend
function preview() {
  document.forms.o2ReloadPageForm.target      = '_new';
  document.forms.o2ReloadPageForm.media.value = 'Html';
  reloadPage();
  document.forms.o2ReloadPageForm.target      = '';
  document.forms.o2ReloadPageForm.media.value = 'Editor';
}

// go back to original version
function o2RevertChanges() {
  if (PAGE_EDITOR_GLOBALS.objectInfo.id > 0) {
    window.location = '/o2cms/Page-Editor/edit?objectId=' + PAGE_EDITOR_GLOBALS.objectInfo.id + "&templateType=" + PAGE_EDITOR_GLOBALS.templateType;
  }
  else {
    var url = '/o2cms/Page-Editor/newPage?parentId=' + PAGE_EDITOR_GLOBALS.objectInfo.parentId;
    url += '&templateType=' + PAGE_EDITOR_GLOBALS.templateType;
    url += '&templateId='   + PAGE_EDITOR_GLOBALS.objectInfo.templateId;
    url += '&name='         + PAGE_EDITOR_GLOBALS.objectInfo.name;
    url += '&className='    + PAGE_EDITOR_GLOBALS.objectInfo.className;
    url += '&title='        + PAGE_EDITOR_GLOBALS.objectInfo.title;
    window.location = url;
  }
}

function togglePageControls() {
  var elm = document.getElementById('o2PageControls');
  elm.className = elm.className=='o2PageControlsOn' ? 'o2PageControlsOff' : 'o2PageControlsOn';
}

function toggleEditSlotString(slotId) {
  var textarea = document.getElementById("slotString_" + slotId);
  var textareaWasHidden = textarea.style.display === "none";
  textarea.style.display = textareaWasHidden ? "inline" : "none";
  var slotStringValueElm = document.getElementById("slotStringValue_" + slotId);
  slotStringValueElm.style.display = textareaWasHidden ? "none" : "inline";
  if (!textareaWasHidden) {
    slotStringValueElm.innerHTML = textarea.value;
  }
}
