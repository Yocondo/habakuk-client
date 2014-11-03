{ EventEmitter } = require 'events'
Zookeeper = require './zookeeper'

class Handler extends EventEmitter
	constructor: ->
		@heartbeatSequence = 0

	sendHeartbeat = ->
		@emit 'heartbeat', "Heartbeat ##{@heartbeatSequence}"
		@heartbeatSequence += 1

	start: (next) ->
		unless @heartbeatInterval
			@heartbeatInterval = setInterval (sendHeartbeat.bind @), 2000
		next null

	stop: (next) ->
		if @heartbeatInterval
			clearInterval @heartbeatInterval
			delete @heartbeatInterval
		next null

handler = new Handler

options =
	url: 'http://localhost:3000'
	component: 'abigail'
	host: 'kirk'

zookeeper = new Zookeeper handler, options
zookeeper.on 'status', (event) -> console.log 'status:', event
