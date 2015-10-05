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

  exec: (f, options = errors: true, profile: true, profileLoglevel: 'INFO', message: "exec() call", module: 'profiler' )=>
    if typeof f isnt 'function'
      @error "Tried to call exec() without a function as an argument"
      return 

    obj = 
      function: f.toString()
      type: 'profile'

    @_emitWithSeverity Observatory.LOGLEVEL[options.profileLoglevel], options.message + " starting for " + obj.function, options.module if options.profile
    if options.errors
      try
        t = Date.now()
        ret = f.call this
        t2 = Date.now() - t
      catch e
        t2 = Date.now() - t
        @trace e
    else
      t = Date.now()
      ret = f.call this
      t2 = Date.now() - t

    @profile options.message + " done in #{t2} ms", t2, obj, module, options.profileLoglevel if options.profile
    ret


  profile: (message, time, object, module = 'profiler', severity = 'VERBOSE', buffer = false)->
    object = object ? {}
    object.timeElapsed = time
    @_emitWithSeverity Observatory.LOGLEVEL[severity], message, object, module, 'profile'

  _profile: (message, time, object, module = 'profiler', severity = 'VERBOSE', buffer = false)->
    object = object ? {}
    object.timeElapsed = time
    @_forceEmitWithSeverity Observatory.LOGLEVEL[severity], message, object, module, 'profile'


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