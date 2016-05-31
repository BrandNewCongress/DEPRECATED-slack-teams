# slack-teams

###### Scripts we will use to help BNC volunteers effectively use Slack to communicate with each other and track their progress organizing events.

#### Services

* A slackbot which greets new users when they join the Tour Slack team, asks them which city they are volunteering in, and routes them to the correct private room. Includes Rake tasks to interact with the Events spreadsheet to automatically create Slack channels and create To-Do Forms for each city's Slack channel.
* A Sinatra service which executes and coordinates several Google Apps Script executables and updates our Events Google Sheets and Slack channel.

#### Google Apps Scripts
These scripts are currently deployed under my own account as an API executable. They are invoked via the [Google Apps Script REST Execution API](https://developers.google.com/apps-script/guides/rest/).
* [form_copy_google_apps_executor.gs](https://github.com/BrandNewCongress/slack-teams/blob/master/scripts/form_copy_google_apps_executor.gs) Copies the given formID ands sets the new form with the given title, description, and response destination. Invoked by [form_copy_apps_script_executor.rb](https://github.com/BrandNewCongress/slack-teams/blob/master/lib/form_copy_apps_script_executor.rb).
* [get_prefilled_url_from_latest_responses.gs](https://github.com/BrandNewCongress/slack-teams/blob/master/scripts/get_prefilled_url_from_latest_responses.gs) Accepts a formId, gets the latest responses for that form and returns a prefilled url with them. Invoked by [form_prefilled_url_script_executor.rb](https://github.com/BrandNewCongress/slack-teams/blob/master/lib/form_prefilled_url_script_executor.rb).
* [on_submit.gs](https://github.com/BrandNewCongress/slack-teams/blob/master/scripts/on_submit.gs) Attach this script to the original form which is copied for each event. On submit, it sends an HTTP request to the running service at the `submitFormId` endpoint, including the formId as a parameter. That executes the getPrefilledUrlFromLatestResponses script, which the service then updates the Events sheet with the new prefilled URL for that event.
