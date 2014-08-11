/**
 Description:
 String, number and date utility functions

 $Id: $
*/



/**
 Replace variables in a template.
 Example: subst('Hello %%name%%!', ['name','World']) would return 'Hello World'
 From base.js
*/
function subst (content, substs) {
  var idx=0;
  for (var i=0; i<substs.length; i+=2) {
    if (substs[i]=='.*') {content=content.replace(/%%[^%]+%%/g, '')}
    else {
      idx=content.indexOf('%%'+substs[i]+'%%',0);
      while (idx!=-1 && idx<content.length) {
        content=content.substring(0,idx)+substs[i+1]+content.substring(idx+(substs[i].length+4));
        idx=content.indexOf('%%'+substs[i]+'%%',idx);
      }
    }
  }
  return content;
}


// convert dots to commas in numbers
function js2human(jsNumber,decimals) {
  if( decimals==null ) decimals=2;
        return _commaFix(fixDecimals(jsNumber,decimals),'.',',');
}

// convert commas to dots in numbers
function human2js(humanNumber) {
  var jsNumber = parseFloat(_commaFix(humanNumber,',','.'));
  return jsNumber>0 || jsNumber<0 ? jsNumber : 0;
}

// replace "oldComma" with "newComma"
function _commaFix(theNumber,oldComma,newComma) {
  if( theNumber==null || theNumber.length==0 ) return theNumber;
  theNumber+=''; // cast to string
  var commaIx = theNumber.indexOf(oldComma);
  return commaIx>=0 ? theNumber.substring(0,commaIx)+newComma+theNumber.substring(commaIx+1) : theNumber;
}
                                                                                                                                                                 
// return "theNumber" with "decimalCount" decimals
function fixDecimals(theNumber,decimalCount) {
  if( !isFinite(theNumber) ) return theNumber;
  return Math.round(theNumber*Math.pow(10,decimalCount))/Math.pow(10,decimalCount)*1.0;
}
                                                                                                                                                                 
// pad a number with zeroes
function zeroPad(theNumber,digitCount) {
  if( theNumber==null ) return null;
  theNumber = ''+theNumber;
  for( var i=theNumber.length; i<digitCount; i++ ) {
     theNumber = '0'+theNumber+'';
  }
  return theNumber;
}
