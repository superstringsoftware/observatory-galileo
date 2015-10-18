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
Observatory = @Observatory ? {}

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
    printToConsole: false
    profiling:
      isOn: true # globally profiling on or off?
      maxProfilingLevel: 4 # WARNING by default - use LOGLEVELS here!!!
      DANGER_THRESHOLD: 1000 # 1s
      WARNING_THRESHOLD: 100 # 100 ms

  # Initializing the system - creating loggers, subscribing etc
  # Currently creates 1 ConsoleLogger and subscribes it system-wide.
  # Also initializes default logger (Generic Emitter).
  # TODO: add tests and settings format
  initialize: (settings)->
    f.call this, settings for f in @_initFunctions

  registerInitFunction: (f)->
    @_initFunctions.push f

  # array of initialization functions
  _initFunctions: [
    (s)->
      @_loggers = []
      @emitters = {}
      #console.log s
      if s?
        @settings.maxSeverity = if s.logLevel? then @LOGLEVEL[s.logLevel] else 3
        @settings.printToConsole = s.printToConsole ? true
        @settings.profiling = s.profiling if s.profiling?
      @_consoleLogger = new Observatory.ConsoleLogger 'default'
      @subscribeLogger @_consoleLogger if @settings.printToConsole
      @_defaultEmitter = new Observatory.Toolbox 'Toolbox'
      @emitters.Toolbox = @_defaultEmitter
      @emitters.Toolbox.maxSeverity = @settings.maxSeverity
  ]

  # Setting the settings, in reality it's only setting right severity on all the emitters
  setSettings: (s)->
    @settings.profiling = s.profiling if s.profiling?
    # first getting correct numeric maxSeverity from settings
    if s.maxSeverity?
      @settings.maxSeverity = s.maxSeverity
    else
      if s.logLevel? then @settings.maxSeverity = @LOGLEVEL[s.logLevel]
    # now processing console logger
    if s.printToConsole? and (s.printToConsole isnt @settings.printToConsole)
      @settings.printToConsole = s.printToConsole
      if s.printToConsole is true then @subscribeLogger @_consoleLogger else @unsubscribeLogger @_consoleLogger
    # now setting max severity for all emitters
    for k,v of @emitters
      #console.log v
      v.maxSeverity = @settings.maxSeverity
    #@emitters.Toolbox?.maxSeverity = @settings.maxSeverity

  # Returns default logger to use in the app via warn(), debug() etc calls
  getDefaultLogger: -> @_defaultEmitter
  getToolbox: -> @_defaultEmitter

  # Check if we are run on server or client.
  # NOTE! To be overridden for Meteor based implementations!
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
        object: options.object ? options.obj
        isServer: Observatory.isServer()
        type: options.type

  # View formatters take a message accepted by loggers and further format it for nice output,
  # e.g., adding ANSI colors or html markup.
  viewFormatters:
    _convertDate: (timestamp, long = false)->
      ds = @_lpad(timestamp.getUTCDate(), 2) + '/' + @_lpad(timestamp.getUTCMonth() + 1, 2)
      ds = ds +  + '/'+timestamp.getUTCFullYear() if long
      ds
    _convertTime: (timestamp, ms = true) ->
      ts = @_lpad(timestamp.getUTCHours(), 2) + ':' + @_lpad(timestamp.getUTCMinutes(), 2) + ':' + @_lpad(timestamp.getUTCSeconds(), 2)
      ts += '.' + @_lpad(timestamp.getUTCMilliseconds(), 3) if ms
      ts
    _ps: (s)-> '['+s+']'
    _lpad: (str = '', length = 0, padStr = '0') ->
      length -= str.toString().length
      while length > 0
        str = padStr + str
        length--
      str

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


(exports ? this).Observatory = Observatory