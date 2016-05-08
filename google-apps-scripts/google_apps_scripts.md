# Google Apps Scripts

These are scripts designed to run in the Script Editor associated with a particular Google form. They are written in a Javascript API called  [AppsScript](https://developers.google.com/apps-script/).

  1. [form_channel_updater.gs](https://github.com/BrandNewCongress/slack-teams/blob/master/google-apps-scripts/form_channel_updater.gs)
  This script is designed to pull data from a Google Sheet in order to populate a multiple choice question about which slack channel / city the respondent is from. It then ensures that when the survey is submitted, only one row per city is added to the Google sheet containing responses.
