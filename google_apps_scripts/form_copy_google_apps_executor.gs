/**
 * The function in this script will be called by the Apps Script Execution API.
 */

/**
 * Accepts a Form ID and makes a copy with updated title, description, and destination.
 * @return String A string representing the ID of the new form.
 */
function copyFormAndUpdateProperties(originalFormID, title, description, destination) {
  var file = DriveApp.getFileById(originalFormID);
  var newFormID = file.makeCopy().getId();
  var newForm = FormApp.openById(newFormID);
  newForm.setTitle(title);
  newForm.setDescription(description);
  newForm.setDestination(FormApp.DestinationType.SPREADSHEET, destination);
  var newFormID = newForm.getId();
  Logger.log('Copied Form %s to %s', originalFormID, newFormID);
  return newFormURL;
}