# ## Observatory
# Observatory-galileo is a nodejs / client logging framework with flexible architecture.
# It was developed as a basis for [Observatory Logging & Monitoring Suite](http://observatoryjs.com)
# but can be used standalone independent of [Meteor](http://meteor.com).
# Although you should *really* try Meteor. You'll love it, we promise :)
#
# Below is the full API documentation, useful if you want to extend the framework. If you just want to
# jump to usage, start reading with [Generic Emitter](#abcde).

_ = require 'underscore' if require?

# ### Constants and common definitions
Observatory =

  # Log level (severity) definitions
  LOGLEVEL:
    SILENT: -1
    FATAL: 0
    ERROR: 1
    WARNING: 2
    INFO: 3
    VERBOSE: 4
    DEBUG: 5
    MAX: 6
    NAMES: ["FATAL", "ERROR", "WARNING", "INFO", "VERBOSE", "DEBUG", "MAX"]

  # Check if we are run on server or client.
  # NOTE! To be overriden for Meteor based implementations!
  isServer: -> not (typeof window isnt "undefined" and window.document)

  # Maximum system-wide severity - info by default
  maxSeverity: 3

  # formatters - functions that take arbitrary json and format it into a message that
  # loggers can accept
  formatters:
    basicFormatter: (options)->
        timestamp: new Date
        severity: options.severity
        textMessage: options.message
        # note that it's a function that gets passed around so `this` will be what we need
        module: options.module # should the priority be reversed?
        object: options.obj
        isServer: Observatory.isServer()


  # array of system-wide subscribing loggers
  _loggers: []
  # get all currently listening system-wide loggers
  getLoggers: -> @_loggers
  # add new logger to listen to messages
  subscribeLogger: (logger)->
    @_loggers.push logger
  # remove logger from the listeners
  unsubscribeLogger: (logger)->
    @_loggers = _.without @_loggers, logger
  # reset - resets Observatory to the default state
  reset: ->
    @_loggers = []
    @maxSeverity = 3


# ### MessageEmitter
# This class is the base for anything that wants to produce messages to be logged.
class Observatory.MessageEmitter
  _loggers = [] # array of subscribing loggers

  _getLoggers: -> @_loggers
  constructor: (@name)-> @_loggers = []

  # add new logger to listen to messages
  subscribeLogger: (logger)->
    @_loggers.push logger

  # remove logger from the listeners
  unsubscribeLogger: (logger)->
    @_loggers = _.without @_loggers, logger

  # Translates message to be logged to all subscribed loggers.
  # `logger` has to respond to `addMessage(msg)` call.
  # Normally, only system-wide loggers are used, subscription for specific emitters is to provide
  # finer-grained control.
  emitMessage: (message)->
    l.addMessage message for l in Observatory.getLoggers()
    l.addMessage message for l in @_loggers if @_loggers.length > 0
    message

# ### Logger
# Logger listens to messages and processes them, one by one or in batches.
# It also checks if the Emitters generate messages in the correct format described below.
class Observatory.Logger
  messageBuffer = []

  # * `@name` is a module name
  # * `@useBuffer` - whether to log the messages immediately or buffer them first
  # * `@interval` - if using buffer, how often we should process it.
  # TODO: figure out how to use different interval-setting functions in pure js and Meteor.
  # TODO: actual interval setup in the constructor
  constructor: (@name, @useBuffer = false, @interval = 3000)->
    @messageBuffer = []

  # `messageAcceptable` verifies that Emitters give messages in the format that
  # can be recognized by this logger. At the very minimum, we are checking for
  # timestamp, severity, client / server and either text or html formatted message to log.
  messageAcceptable: (m)->
    return (m? and m.timestamp? and m.severity? and m.isServer? and (m.textMessage? or m.htmlMessage?) )

  # `addMessage` is the listening method that takes messages from Emitters
  # TODO: do we really need to throw an error??? add some kind of 'strict mode'?
  addMessage: (message)->
    throw new Error "Unacceptable message format in logger: #{@name}" if not @messageAcceptable message
    if @useBuffer then @messageBuffer.push message else @log message

  # `log` - 'virtual' function that does actual output of the message. Needs to be overriden by extending
  # classes with e.g. logging to console or inserting into Meteor Collection. Does nothing here.
  log: (message)->
    throw new Error "log() function needs to be overriden to perform actual output!"

  # processing the buffer
  processBuffer: ->
    return unless @messageBuffer.length > 0
    @log obj for obj in @messageBuffer
    @messageBuffer = []

# <a name="abcde"/>
# ### GenericEmitter
# Implements typical logging functionality to be used inside an app - log messages with various severity levels.

class Observatory.GenericEmitter extends Observatory.MessageEmitter

  # Creating a named emitter with maximum severity of the messages to emit equal to `maxSeverity`
  # and `formatter` as a formatting function. This provides flexibility on how the message to be passed on to
  # loggers is formed. E.g., here it's given a basic format, when we'll use Meteor we'll provide a more
  # advanced formatter that will set userId, IP address etc.
  constructor: (name, maxSeverity, formatter)->
    @maxSeverity = maxSeverity
    if formatter? and typeof formatter is 'function'
      @formatter = formatter
    else
      @formatter = Observatory.formatters.basicFormatter

    super name
    # some dynamic js magic - defining different severity method aliases programmatically to be DRY.
    # TODO: need to keep in mind bind() doesn't work in IE8 and below, but there's a
    # [script to fix this](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Function/bind#Compatibility)
    for m,i in ['fatal','error','warn','info','verbose','debug','insaneVerbose']
      @[m] = @_emitWithSeverity.bind this, i


  # Low-level emitting method that formats message and emits it
  #
  # * `severity` - level with wich to emit a message. Won't be emitted if higher than `@maxSeverity`
  # * `message` - text message to include into the full log message to be passed to loggers
  # * `module` - optional module name. If the emitter is named, its' name will be used instead in any case.
  # * `obj` - optional arbitrary json-able object to be included into full log message, e.g. error object in the call to `error`
  _emitWithSeverity: (severity, message, obj, module)->
    return false if not severity? or severity > @maxSeverity
    if typeof message is 'object'
      module = obj
      obj = message
      message = JSON.stringify obj
    if typeof obj is 'string'
      module = obj
      obj = null

    options = severity: severity, message: message, obj: obj, module: module ? @name # explicit module overrides name
    @emitMessage @formatter(options)



(exports ? this).Observatory = Observatory