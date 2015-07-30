{korubaku} = require 'korubaku'

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
				korubaku (ko) =>
					server.grabInput msg.chat.id, msg.from.id, pkg.name, 'remindex'
					[err] = yield store.put 'remind', "#{msg.chat.id}step#{msg.from.id}", 1, ko.raw()
					if err
						server.releaseInput msg.chat.id
					else
						telegram.sendMessage msg.chat.id,
							'Well, how long later do you want me to remind you?',
							msg.message_id
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
		else server.releaseInput msg.chat.id, msg.from.id

remindEx = (msg, telegram, store, server) ->
	korubaku (ko) =>
		console.log "RemindEx!"
		step = yield store.get 'remind', "#{msg.chat.id}step#{msg.from.id}", ko.default()
		console.log "Current step is #{step}"
		if step is 1
			parser = require './parser'
			time = parser.time msg.text
			if time <= 0 or time >= 0xFFFFFFFF
				# Out of range
				telegram.sendMessage msg.chat.id, '''
					Sorry, but I can\'t work with that number. \n
					Please send me a time with units (s, m, d), and within 23d.
				''', msg.message_id
			else
				[err] = yield store.put 'remind', "#{msg.chat.id}step#{msg.from.id}", 2, ko.raw()
				if err?
					server.releaseInput msg.chat.id, msg.from.id
					telegram.sendMessage msg.chat.id, 'Oops, something went wrong'
				else
					yield store.put 'remind', "#{msg.chat.id}time#{msg.from.id}", time, ko.raw()
					telegram.sendMessage msg.chat.id,
						'Okay, now send me what you want me to remind you of',
						msg.message_id
		else if step is 2
			time = yield store.get 'remind', "#{msg.chat.id}time#{msg.from.id}", ko.default()
			telegram.sendMessage msg.chat.id, 'Yes, sir!', msg.message_id
			setTimeout =>
				telegram.sendMessage msg.chat.id, "@#{msg.from.username} #{msg.text}"
			, time
			server.releaseInput msg.chat.id, msg.from.id
			store.put 'remind', "#{msg.chat.id}step#{msg.from.id}", 0
			store.put 'remind', "#{msg.chat.id}time#{msg.from.id}", 0
