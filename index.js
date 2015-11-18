var logger = require('jethro');
var slackAPI = require('slackbotapi');
var Mixpanel = require('mixpanel');

var SUPPORTED_MESSAGE_SUBTYPES = [
  'me_message'
];

// Starting
var slack = new slackAPI({
  'token': 'xoxb-4226423209-9F0xYf0ZYHImJF1yeoNsX1NV',
  'logging': true,
  'autoReconnect': true
});

var mixpanel = Mixpanel.init('4bfd3c8b4f74486f866e9fd261dc3d12');


// Slack on EVENT message, send data.
slack.on('message', function (data) {
  // Ignore the messages that we can not deal with at the moment.
  if (data['hidden'] || !data['text'] || !data['user']) {
    logger("debug", "event:message", "Ignoring message because it does not contain text, a user, or is hidden.");
    return;
  }

  // Ignore message subtypes that we can not process right now.
  if (!!data['subtype'] && SUPPORTED_MESSAGE_SUBTYPES.indexOf(data['subtype']) == -1) {
    logger("debug", "event:message", "Ignoring message because subtype " + data['subtype'] + " is not supported.");
    return;
  }

  mixpanel.track("Channel Message Sent", {
    distinct_id: data['user'],
    "Channel": data['channel'],
    "Text": data['text']
  });

  mixpanel.people.increment(data['user'], "Message Count", 1);
  mixpanel.people.append(data['user'], "Channels", data['channel']);
});

slack.on('team_join', function (data) {
  var user = data['user'];

  mixpanel.people.set(data['user']['id'], {
    $email: user['profile']['email'],
    $name: user['profile']['real_name'] || user['name'],
    $first_name: user['profile']['first_name'],
    $last_name: user['profile']['last_name'],
    "Username": user['name']
  });
});

slack.on('user_change', function (data) {
  var user = data['user'];

  mixpanel.people.set(data['user']['id'], {
    $email: user['profile']['email'],
    $name: user['profile']['real_name'] || user['name'],
    $first_name: user['profile']['first_name'],
    $last_name: user['profile']['last_name'],
    "Username": user['name']
  });
});
