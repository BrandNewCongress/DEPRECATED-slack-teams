function addQuestionsToForm(formKey) {
  var form = FormApp.openById(formKey);
  var items = form.getItems();
  var count = items.length;
  if (count < 1) {
    Logger.log('Form has no items, bailing out.')
    return false
  }

  var firstItemTitle = 'BNC Events Team Contact';
  if (items[1].getTitle() !== firstItemTitle) {
     // Prepend Item: BNC Events Team Contact
    var firstItem = form.addTextItem();
    firstItem.setTitle(firstItemTitle);
    form.moveItem(firstItem.getIndex(), 1);
  }
  
  var signInTitle = 'Sign-in sheet uploaded?';
  if (items[count - 3].getTitle() !== signInTitle) {
    // Append Item: Sign-In Sheet Uploaded? Yes / No
    var signInItem = form.addMultipleChoiceItem();
    signInItem.setTitle(signInTitle)
      .setChoices([
        signInItem.createChoice('Yes'),
        signInItem.createChoice('No')
      ]); 
  }
  
  // Append Item: Follow-up Email Sent After Event? Yes / No
  var followUpTitle = 'Follow-up Email Sent After Event?';
  if (items[count - 2].getTitle() !== followUpTitle) {
    var followUpItem = form.addMultipleChoiceItem();
    followUpItem.setTitle(followUpTitle)
      .setChoices([
        followUpItem.createChoice('Yes'),
        followUpItem.createChoice('No')
      ]); 
  }
  
  // Append Item: Additional Notes
  var addlNotesTitle = 'Additional Notes?';
  if (items[count - 1].getTitle() != addlNotesTitle) {
    var addlNotesItem = form.addParagraphTextItem();
    addlNotesItem.setTitle(addlNotesTitle); 
  }
  
  return true
}
