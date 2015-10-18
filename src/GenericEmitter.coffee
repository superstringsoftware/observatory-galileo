Observatory = @Observatory ? {}

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
    # same but ignoring global logging level
    for m,i in ['_fatal','_error','_warn','_info','_verbose','_debug','_insaneVerbose']
      @[m] = @_forceEmitWithSeverity.bind this, i

  # Trace a error - format stacktrace nicely and output with ERROR level
  trace: (error, msg, module)->
    message = msg + '\n' + (error.stack ? error)
    @_emitWithSeverity Observatory.LOGLEVEL.ERROR, message, {module: module, obj: error}

  # Low-level emitting method that formats message and emits it
  #
  # * `severity` - level with which to emit a message. Won't be emitted if higher than `@maxSeverity`
  # * `message` - text message to include into the full log message to be passed to loggers
  # * `module` - optional module name. If the emitter is named, its' name will be used instead in any case.
  # * `obj` - optional arbitrary json-able object to be included into full log message, e.g. error object in the call to `error`
  # This is the old API, deprecated as of 1.0.0 - _forceEmitWithSeverity: (severity, message, obj, module, type, buffer = false)
  #
  # Now need to use _forceEmitWithSeverity with following alternative signatures, which are much more versatile:
  # (severity, message, options) - text message and options object. If options.message is present, it's ignored.
  # (severity, message) - text message only
  # (severity, options) - options.message needs to contain the text message
  #
  # * `severity` - Number, level with which to emit a message. Won't be emitted if higher than `@maxSeverity`
  # Here's the possible options fields description:
  # * `message` - String, text message to include into the full log message to be passed to loggers
  # * `module` - String, optional module name. If the emitter is named, its' name will be used instead in any case.
  # * `type` - String, type of the message, used internally for distinguishing between different message types for further processing
  # * `obj` - Object, optional arbitrary json-able object to be included into full log message, e.g. error object in the call to `error`
  # * `useBuffer` - Bool, whether to tell loggers to use the buffer
  #
  # NOTE: it DOES NOT use formatters any more and DOES NOT check for correct formatting for performance, so there's potential to mess things up!!!
  #
  _forceEmitWithSeverity: (severity, message, options)->
    if typeof message is 'object' # assuming no message, only options passed in
      options = message
    else
      if typeof message is 'string'
        options = {} unless typeof options is 'object'
        options.message = message
      else throw new Error "Logging methods need to pass at least a text message as a parameter!"

    msg = @messageStub severity, options.message, options.type, options.obj ? options.object, options.module
    @emitMessage msg, options.useBuffer ? false

  _emitWithSeverity: (severity, message, options)->
    return false if typeof severity isnt 'number' or (severity > @maxSeverity)
    @_forceEmitWithSeverity severity, message, options


(exports ? this).Observatory = Observatory