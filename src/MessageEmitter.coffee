# ## MessageEmitter
# This class is the base for anything that wants to produce messages to be logged.
_ = require 'underscore'
Observatory = Observatory ? {}

class Observatory.MessageEmitter
  @_loggers = [] # array of subscribing loggers

  _getLoggers: -> @_loggers
  constructor: (@name)-> @_loggers = []

  # add new logger to listen to messages
  subscribeLogger: (logger)-> @_loggers.push logger
  # remove logger from the listeners
  unsubscribeLogger: (logger)-> @_loggers = _.without @_loggers, logger

  # Translates message to be logged to all subscribed loggers.
  # [Logger](http://example.net/) has to respond to `addMessage(msg)` call.
  emitMessage: (message)->
    l.addMessage message for l in @_loggers

(exports ? this).Observatory = Observatory