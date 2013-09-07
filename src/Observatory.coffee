# ## Observatory
# Observatory-galileo is a nodejs / client logging framework with flexible architecture.
# It was developed as a basis for [Observatory Logging & Monitoring Suite](http://observatoryjs.com)
# but can be used standalone independent of [Meteor](http://meteor.com).
# Although you should *really* try Meteor. You'll love it, we promise :)
#
# Below is the full API documentation, useful if you want to extend the framework. If you just want to
# jump to usage, start reading with [Generic Emitter](#abcde).
#
# ### Basic framework architecture notes
# * `MessageEmitters` emit messages - either from explicit calls to `logger.debug()` etc or by in turn listening or
# monitoring some other provider: e.g., http connect module, external log service etc. Emitters use formatters
# (`Observatory.formatters`) -->
# * `Formatters` form or tranform messages into predefined json format that is acceptably by -->
# * `Loggers` receive formatted messages from emitters and either buffer them or process immediately,
# by applying further output formatting - e.g., adding ANSI colors or html tags - and output them into
# different out devices - console, mongo collection etc.

###

  # Commented out for Meteor usage

require = if Npm? then Npm.require else require
_ = require 'underscore'
###

# ### Constants and common definitions
Observatory = Observatory ? {}

_.extend Observatory,
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

  settings:
    maxSeverity: 3
    printToConsole: true

  # Initializing the system - creating loggers, subscribing etc
  # Currently creates 1 ConsoleLogger and subscribes it system-wide.
  # Also initializes default logger (Generic Emitter).
  # TODO: add tests and settings format
  initialize: (settings)-> f.call this, settings for f in @_initFunctions
  registerInitFunction: (f)-> @_initFunctions.push f
  # array of initialization functions
  _initFunctions: [
    (s)->
      @_loggers = []
      if s?
        @settings.maxSeverity = if s.logLevel? then @LOGLEVEL[s.logLevel] else 3
        @settings.printToConsole = s.printToConsole ? true
      @_consoleLogger = new Observatory.ConsoleLogger 'default'
      @subscribeLogger @_consoleLogger
      @_defaultEmitter = new Observatory.Toolbox 'default'
  ]
  
  # Returns default logger to use in the app via warn(), debug() etc calls
  getDefaultLogger: -> @_defaultEmitter
  getToolbox: -> @_defaultEmitter

  # Check if we are run on server or client.
  # NOTE! To be overriden for Meteor based implementations!
  isServer: -> not (typeof window isnt "undefined" and window.document)

  # Formatters - functions that take arbitrary json and format it into a message that
  # loggers can accept. Formatters can be chained - will be useful when implementing Meteor
  # related stuff.
  formatters:
    basicFormatter: (options)->
        timestamp: new Date
        severity: options.severity
        textMessage: options.message
        # note that it's a function that gets passed around so `this` will be what we need
        module: options.module # should the priority be reversed?
        object: options.obj
        isServer: Observatory.isServer()

  # View formatters take a message accepted by loggers and further format it for nice output,
  # e.g., adding ANSI colors or html markup.
  viewFormatters:
    _convertDate: (timestamp)->
      timestamp.getUTCDate() + '/' + (timestamp.getUTCMonth()+1) + '/'+timestamp.getUTCFullYear()
    _convertTime: (timestamp, ms=true)->
      ts = timestamp.getUTCHours()+ ':' + timestamp.getUTCMinutes() + ':' + timestamp.getUTCSeconds()
      ts += '.' + timestamp.getUTCMilliseconds() if ms
      ts
    _ps: (s)-> '['+s+']'

    basicConsole: (o)->
      t = Observatory.viewFormatters
      ts = t._ps(t._convertDate(o.timestamp)) + t._ps(t._convertTime(o.timestamp))
      full_message = ts + if o.isServer then "[SERVER]" else "[CLIENT]"
      full_message+= if o.module then t._ps o.module else "[]"
      full_message+= t._ps(Observatory.LOGLEVEL.NAMES[o.severity]) #TODO: RANGE CHECK!!!
      full_message+= " #{o.textMessage}"
      full_message+= " | #{JSON.stringify(o.object)}" if o.object?
      full_message


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


# ### MessageEmitter
# This class is the base for anything that wants to produce messages to be logged.
class Observatory.MessageEmitter
  _loggers = [] # array of subscribing loggers

  _getLoggers: -> @_loggers
  constructor: (@name, @formatter)->
    @_loggers = []
    @isOn = true
    @isOff = false

  # only emit messages if we are on
  turnOn: -> @isOn = true; @isOff = false
  turnOff: -> @isOn = false; @isOff = true

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
  emitMessage: (message, buffer = false)->
    return unless @isOn
    l.addMessage message, buffer for l in Observatory.getLoggers()
    l.addMessage message, buffer for l in @_loggers if @_loggers.length > 0
    message

  emitFormattedMessage: (message, buffer = false)->
    @emitMessage @formatter message, buffer if @isOn and @formatter? and (typeof @formatter is 'function')
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
  # TODO: tests for arguments shifting!!!
  constructor: (@name, @formatter = Observatory.viewFormatters.basicConsole, @useBuffer = false, @interval = 3000)->
    if typeof formatter is 'boolean'
      @interval = @useBuffer
      @useBuffer = @formatter
      @formatter = Observatory.viewFormatters.basicConsole
    @messageBuffer = []
    #super

  # `messageAcceptable` verifies that Emitters give messages in the format that
  # can be recognized by this logger. At the very minimum, we are checking for
  # timestamp, severity, client / server and either text or html formatted message to log.
  messageAcceptable: (m)->
    return (m? and m.timestamp? and m.severity? and m.isServer? and (m.textMessage? or m.htmlMessage?) )

  # `addMessage` is the listening method that takes messages from Emitters
  # TODO: do we really need to throw an error??? add some kind of 'strict mode'?
  addMessage: (message, useBuffer = false)->
    throw new Error "Unacceptable message format in logger: #{@name}" if not @messageAcceptable message
    if @useBuffer or useBuffer then @messageBuffer.push message else @log message

  # `log` - 'virtual' function that does actual output of the message. Needs to be overriden by extending
  # classes with e.g. logging to console or inserting into Meteor Collection. Does nothing here.
  log: (message)->
    throw new Error "log() function needs to be overriden to perform actual output!"

  # processing the buffer
  processBuffer: ->
    return unless @messageBuffer.length > 0
    @log obj for obj in @messageBuffer
    @messageBuffer = []

# <a name="abcde"></a>
#
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

    super name, @formatter
    # some dynamic js magic - defining different severity method aliases programmatically to be DRY.
    # TODO: need to keep in mind bind() doesn't work in IE8 and below, but there's a
    # [script to fix this](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Function/bind#Compatibility)
    for m,i in ['fatal','error','warn','info','verbose','debug','insaneVerbose']
      @[m] = @_emitWithSeverity.bind this, i

  # Trace a error - format stacktrace nicely and output with ERROR level
  trace: (error, module)->
    message = error.stack ? error
    @_emitWithSeverity Observatory.LOGLEVEL.ERROR, message, module

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

    options = severity: severity, message: message, object: obj, module: module ? @name # explicit module overrides name
    @emitMessage @formatter(options)

# ### ConsoleLogger
# Basic logger to the console, without any fancy stuff
class Observatory.ConsoleLogger extends Observatory.Logger
  # Simply redefining log() to output messages to the console
  log: (m)-> console.log @formatter m

(exports ? this).Observatory = Observatory