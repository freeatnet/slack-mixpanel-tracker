# slack-mixpanel-tracker
A Slack bot to send team activity to Mixpanel.

## What's in 
1. The bot joins all public channels on startup; monitors and joins any channels created.
2. Channel messages are tracked. A message event contains a reference to its author and the channel it was sent to. Currently, only plain and "/me" messages are reported.
3. Slack team members XXX Mixpanel "People" profile, including basic data, channels they are active in, and message count.

## Running the bot
1. Create a Bot or a Hubot integration (https://my-team.slack.com/services) in your Slack team and grab the token.
2. Create a token for a real user in the same team. A test token you can create at the bottom of https://api.slack.com/web should work.
3. Grab the token for the Mixpanel project you'll be pushing your data to.
4. Clone the repo. Run `npm install`.
5. Run `MIXPANEL_TOKEN="…" BOT_TOKEN="…" ADMIN_TOKEN="…" coffee index.coffee`.
6. Enjoy the flow of data into your Mixpanel project.

## TODO
- [ ] Import historical data
- [ ] Record user channel joins
- [ ] Report user mentions as an event
- [ ] Handle messages of misc subtypes
