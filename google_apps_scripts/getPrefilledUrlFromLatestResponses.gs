/**
 * The function in this script will be called by the Apps Script Execution API.
 */

/**
 * Accepts a formId, gets the latest responses for that form and returns a prefilled url with them.
 * @return An object containing the prefilled URL and the destination ID of the form (for matching).
 */
function getPrefilledUrlFromLatestResponses(formId) {
  var form = FormApp.openById(formId);
  var responses = form.getResponses();
  if (responses.length == 0) {
    return;
  }
  
  var latestResponses = responses[responses.length - 1];
  Logger.log("Latest Responses: %s", latestResponses);
  
  var prefilledUrl = latestResponses.toPrefilledUrl();
  var prefilledShortUrl = shortenUrl(prefilledUrl);
  Logger.log('Created short prefilled url %s', prefilledShortUrl);
  
  destinationId = form.getDestinationId();
  return {
    'prefilledFormUrl': prefilledShortUrl,
    'destinationId': destinationId
  };
}

/*
 * Attempts to shorten the Url with the built-in function, but apparently that fails sometimes,
 * so falls back to the UrlShortener service (which requires an extra scope permission).
 */
function shortenUrl(url) {
  try {
    var prefilledShortUrl = newForm.shortenFormUrl(url);
  }
  catch(e){
    // if the shortenFormUrl is having an issue, use the generic UrlShortener
    prefilledShortUrl = UrlShortener.Url.insert({
      longUrl: url
    }).id;
  }
  return prefilledShortUrl;
}