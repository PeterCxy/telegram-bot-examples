{korubaku} = require 'korubaku'
printf = require 'printf'

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
			cmd: 'choose'
			num: -1
			args: '<choices> <format>'
			desc: """
				Choose among <choices> and format the <format> string using the choice.
				<choices> should be like: choice1-1,choice1-2;choice2-1,choice2-2
				The result will be filled into placeholders in <format> in the original order.
				supported placeholders are the same as in the printf function in C
			"""
			act: (msg, args) =>
				results = []
				for category in args[0].split ';'
					console.log "working with #{category}"
					comprehension = no
					if category.startsWith('[') and category.endsWith(']') and category.indexOf('-') > 0
						category = category[1...-1]
						[start, ..., end] = category.split '-'
						choices = []
						comprehension = yes
					else
						choices = category.split ','
					console.log "choices = #{choices}"
					result = null
					if choices.length > 0
						index = Math.floor Math.random() * choices.length
						console.log "index = #{index}"
						result = choices[index]
						console.log "result = #{result}"
					else if comprehension
						result = Number start
						result += Math.random() * (end - start)
						console.log "#{start}-#{end} -> #{result}"
					results.push result
				results.unshift args[1..].join ' '
				console.log "results = #{results}"
				str = printf.apply this, results
				telegram.sendMessage msg.chat.id, str, msg.message_id
		,
			cmd: 'id'
			num: 0
			debug: yes
			desc: 'Get ID of this chat.'
			act: (msg) ->
				telegram.sendMessage msg.chat.id, msg.chat.id
		,
			cmd: 'copy'
			num: 0
			desc: 'Copy some long string to Ubuntu Pastebin (http://paste.ubuntu.com) (Not available in groups)'
			act: (msg) =>
				if !msg.chat.title? then korubaku (ko) =>
					server.grabInput msg.chat.id, msg.from.id, pkg.name, 'pastebin'
					[err] = yield store.put 'pastebin', "#{msg.chat.id}step#{msg.from.id}", 1, ko.raw()
					if err
						server.releaseInput msg.chat.id, msg.from.id
					else
						telegram.sendMessage msg.chat.id,
							'Now, you can send me some text you want to copy to Ubuntu pastebin.'
		,
			cmd: 'paste'
			num: 0
			desc: 'Paste the url to the last string you copied to Pastebin here.'
			act: (msg) =>
				korubaku (ko) =>
					[err, url] = yield store.get 'pastebin', "#{msg.from.id}url", ko.raw()
					console.log url
					if !url? or err?
						telegram.sendMessage msg.chat.id, ':('
					else
						telegram.sendMessage msg.chat.id,
							"@#{msg.from.username} shared: #{url}"
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
		when 'pastebin' then (require './pastebin').handle msg, telegram, store, server
		else server.releaseInput msg.chat.id, msg.from.id

exports.cancel = (msg, telegram, store, server) ->
	console.log 'examples: cancelling operation'
	
	korubaku (ko) =>
		# Remind command
		yield store.put 'remind', "#{msg.chat.id}step#{msg.from.id}", 0, ko.default()
		yield store.put 'remind', "#{msg.chat.id}time#{msg.from.id}", 0, ko.default()
	
		# Pastebin
		yield store.put 'pastebin', "#{msg.chat.id}content#{msg.from.id}", '', ko.default()

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
