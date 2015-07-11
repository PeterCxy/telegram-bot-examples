exports.setup = (telegram, server, store) ->
	server.route 'hello', 0, (msg, args) =>
		telegram.sendMessage msg.chat.id, 'Hello, world'
