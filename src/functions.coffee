exports.help = [
		cmd: 'hello'
		args: ''
		des: 'Just hello'
	,
		cmd: 'echo'
		args: '<something>'
		des: 'echo <something>'
]

exports.setup = (telegram, server, store) ->
	server.route 'hello', 0, (msg, args) =>
		telegram.sendMessage msg.chat.id, 'Hello, world'
	
	server.route 'echo', 1, (msg, args) =>
		telegram.sendMessage msg.chat.id, args[0]
