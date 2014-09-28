{ EventEmitter } = require 'events'

class Zookeeper extends EventEmitter
	@logger: console

	constructor: (@handler, @options) ->
		@status =
			status: 'booting'
			since: new Date

		url = @options.url
		Zookeeper.logger.info "[zookeeper] connecting to #{url}"
		@socket = require('socket.io-client').connect url

		@socket.on 'disconnect', (reason) =>
			Zookeeper.logger.warn '[zookeeper] disconnected: %s', reason
			@stop()

		@socket.on 'start', => @start()
		@socket.on 'stop', => @stop()

		@socket.on 'connect', =>
			Zookeeper.logger.info '[zookeeper] connected, registering...'
			@socket.emit 'register',
				clientId: @options.clientId || "#{@options.clientType}-#{require('os').hostname().toLowerCase()}"
				clientType: @options.clientType

		@handler.on 'heartbeat', (message) =>
			Zookeeper.logger.info 'heartbeat:', message
			@socket.emit 'heartbeat', message

	setStatus: (newStatus) ->
		if newStatus isnt @status.status
			oldStatus = @status.status
			@status.status = newStatus
			@status.since = new Date
			@emit 'status', from: oldStatus, to: newStatus

	stop: ->
		Zookeeper.logger.info '[zookeeper] stopping...'
		@setStatus 'stopping'
		@handler.stop (err) =>
			Zookeeper.logger.warn '[zookeeper] error stopping:', err.stack || err if err
			Zookeeper.logger.info '[zookeeper] stopped.'
			@setStatus 'stopped'

	start: ->
		Zookeeper.logger.info '[zookeeper] starting...'
		@setStatus 'starting'
		@handler.start (err) =>
			if err
				Zookeeper.logger.warn '[zookeeper] error starting:', err.stack || err
				@setStatus 'failed'
			else
				Zookeeper.logger.info '[zookeeper] started.'
				@setStatus 'running'

module.exports = Zookeeper
