function CheckOnKeyPress(editor) {
  this.editor = editor;
}

CheckOnKeyPress._pluginInfo = {
  name          : "CheckOnKeyPress",
  version       : "1.0",
  developer     : "",
  developer_url : "",
  c_owner       : "Niko Sams",
  sponsor       : "",
  sponsor_url   : "",
  license       : "htmlArea"
};

CheckOnKeyPress.prototype.onKeyPress = function(ev) {
  var editor = this.editor;
  var elm = document.getElementById( editor._textArea.id );
  var onChange = elm.getAttribute("onChange") || elm.getAttribute("onchange");
  if (!onChange) {
    return;
  }
  var keyCode  = ev.which || ev.keyCode;
  // console.log(ev.ctrlKey + " " + ev.altKey + " " + ev.metaKey + " " + ev.shiftKey + " " + keyCode);

  if (ev.altKey) {
    return;
  }

  // Current selection may have been changed, let's save the new one:
  _ckp_editor = editor;
  if (this.timer) {
    clearTimeout(this.timer);
  }
  this.timer = setTimeout("_ckp_saveSelection();", 10); // Have to delay it a little bit to get the most recently selected letter(s)

  // Ctrl in combination with 1,2,3,4,5,6,e,r,y,u,i,l,z,x,v,b,n (lowercase and uppercase) may change the document
  var ctrlKeys = new Array(49, 50, 51, 52, 53, 54, 69, 73, 76, 77, 78, 82, 85, 86, 88, 89, 90, 98, 101, 105, 108, 109, 110, 114, 117, 118, 120, 121, 122);
  if (ev.ctrlKey) {
    // console.log("ctrlKey");
    var found = false;
    for (var i = 0; i < ctrlKeys.length; i++) {
      if (ctrlKeys[i] === keyCode) {
        found = true;
        break;
      }
    }
    if (!found) {
      return;
    }
  }

  var nonCharacterKeyIntervals = new Array(27, "33-40", 91, 93);
  for (var i = 0; i < nonCharacterKeyIntervals.length; i++) {
    var interval = nonCharacterKeyIntervals[i];
    var min, max;
    var matches = interval.toString().match(/^(\d+)-(\d+)$/);
    if (matches) {
      min = matches[1];
      max = matches[2];
    }
    else {
      min = max = interval;
    }
    if (keyCode >= min  &&  keyCode <= max) {
      // console.log("Returning");
      return;
    }
  }
  if (typeof(onChange) === "function") {
    onChange.call(this);
  }
  else if (typeof(onChange) === "string") {
    eval(onChange);
  }
  else {
    alert("Unknown typeof(onChange): " + typeof(onChange));
  }
}

function _ckp_saveSelection() {
  var editor = _ckp_editor;
  _ckp_editor = null;
  editor.o2CurrentSelection = editor.saveSelection();
}
