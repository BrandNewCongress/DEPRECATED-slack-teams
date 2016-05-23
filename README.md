# slack-teams

###### Scripts we will use to help BNC volunteers effectively use Slack to communicate with each other and track their progress organizing events.

Contains:
* [tour_slackbot](https://github.com/BrandNewCongress/slack-teams/blob/master/tour_slackbot) A slackbot which greets new users when they join the Tour Slack team, asks them which city they are volunteering in, and routes them to the correct private room. Includes Rake tasks to interact with the Events spreadsheet to automatically create Slack groups and create To-Do Forms for each city's Slack group.
* [form_copy_google_apps_executor.gs](https://github.com/BrandNewCongress/slack-teams/blob/master/google_apps_scripts/form_copy_google_apps_executor.gs) This script is currently deployed under my own account as an API executable. It is able to be invoked via the [Google Apps Script REST Execution API](https://developers.google.com/apps-script/guides/rest/).
