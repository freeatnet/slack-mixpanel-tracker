SlackMixpanelIntegration = require('./lib/slack-mixpanel-integration')

MIXPANEL_TOKEN = process.env.MIXPANEL_TOKEN
BOT_TOKEN = process.env.BOT_TOKEN
ADMIN_TOKEN = process.env.ADMIN_TOKEN

integration = new SlackMixpanelIntegration MIXPANEL_TOKEN, BOT_TOKEN, ADMIN_TOKEN
