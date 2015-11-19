SlackMixpanelIntegration = require('./lib/slack-mixpanel-integration')

MIXPANEL_TOKEN = '<MIXPANEL TOKEN>'
BOT_TOKEN = '<BOT TOKEN>'
ADMIN_TOKEN = '<REAL USER WITH INVITE PRIVILEDGE TOKEN>'

integration = new SlackMixpanelIntegration MIXPANEL_TOKEN, BOT_TOKEN, ADMIN_TOKEN
