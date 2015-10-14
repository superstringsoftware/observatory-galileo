###

  # Commented out for Meteor usage

if require?
  Observatory = (require './Observatory.coffee').Observatory
  {MessageEmitter, GenericEmitter, Logger, ConsoleLogger, LOGLEVEL} = Observatory
###

# ### Constants and common definitions
Observatory = Observatory ? {}

#console.log Observatory
# TLog replacement?
class Observatory.Toolbox extends Observatory.GenericEmitter
  #constructor: (name, maxSeverity, formatter)-> super name, maxSeverity, formatter

  # Simply records log with type = 'profile'
  dumbProfile: (message, time, object, module = 'profiler', severity = 'VERBOSE', buffer = false)->
    object = object ? {}
    object.timeElapsed = time
    @_emitWithSeverity Observatory.LOGLEVEL[severity], message, object, module, 'profile', buffer

  # Simply records log with type = 'profile' and disregards current logging level (severity)
  forceDumbProfile: (message, time, object, module = 'profiler', severity = 'VERBOSE', buffer = false)->
    object = object ? {}
    object.timeElapsed = time
    @_forceEmitWithSeverity Observatory.LOGLEVEL[severity], message, object, module, 'profile', buffer

  # TODO: check if profiling is on and optimize method call if not - so that people can wrap into profiling wherever they want and not worry about performance
  # profile sync function execution
  # * options: additional options to put into profiling log message
  # * - message: message to log with
  # * - method: method name that we are profiling
  # * - buffer: whether to buffer log output (needed in Meteor mostly)
  # * func: function to profile followed by its' arguments, however many
  profile: (options, thisArg, func)=>
    args = _.rest (_.rest (_.rest arguments))

    t1 = Date.now()
    ret = func.apply thisArg, args
    t2 = Date.now() - t1

    msg = "#{options.method} call finished in #{t2} ms | #{options.message}"
    object =
      timeElapsed: t2
      method: options.method
      arguments: EJSON.stringify args
      stack: (new Error()).stack
    @_verbose msg, object, 'profiler', 'profile', (options.buffer? is true)
    #console.log object
    ret

  # profile async function execution
  # * options: additional options to put into profiling log message
  # * - message: message to log with
  # * - method: method name that we are profiling
  # * - buffer: whether to buffer log output (needed in Meteor mostly)
  # * func: function to profile followed by its' arguments, however many
  profileAsync: (options, thisArg, func)=>
    args = _.rest (_.rest (_.rest arguments))

    sargs = EJSON.stringify args
    orig_callback = args.pop()

    callback = (err,res)=>
      t2 = Date.now() - @__startTime
      msg = "#{options.method} call finished in #{t2} ms | #{options.message}"
      object =
        timeElapsed: t2
        method: options.method
        arguments: sargs
        stack: (new Error()).stack
        type: "profile.end"
      @_verbose msg, object, 'profiler', 'profile', (options.buffer? is true)
      #console.log object

      orig_callback err, res if typeof orig_callback is 'function'

    if typeof orig_callback is 'function'
      args.push callback
    else
      args.push orig_callback
      args.push callback


    msg = "#{options.method} call started"
    object =
      method: options.method
      arguments: sargs
      stack: (new Error()).stack
      type: "profile.start"
    @_verbose msg, object, 'profiler', 'profile', (options.buffer? is true)

    @__startTime = Date.now()
    func.apply thisArg, args



  inspect: (obj, long = false, print = false)->
    ret =
      functions: []
      objects: []
      vars: []
    for k,v of obj
      switch typeof v
        when 'function' then ret.functions.push key: k, value: v.toString()
        when 'object' then ret.objects.push key: k, value: (if long then v else "Object")
        else ret.vars.push key: k, value: v
    if print
      for t in ['functions','objects','vars']
        console.log "****** PRINTING #{t} ***********" if ret[t].length > 0
        if long
          console.log "#{it.key}: #{it.value}" for it in ret[t]
        else
          console.log it.key for it in ret[t]
    #console.log ret
    ret


#console.log Observatory
(exports ? this).Observatory = Observatory
#console.log Observatory