exports.name = 'examples'
exports.desc = 'Some interesting example commands'

exports.setup = (telegram, store, server) ->
	parser = require './parser'
	pkg = require '../package.json'

	[
			cmd: 'hello'
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
			num: 2
			desc: 'Remind you of <message> after <time> (format: AdBhCmDs)'
			act: (msg, time, message) =>
				setTimeout =>
					telegram.sendMessage msg.chat.id, message
				, parser.time time
		,
			cmd: 'remindex'
			num: 0
			desc: 'A better user interface for the remind command'
			act: (msg) =>
				server.grabInput msg.chat.id, msg.from.id, pkg.name, 'remindex'
				store.put 'remind', "#{msg.chat.id}step#{msg.from.id}", 1, (err) =>
					if err
						server.releaseInput msg.chat.id
					else
						telegram.sendMessage msg.chat.id, 'Well, how long later do you want me to remind you?'
		,
			cmd: 'parsetime'
			num: 1
			desc: 'Get milliseconds of AdBhCmDs'
			debug: yes
			act: (msg, time) =>
				telegram.sendMessage msg.chat.id, parser.time time
	]

exports.input = (cmd, msg, telegram, store, server) ->
	switch cmd
		when 'remindex' then remindEx msg, telegram, store, server
		else server.releaseInput msg.chat.id

remindEx = (msg, telegram, store, server) ->
	console.log "RemindEx!"
	store.get 'remind', "#{msg.chat.id}step#{msg.from.id}", (err, step) =>
		if err?
			server.releaseInput msg.chat.id, msg.from.id
		else
			console.log "Current step is #{step}"
			if step is 1
				parser = require './parser'
				time = parser.time msg.text
				if time <= 0 or time >= 0xFFFFFFFF
					# Out of range
					telegram.sendMessage msg.chat.id, '''
						Sorry, but I can\'t work with that number. \n
						Please send me a time with units (s, m, d), and within 23d.
					'''
				else
					store.put 'remind', "#{msg.chat.id}step#{msg.from.id}", 2, (err) =>
						if err?
							server.releaseInput msg.chat.id, msg.from.id
							telegram.sendMessage msg.chat.id, 'Oops, something went wrong'
						else
							store.put 'remind', "#{msg.chat.id}time#{msg.from.id}", time, (err) =>
								telegram.sendMessage msg.chat.id, 'Okay, now send me what you want me to remind you of'
			else if step is 2
				store.get 'remind', "#{msg.chat.id}time#{msg.from.id}", (err, time) =>
					if err?
						server.releaseInput msg.chat.id, msg.from.id
						telegram.sendMessage msg.chat.id, 'Oops, something went wrong'
					else
						telegram.sendMessage msg.chat.id, 'Yes, sir!'
						setTimeout =>
							telegram.sendMessage msg.chat.id, msg.text
						, time
						server.releaseInput msg.chat.id, msg.from.id
						store.put 'remind', "#{msg.chat.id}step#{msg.from.id}", 0
						store.put 'remind', "#{msg.chat.id}time#{msg.from.id}", 0
