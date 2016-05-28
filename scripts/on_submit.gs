/**
 * This script should be attached to the original template form
 * that is copied for each event.
 * Requires a Script Property set with the key 'BNCServiceURLEndpoint'
 * and the value of the endpoint for the running service.
 *
 * Sadly, it requires some manual work when copied:
 * You must go to Resources > Current Project Triggers,
 * set up an onSubmit trigger to trigger the function onSubmit(e).
 * This requires clicking Allow on the oAuth popup.
 *
 * Requires the following scope to be authorized:
 * https://www.googleapis.com/auth/forms
 */

function onSubmit(e) {
  var form = FormApp.getActiveForm();
  var formId = form.getId();
  var properties = PropertiesService.getScriptProperties();
  var endpoint = properties.getProperty('BNCServiceURLEndpoint');
  var url = endpoint + '?formId=' + formId;
  Logger.log("Requesting URL: %s", url);
  var response = UrlFetchApp.fetch(url);
  var status = response.getResponseCode();
  Logger.log("Status Code: %s", status);
}