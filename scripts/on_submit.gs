/**
 * This script should be attached to the original template form
 * that is copied for each event.
 * Requires a User Property set with the key 'BNCServiceURLEndpoint'
 * and the value of the endpoint for the running service.
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