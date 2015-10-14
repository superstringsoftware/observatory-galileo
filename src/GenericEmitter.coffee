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
    @_emitWithSeverity Observatory.LOGLEVEL.ERROR, message, error, module

  # Low-level emitting method that formats message and emits it
  #
  # * `severity` - level with which to emit a message. Won't be emitted if higher than `@maxSeverity`
  # * `message` - text message to include into the full log message to be passed to loggers
  # * `module` - optional module name. If the emitter is named, its' name will be used instead in any case.
  # * `obj` - optional arbitrary json-able object to be included into full log message, e.g. error object in the call to `error`
  _forceEmitWithSeverity: (severity, message, obj, module, type, buffer = false)->
    if typeof message is 'object'
      buffer = type
      type = module
      module = obj
      obj = message
      message = JSON.stringify obj
    if typeof obj is 'string'
      buffer = type
      type = module
      module = obj
      obj = null

    options = severity: severity, message: message, object: obj, type: type, module: module ? @name # explicit module overrides name
    @emitMessage @formatter(options), buffer

  _emitWithSeverity: (severity, message, obj, module, type, buffer = false)->
    return false if not severity? or (severity > @maxSeverity)
    @_forceEmitWithSeverity severity, message, obj, module, type, buffer

(exports ? this).Observatory = Observatory