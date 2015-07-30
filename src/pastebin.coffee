{korubaku} = require 'korubaku'
request = require 'request'

exports.handle = (msg, telegram, store, server) ->
	korubaku (ko) ->
		step = yield store.get 'pastebin', "#{msg.chat.id}step#{msg.from.id}", ko.default()
		if step is 1
			if msg.text.toLowerCase() isnt 'finish'
				content = yield store.get 'pastebin', "#{msg.chat.id}content#{msg.from.id}", ko.default()
				if content?
					content += "\n#{msg.text}"
				else
					content = msg.text
				[err] = yield store.put 'pastebin', "#{msg.chat.id}content#{msg.from.id}", content, ko.raw()
				if !err?
					telegram.sendMessage msg.chat.id, 'More? Come on! Send me "Finish" after you have done it!!'
				else
					server.releaseInput msg.chat.id, msg.from.id
					telegram.sendMessage msg.chat.id, 'Oops, something went wrong.'
			else
				[err] = yield store.put 'pastebin', "#{msg.chat.id}step#{msg.from.id}", 2, ko.raw()
				telegram.sendMessage msg.chat.id, 'Which type is this text?'
		else if step is 2
			content = yield store.get 'pastebin', "#{msg.chat.id}content#{msg.from.id}", ko.default()
			[url] = yield paste msg.from.username, content, ko.raw()
			console.log url
			if !url? or url is ''
				telegram.sendMessage msg.chat.id, 'Sorry, but I failed...'
			else
				[err] = yield store.put 'pastebin', "#{msg.from.id}url", url, ko.raw()
				if !err? then telegram.sendMessage msg.chat.id,
					'Done, sir! Call /paste command somewhere and I will post it there!'
			yield store.put 'pastebin', "#{msg.chat.id}content#{msg.from.id}", '', ko.default()
			yield store.put 'pastebin', "#{msg.chat.id}step#{msg.from.id}", 0, ko.default()
			server.releaseInput msg.chat.id, msg.from.id

paste = (poster, str, callback) ->
	korubaku (ko) ->
		[err, res, body] = yield request.post 'http://paste.ubuntu.com/',
			form:
				poster: poster
				syntax: "text"
				content: str
		, ko.raw()

		callback res.headers.location unless err? or res.statusCode isnt 302
