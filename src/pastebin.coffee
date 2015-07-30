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
				# 20K
				if Buffer.byteLength(content, 'utf-8') >= 20 * 1024
					telegram.sendMessage msg.chat.id, 'Too long!'
				else
					[err] = yield store.put 'pastebin', "#{msg.chat.id}content#{msg.from.id}", content, ko.raw()
					if !err?
						telegram.sendMessage msg.chat.id, 'More? Come on! Send me "Finish" after you have done it!!'
					else
						server.releaseInput msg.chat.id, msg.from.id
						telegram.sendMessage msg.chat.id, 'Oops, something went wrong.'
			else
				content = yield store.get 'pastebin', "#{msg.chat.id}content#{msg.from.id}", ko.default()
				if content.trim() is ''
					telegram.sendMessage msg.chat.id, 'But I heared nothing!'
				else
					[err] = yield store.put 'pastebin', "#{msg.chat.id}step#{msg.from.id}", 2, ko.raw()
					telegram.sendMessage msg.chat.id, 'Which type is this text?', null,
						telegram.makeKeyboard telegram.verticalKeyboard(Object.keys(keyboard)), true
		else if step is 2
			content = yield store.get 'pastebin', "#{msg.chat.id}content#{msg.from.id}", ko.default()
			syntax = keyboard[msg.text]
			syntax = "text" if !syntax?
			[url] = yield paste msg.from.username, content, syntax, ko.raw()
			console.log url
			if !url? or url is ''
				telegram.sendMessage msg.chat.id, 'Sorry, but I failed...'
			else
				[err] = yield store.put 'pastebin', "#{msg.from.id}url", url, ko.raw()
				if !err? then telegram.sendMessage msg.chat.id,
					'Done, sir! Call /paste command somewhere and I will post it there!', null,
					telegram.makeHideKeyboard()
			yield store.put 'pastebin', "#{msg.chat.id}content#{msg.from.id}", '', ko.default()
			yield store.put 'pastebin', "#{msg.chat.id}step#{msg.from.id}", 0, ko.default()
			server.releaseInput msg.chat.id, msg.from.id

paste = (poster, str, syntax, callback) ->
	korubaku (ko) ->
		[err, res, body] = yield request.post 'http://paste.ubuntu.com/',
			form:
				poster: poster
				syntax: syntax
				content: str
		, ko.raw()

		callback res.headers.location unless err? or res.statusCode isnt 302

keyboard =
	"Plain Text": "text"
	"AppleScript": "applescript"
	"ActionScript": "as"
	"ActionScript 3": "as3"
	"Makefile": "make"
	"Bash": "bash"
	"Batchfile (Windows)": "bat"
	"C": "c"
	"C++": "cpp"
	"C#": "csharp"
	"Clojure": "clojure"
	"Cmake": "cmake"
	"CoffeeScript": "coffee-script"
	"Common Lisp": "common-lisp"
	"CSS": "css"
	"Erlang": "erlang"
	"Fortran": "fortran"
	"Golang": "go"
	"HTML": "html"
	"Java": "java"
	"JavaScript": "js"
	"LUA": "lua"
	"Matlab": "matlab"
	"Objective-C": "objective-c"
	"Perl": "perl"
	"PHP": "php"
	"Python": "python"
	"Python 3": "python3"
	"Ruby": "rb"
	"Scala": "scala"
	"Sass": "sass"
	"TeX": "tex"
	"Vala": "vala"
	"VB.net": "vb.net"
	"VimL": "vim"
	"XML": "xml"
