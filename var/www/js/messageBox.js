var _____messageBoxCount = 0;

function MessageBox(id) {
  _____messageBoxCount++;
  if (id != null) {
    this.id = id;
  }
  else {
    this.id = "messageBox_" + _____messageBoxCount;
  }
  return this;
}

MessageBox.prototype.question = function(question, properties) {
  
}
