/**
 * The function in this script will be called by the Apps Script Execution API.
 */

/**
 * Accepts a Form ID and makes a copy with updated title, description, and destination.
 * @return String A string representing the ID of the new form.
 */
function copyFormAndUpdateProperties(originalFormID, title, description, destination) {
  var file = DriveApp.getFileById(originalFormID);
  var newFile = file.makeCopy();
  var newFormID = newFile.getId();
  var newForm = FormApp.openById(newFormID);
  newFile.setName(title);
  newForm.setTitle(title);
  newForm.setDescription(description);
  newForm.setDestination(FormApp.DestinationType.SPREADSHEET, destination);
  var newFormUrl = newForm.getPublishedUrl();
  try {
    var newFormShortUrl = newForm.shortenFormUrl(formUrl);
  }
  catch(e){
    // if the shortenFormUrl is having an issue, use the generic UrlShortener
    newFormShortUrl = UrlShortener.Url.insert({
      longUrl: newFormUrl
    }).id;
  }
  Logger.log('Copied Form %s to %s', originalFormID, newFormShortUrl);
  return newFormShortUrl;
}