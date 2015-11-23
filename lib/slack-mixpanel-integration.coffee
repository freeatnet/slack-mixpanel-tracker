_ = require('underscore')
logger = require('jethro')
Slack = require('slack-api').promisify()
SlackRTM = require('slackbotapi')
Mixpanel = require('mixpanel')

module.exports = class
  SLACK_API_ERRORS: [ Slack.errors.SlackError, Slack.errors.SlackServiceError ]
  SUPPORTED_MESSAGE_SUBTYPES: [ 'me_message' ]

  botToken: null
  adminToken: null

  botUserInfo: null
  channelMapping: {}
  peopleMapping: {}

  mp:
    recordChannelMessage: (channel, message) ->
      mpEventData =
        distinct_id: message['user']
        'Channel': channel['name']
        'Text': message['text']

      @mixpanel.track 'Channel Message Sent', mpEventData
      @mixpanel.people.increment message['user'], 'Message Count', 1
      @mixpanel.people.append message['user'], 'Channels', channel['name']

    createUserProfile: (user) ->
      @mixpanel.people.set user['id'], @userTypeToMixpanelUser(user)

    updateUserProfile: (user) ->
      @mixpanel.people.set user['id'], @userTypeToMixpanelUser(user)

    userTypeToMixpanelUser: (user) ->
      return {
        $email: user['profile']['email']
        $name: user['profile']['first_name'] or user['name']
        $first_name: user['profile']['first_name']
        $last_name: user['profile']['last_name']
        'Username': user['name']
        'Real Name': user['profile']['real_name']
        'About': user['profile']['title']
      }

  constructor: (mixpanelToken, @botToken, @adminToken) ->
    @mp.mixpanel = Mixpanel.init(mixpanelToken)
    @fetchUsersList()
    @configureBotPresence()
    return @

  fetchUsersList: () ->
    logger 'debug', 'startup', "Fetching users list"

    storeUserList = (data) =>
      logger 'debug', 'startup', "Storing users list"
      @peopleMapping = {}

      data['members'].forEach (member) =>
        @peopleMapping[member['id']] = member
      logger 'info', 'startup', "Stored #{_.keys(@peopleMapping).length} users"
      return

    Slack.users.list(token: @botToken).then(storeUserList).catch @SLACK_API_ERRORS..., (error) ->
      logger 'warning', 'startup', "Could not list users in the team: #{error}"
      return

    return

  configureBotPresence: ->
    logger 'debug', 'startup', "Fetching bot user info"
    Slack.auth.test(token: @botToken).then((data) =>
      logger 'debug', 'startup', "Received bot user info"
      @botUserInfo = data
      @joinMissingChannels()
      return
    ).catch @SLACK_API_ERRORS..., (error) ->
      logger 'error', 'startup', "Could not retrieve bot's user info #{error}"
      return

  joinMissingChannels: ->
    logger 'debug', 'startup', "Fetching channel list"

    Slack.channel.list(exclude_archived: 1, token: @botToken).then((data) =>
      logger 'debug', 'startup', "Received channel list"
      data.channels.forEach (channel) =>
        @channelMapping[channel['id']] = channel
        @joinChannel(channel['id']) if not channel['is_member']
        return

      # Continue configuration workflow
      @configureRtm() # Is there a better way to do this?
      return
    ).catch @SLACK_API_ERRORS..., (error) ->
      logger 'warning', 'startup', "Could not list bot's channels: #{error}"
      return
    return

  joinChannel: (channelId) ->
    logger 'debug', 'startup', "Attempting to join #{channelId}"

    selfInviteParams =
      channel: channelId
      user: @botUserInfo['user_id']
      token: @adminToken

    Slack.channel.invite(selfInviteParams).catch @SLACK_API_ERRORS..., (error) ->
      logger 'warning', 'startup', "Error attempting to join #{channelId}: #{error}"

  configureRtm: ->
    @rtm = new SlackRTM 'token': @botToken, 'logging': true, 'autoReconnect': true

    @rtm.on 'channel_created', @onChannelCreated
    @rtm.on 'message', @onMessage
    @rtm.on 'team_join', @onTeamJoin
    @rtm.on 'user_change', @onUserChange
    return

  onMessage: (data) =>
    # Ignore the messages that we can not deal with at the moment.
    if data['hidden'] or !data['text'] or !data['user']
      logger 'debug', 'event:message', 'Ignoring message because it does not contain text, a user, or is hidden.'
      return

    # Ignore message subtypes that we can not process right now.
    if data['subtype']? and @SUPPORTED_MESSAGE_SUBTYPES.indexOf(data['subtype']) == -1
      logger 'debug', 'event:message', "Ignoring message because subtype #{data['subtype']} is not supported."
      return

    @mp.recordChannelMessage(@channelMapping[data['channel']], data)
    return

  onChannelCreated: (data) =>
    # TODO: channel_created should store new channel in data mapping
    @joinChannel(data['id'])
    return

  onTeamJoin: (data) =>
    user = data['user']
    @peopleMapping[user['id']] = user
    @mp.createUserProfile(user)
    return

  onUserChange: (data) =>
    user = data['user']
    @peopleMapping[user['id']] = user
    @mp.updateUserProfile(user)
    return


