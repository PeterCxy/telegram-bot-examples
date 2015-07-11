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
			act: (msg, sth) =>
				telegram.sendMessage msg.chat.id, sth
		,
			cmd: 'remind'
			args: '<time> <message>'
			num: 2
			desc: 'Remind you of <message> after <time> (format: AdBhCmDs)'
			act: (msg, time, sth) =>
				setTimeout =>
					telegram.sendMessage msg.chat.id, sth
				, time
		,
			cmd: 'parsetime'
			args: '<time>'
			num: 1
			desc: 'Get milliseconds of AdBhCmDs'
			debug: yes
			act: (msg, time) =>
				telegram.sendMessage msg.chat.id, parser.time time
	]
