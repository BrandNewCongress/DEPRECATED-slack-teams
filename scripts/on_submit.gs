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
  var properties = PropertiesService.getUserProperties();
  var endpoint = properties.getProperty('BNCServiceURLEndpoint');
  var params = {'formId': formId};
  var response = UrlFetchApp.getRequest(endpoint, params)
  for(i in response) {
    Logger.log(i + ": " + response[i]);
  }
}