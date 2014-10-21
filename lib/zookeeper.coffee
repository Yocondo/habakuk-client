{ EventEmitter } = require 'events'
{ Promise } = require 'es6-promise'

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
			@getRegisterMessage()
			.then (registerMessage) =>
				Zookeeper.logger.info '[zookeeper] connected, registering:', JSON.stringify registerMessage
				@socket.emit 'register', registerMessage
				@handler.on 'heartbeat', (message) =>
					Zookeeper.logger.debug? '[zookeeper] heartbeat:', message
					@socket.emit 'heartbeat', message
			.catch (err) =>
				Zookeeper.logger.error '[zookeeper] error registering:', err.stack || err

	getRegisterMessage: ->
		getVersion = =>
			console.log 'options:', @options
			return Promise.resolve @options.version if @options.version
			Zookeeper.logger.debug '[zookeeper] no version specified, using git commit id instead'
			(require 'git-info')().then (git) -> git.shortCommitId

		getVersion()
		.then (version) =>
			component: @options.component
			host: @options.host || require('os').hostname().toLowerCase()
			version: version

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
