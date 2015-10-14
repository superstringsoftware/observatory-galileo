Observatory = @Observatory ? {}

# ### ConsoleLogger
# Basic logger to the console, without any fancy stuff
class Observatory.ConsoleLogger extends Observatory.Logger
  # Simply redefining log() to output messages to the console
  log: (m) ->
    console.log @formatter m

  # ignoring any buffering requests
  addMessage: (message, useBuffer)->
    #console.log "addMessage() called for message:"
    #console.log message
    throw new Error "Unacceptable message format in logger: #{@name}" if not @messageAcceptable message
    @log message


(exports ? this).Observatory = Observatory