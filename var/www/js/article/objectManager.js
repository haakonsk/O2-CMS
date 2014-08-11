function insertObject(file, target) {
  window.opener.richText_addObject(file, {target : target});
  window.close();
}

function fileChange(ix) {
  var path  = document.getElementById('upload'+ix).value;
  if( !path ) return previewElm.innerHTML = '';
  var ext = path.substring(path.lastIndexOf('.')+1).toLowerCase();
  // windows or unix path?
  var filename = path.indexOf('\\')>=0 ? path.substring(path.lastIndexOf('\\')+1) : path.substring(path.lastIndexOf('/')+1); // '
  document.getElementById('name'+ix).value = filename;
}

// called when chooseFolder changes file
var currentFile = null;
var currentFolder = null;
function objectChanged(file) {

  if ( file.isContainer ) {
    var scriptData = $('#fileUpload').uploadifySettings('scriptData');
    scriptData.parentId = file.id;
    $('#fileUpload').uploadifySettings( 'scriptData', scriptData );
    currentFolder = file.id;
  }

  currentFile = file;
  o2.lang.setCurrentPrefix('o2.article.objectManager');
  document.getElementById('insertObjectButton').value
    = (file.className == 'O2::Obj::Image'  ?  o2.lang.getString("btnInsertImage")  :  o2.lang.getString("btnInsertLink"))   +   ": \"" + file.name + '"';
  return true;
}

function reloadFolder () {
  if (currentFolder) {
    setFolderId_folderId( currentFolder );
  }
}


// called when a file was uploaded
function fileUploaded(file) {
  document.getElementById('progressBar').style.display = 'none';
  window.opener.top.reloadTreeFolder(file.parentId);
  insertObject(file);
}

function uploadFile(formElm) {
  document.getElementById('progressBar').style.display = 'block';
  formElm.submit();
}

function showUploadFile() {
  document.getElementById('uploadFileButton').style.display='none';
  document.getElementById('fileUploadDiv').style.display='block';
  top.resizeTo(780,700);
}
