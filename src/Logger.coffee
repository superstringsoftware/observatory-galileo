Observatory = @Observatory ? {}

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
    #console.log "Logger::addMessage() with useBuffer: #{useBuffer}"
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

(exports ? this).Observatory = Observatory