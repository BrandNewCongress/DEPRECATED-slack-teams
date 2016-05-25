function onOpen(e) {
  var form = FormApp.getActiveForm();
  var slackQuestion = form.getItems()[0];
  if (slackQuestion.getType() == 'MULTIPLE_CHOICE') {
    var multChoiceQ = slackQuestion.asMultipleChoiceItem();
    var sheet = SpreadsheetApp.openById("1ssB_4ve0yx-ZNZkkqoWXxMp57qGRNdmoByvJ3PQSaaM").getSheets()[0];
    // Get first column which is the channel name
    var channels = sheet.getDataRange().getDisplayValues().map(function(value,index) { return value[0]; });
    multChoiceQ.setChoiceValues(channels);
  }
}

function onEdit(e) {
  var form = FormApp.getActiveForm();
  var responses = form.getResponses();
  // TODO: Populate responses based on the answer to the first question (Slack channel).
  // For now, just log the responses.
  for (var i = 0; i < responses.length; i++) {
    var formResponse = responses[i];
    var itemResponses = formResponse.getItemResponses();
    for (var j = 0; j < itemResponses.length; j++) {
      var itemResponse = itemResponses[j];
      Logger.log('Response #%s to the question "%s" was "%s"',
                (i + 1).toString(),
                itemResponse.getItem().getTitle(),
                itemResponse.getResponse());
    }
  }
}

function onSubmit() {
  // This has been installed in "Resources > Current Project Triggers"
  // It will be called whenever form is submitted
}
