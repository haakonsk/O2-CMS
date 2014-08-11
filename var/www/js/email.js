function chkEmailAdr(email) {
  var reg1 = /(@.*@)|(\.\.)|(@\.)|(\.@)|(^\.)/; // not valid
  var reg2 = /^.+\@(\[?)[a-zA-Z0-9\-\.]+\.([a-zA-Z]{2,3}|[0-9]{1,3})(\]?)$/; // valid
  if (!reg1.test(email) && reg2.test(email)) { // if syntax is valid
    return true;
  }
  return false;
}
