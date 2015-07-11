exports.setup = (telegram, store) ->
	parser = require './parser'

	[
			cmd: 'hello'
			args: ''
			num: 0
			desc: 'Just hello'
			act: (msg) =>
				telegram.sendMessage msg.chat.id, 'Hello, world'
		,
			cmd: 'echo'
			args: '<something>'
			num: 1
			desc: 'echo <something>'
			act: (msg, args) =>
				telegram.sendMessage msg.chat.id, args[0]
		,
			cmd: 'remind'
			args: '<time> <message>'
			num: 2
			desc: 'Remind you of <message> after <time> (format: AdBhCmDs)'
			act: (msg, args) =>
				setTimeout =>
					telegram.sendMessage msg.chat.id, args[1]
				, args[0]
		,
			cmd: 'parsetime'
			args: '<time>'
			num: 1
			desc: 'Get milliseconds of AdBhCmDs'
			debug: yes
			act: (msg, args) =>
				telegram.sendMessage msg.chat.id, parser.time args[0]
	]
