exports.time = (time) ->
	t = 0
	str = ''
	for s in time
		switch s
			when 's'
				t += str * 1000
				str = ''
			when 'm'
				t += str * 60 * 1000
				str = ''
			when 'h'
				t += str * 60 * 60 * 1000
				str = ''
			when 'd'
				t += str * 24 * 60 * 60 * 1000
				str = ''
			else
				str += s
	t
