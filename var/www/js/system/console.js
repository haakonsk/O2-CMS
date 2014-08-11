o2.addLoadEvent(toggleShowFilterLine);

function filterLinesByType(type) {
  var form = document.forms.filter;
  form.type.value = type;
  form.submit();
}

function refresh() {
  document.location.href = o2.urlMod.urlMod({ setMethod : "init" });
}

function resetConsole() {
  if (confirm("$lang->getString('lblDoResetConsole')")) {
    document.location.href = o2.urlMod.urlMod({ setMethod : "resetConsole" });
  }
}

function clearForm() {
  var form = document.forms.filter;
  var fields = ["fromDate", "toDate", "filterMatch", "type"];
  for (var i = 0; i < fields.length; i++) {
    form[ fields[i] ].value = "";
  }
}

function deleteRow(elm) {
  if (confirm("$lang->getString('confirmDeleteRow')")) {
    o2.ajax.call({
      setDispatcherPath : "o2cms",
      setClass          : "System-Console",
      setMethod         : "deleteLogEntry",
      setParams         : "rowId=" + elm.id,
      target            : elm.id,
      where             : "delete",
      method            : "post"
    });
  }
}

function toggleShowFilterLine() {
  var filterLine = document.getElementById("filterLine");
  if (filterLine.style.display == "none") {
    filterLine.style.display = "";
  }
  else {
    filterLine.style.display = "none";
  }
}

function deleteFilterMatches() {
  document.location.href = o2.urlMod.urlMod({ setMethod : "deleteByFilter" });
}

function showInfo(info) {
  info = info.replace( /</g, "&lt;" );
  info = info.replace( />/g, "&gt;" );
  top.messageBox("<pre>" + info + "</pre>");
}
