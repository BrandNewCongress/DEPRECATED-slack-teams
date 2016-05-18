# slack-teams

###### Scripts we will use to help BNC volunteers effectively use Slack to communicate with each other and track their progress organizing events.

Contains:
* [team_admin](https://github.com/BrandNewCongress/slack-teams/tree/master/team_admin) Listens for new Slack channels, creates Google spreadsheets / Google forms based on a template for each one, and displays them all in a tiny site via a Sinatra app.
* [slack_channel_google_sheets_syncer.rb](https://github.com/BrandNewCongress/slack-teams/blob/master/slack_channel_google_sheets_syncer/lib/slack_channel_google_sheets_syncer.rb)
  A script that runs on a loop, reading Slack channel names/ids from our team and syncing them to a Google Sheet.
* [form_channel_updater.gs](https://github.com/BrandNewCongress/slack-teams/blob/master/google_apps_scripts/form_channel_updater.gs)
  A script to pull data from a Google Sheet in order to populate a multiple choice question about which slack channel / city the respondent is from. It then ensures that when the survey is submitted, only one row per city is added to the Google sheet containing responses.
* [form_copy_google_apps_executor.gs](https://github.com/BrandNewCongress/slack-teams/blob/master/google_apps_scripts/form_copy_google_apps_executor.gs) This script is currently deployed under my own account as an API executable. It is able to be invoked via the [Google Apps Script REST Execution API](https://developers.google.com/apps-script/guides/rest/).

Will eventually include:
* A Slackbot which greets volunteers when they join the Slack team, and helps them get set up with all instructions.
* Other relevant glue scripts.
