Observatory = @Observatory ? {}

# ### MessageEmitter
# This class is the base for anything that wants to produce messages to be logged.
class Observatory.MessageEmitter

  constructor: (@name, @formatter)->
  #console.log "MessageEmitter::constructor #{name}"
    @_loggers = [] # array of subscribing loggers
    @isOn = true

  _getLoggers: -> @_loggers

  # only emit messages if we are on
  turnOn: -> @isOn = true
  turnOff: -> @isOn = false

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
  #console.log "MessageEmitter::emitMessage() with buffer: #{buffer}"
    return unless @isOn
    l.addMessage message, buffer for l in Observatory.getLoggers()
    l.addMessage message, buffer for l in @_loggers if @_loggers.length > 0
    message

  # TODO: throw an error when there's no formatter?
  emitFormattedMessage: (message, buffer = false)->
  #console.log "MessageEmitter::emitFormattedMessage() with buffer: #{buffer}"
    @emitMessage (@formatter message), buffer if @isOn and @formatter? and (typeof @formatter is 'function')
    message

(exports ? this).Observatory = Observatory