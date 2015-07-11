exports.help = [
		cmd: 'hello'
		args: ''
		des: 'Just hello'
	,
		cmd: 'echo'
		args: '<something>'
		des: 'echo <something>'
	,
		cmd: 'remind'
		args: '<time> <message>'
		des: 'Remind you of <message> after <time> (format: AdBhCmDs)'
	,
		cmd: 'parsetime'
		args: '<time>'
		des: 'Get milliseconds of AdBhCmDs'
		debug: yes
]

parser = require './parser'

exports.setup = (telegram, server, store) ->
	server.route 'hello', 0, (msg, args) =>
		telegram.sendMessage msg.chat.id, 'Hello, world'
	
	server.route 'echo', 1, (msg, args) =>
		telegram.sendMessage msg.chat.id, args[0]
	
	server.route 'remind', 2, (msg, args) =>
		setTimeout =>
			telegram.sendMessage msg.chat.id, args[1]
		, parser.time args[0]

	server.route 'parsetime', 1, (msg, args) =>
		telegram.sendMessage msg.chat.id, parser.time args[0]
