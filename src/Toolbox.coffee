###

  # Commented out for Meteor usage

if require?
  Observatory = (require './Observatory.coffee').Observatory
  {MessageEmitter, GenericEmitter, Logger, ConsoleLogger, LOGLEVEL} = Observatory
###

# ### Constants and common definitions
Observatory = @Observatory ? {}

#console.log Observatory
# TLog replacement?

# TODO: profiling methods need to go to a separate profiler emitter, with it's own formatter - this way we'll ensure all profiling messages are formatted correctly
class Observatory.Toolbox extends Observatory.GenericEmitter
  #constructor: (name, maxSeverity, formatter)-> super name, maxSeverity, formatter

  # Simply records log with type = 'profile'
  dumbProfile: (message, time, object, module = 'Profiler', severity = 'VERBOSE', buffer = false)->
    object = object ? {}
    object.timeElapsed = time
    options =
      obj: object
      message: message
      module: module
      useBuffer: buffer
      type: 'profile'
    @_emitWithSeverity Observatory.LOGLEVEL[severity], options

  # Simply records log with type = 'profile' and disregards current logging level (severity)
  forceDumbProfile: (message, time, object, module = 'Profiler', severity = 'VERBOSE', buffer = false)->
    object = object ? {}
    object.timeElapsed = time
    options =
      obj: object
      message: message
      module: module
      useBuffer: buffer
      type: 'profile'
    @_forceEmitWithSeverity Observatory.LOGLEVEL[severity], options


  # calculating profiling level based on time elapsed and current thresholds
  _determineProfilingLevel: (timeElapsed)->
    # determine with which level to log
    loglevel = Observatory.LOGLEVEL.ERROR
    if timeElapsed < Observatory.settings.profiling.WARNING_THRESHOLD
      loglevel = Observatory.LOGLEVEL.VERBOSE
    else if timeElapsed < Observatory.settings.profiling.DANGER_THRESHOLD
      loglevel = Observatory.LOGLEVEL.WARNING
    loglevel

  # preparing message to emit based on options (as in profile / profileAsync methods) and time elapsed
  _prepareMessage: (timeElapsed, options, args)->
    msg = if options.message? then "| #{options.message}" else ''
    opts =
      message: "#{options.method} call finished in #{timeElapsed} ms #{msg}"
      type: options.type ? 'profile'
      module: options.module ? 'Profiler'
      useBuffer: options.useBuffer ? false
      obj:
        timeElapsed: timeElapsed
        method: options.method
        arguments: JSON.stringify args
        stack: (new Error()).stack
        type: "profile.end"

  # TODO: write tests for profiling functions
  # profile sync function execution
  # * options: additional options to put into profiling log message
  # * - message: message to log with
  # * - method: method name that we are profiling
  # * - useBuffer: whether to buffer log output (needed in Meteor mostly)
  # * func: function to profile followed by its' arguments, however many
  profile: (options, thisArg, func)=>
    # first checking if profiling is off and then simply passing the call - minimal overhead!
    args = _.rest (_.rest (_.rest arguments))
    return func.apply thisArg, args unless Observatory.settings.profiling.isOn

    # ok, it's on, profiling
    t1 = Date.now()
    ret = func.apply thisArg, args
    t2 = Date.now() - t1

    # determine with which level to log
    loglevel = @_determineProfilingLevel t2
    # only logging if thresholds are ok, otherwise simply returning
    return ret if loglevel > Observatory.settings.profiling.maxProfilingLevel

    @_forceEmitWithSeverity loglevel, @_prepareMessage t2, options, args
    #console.log object
    ret

  # TODO: properly handle profile.start events - only record them if t2 is within thresholds!!! (do we even need profile.start?)
  # profile async function execution
  # * options: additional options to put into profiling log message
  # * - message: message to log with
  # * - method: method name that we are profiling
  # * - buffer: whether to buffer log output (needed in Meteor mostly)
  # * func: function to profile followed by its' arguments, however many
  profileAsync: (options, thisArg, func)=>
    # first checking if profiling is off and then simply passing the call - minimal overhead!
    args = _.rest (_.rest (_.rest arguments))
    return func.apply thisArg, args unless Observatory.settings.profiling.isOn

    orig_callback = args.pop()

    # redefining callback for recording execution times
    callback = (err,res)=>
      t2 = Date.now() - @__startTime

      # determine with which level to log
      loglevel = @_determineProfilingLevel t2
      # only logging if thresholds are ok, otherwise simply returning
      if loglevel < Observatory.settings.profiling.maxProfilingLevel
        @_forceEmitWithSeverity loglevel, @_prepareMessage t2, options, args
        #console.log object

      orig_callback err, res if typeof orig_callback is 'function'

    # END OF callback definition

    # putting back arguments for the function being profiled
    if typeof orig_callback is 'function'
      args.push callback
    else
      args.push orig_callback
      args.push callback


    msg = "#{options.method} call started"
    object =
      method: options.method
      stack: (new Error()).stack
      type: "profile.start"
    @_verbose msg, {object: object, module: 'Profiler', useBuffer: options.useBuffer ? false}

    @__startTime = Date.now()
    func.apply thisArg, args



  # TODO: add recursion down to specific level (to work around circular objects)
  inspect: (obj, long = false, print = false)->
    ret =
      functions: []
      objects: []
      vars: []
      varsObject: {}
    for k,v of obj
      switch typeof v
        when 'function' then ret.functions.push key: k, value: v.toString()
        when 'object' then ret.objects.push key: k, value: (if long then v else "Object")
        else
          ret.vars.push key: k, value: v
          ret.varsObject[k] = v
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