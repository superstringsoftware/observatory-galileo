# ## Observatory
# Observatory-galileo is a nodejs / client logging framework with flexible architecture.
# It was developed as a basis for [Observatory Logging & Monitoring Suite](http://observatoryjs.com)
# but can be used standalone independent of [Meteor](http://meteor.com).
# Although you should *really* try Meteor. You'll love it, we promise :)
#
# Below is the full API documentation, useful if you want to extend the framework. If you just want to
# jump to usage, start reading with [Generic Emitter](#abcde).

_ = require 'underscore'

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
  # [Logger](http://example.net/) has to respond to `addMessage(msg)` call.
  emitMessage: (message)->
    l.addMessage message for l in @_loggers
    true

# ### Logger
# Logger listens to messages and processes them, one by one or in batches.
# It also checks if the Emitters generate messages in the correct format described below.
class Observatory.Logger
  messageBuffer = []

  # `@name` is a module name
  # `func` is a function to process and log every object in the buffer???
  constructor: (@name, func)->
    @messageBuffer = []
    @func = func

  # `messageAcceptable` verifies that Emitters give messages in the format that
  # can be recognized by this logger. At the very minimum, we are checking for
  # timestamp, severity, client / server and either text or html formatted message to log.
  messageAcceptable: (m)->
    return (m.timestamp? and m.severity? and m.isServer? and (m.textMessage? or m.htmlMessage?) )

  # `addMessage` is the listening method that takes messages from Emitters
  addMessage: (message)->
    throw new Error "Unacceptable message format in logger: #{@name}" if not @messageAcceptable message
    @messageBuffer.push message

  # receives a function that formats & logs each object in the buffer in whatever way we need
  # and clears the buffer in the end
  # ???
  processBuffer: (func)->
    return unless @messageBuffer.length > 0
    f = if func? then func else @func
    f obj for obj in @messageBuffer
    @messageBuffer = []

# <a name="abcde"/>
# ### GenericEmitter
# Implements typical logging functionality to be used inside an app - log messages with various severity levels.

class Observatory.GenericEmitter extends Observatory.MessageEmitter

  # Creating a named emitter with maximum severity of the messages to emit equal to `maxSeverity`
  # and `formatter` as a formatting function. This provides flexibility on how the message to be passed on to
  # loggers is formed.
  constructor: (name, maxSeverity, formatter)->
    @maxSeverity = maxSeverity
    if formatter? and typeof formatter is 'function'
      @formatter = formatter
    else
      @formatter = (options)->
        msg =
          timestamp: new Date
          severity: options.severity
          textMessage: options.message
          module: if @name then @name else options.module # should the priority be reversed?
          object: options.obj
          isServer: Observatory.isServer()

    super name
    # some dynamic js magic - defining different severity method aliases programmatically to be DRY:
    for m,i in ['fatal','error','warn','info','verbose','debug','insaneVerbose']
      @[m] = (message, module, obj)-> @_emitWithSeverity severity: i, message: message, obj: obj, module: module

  # Low-level emitting method that formats message and emits it
  #
  # * `severity` - level with wich to emit a message. Won't be emitted if higher than `@maxSeverity`
  # * `message` - text message to include into the full log message to be passed to loggers
  # * `module` - optional module name. If the emitter is named, its' name will be used instead in any case.
  # * `obj` - optional arbitrary json-able object to be included into full log message, e.g. error object in the call to `error`
  _emitWithSeverity: (options)->
    return if not options.severity? or options.severity > @maxSeverity
    @emitMessage @formatter(options)

console.log Observatory
(exports ? this).Observatory = Observatory