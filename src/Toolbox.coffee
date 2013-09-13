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

  exec: (f, options = errors: true, profile: true, profileLoglevel: 'INFO', message: "exec() call" )=>
    if typeof f isnt 'function'
      @error "Tried to call exec() without a function as an argument"
      return 

    obj = 
      function: f.toString()
      type: 'profile'

    @_emitWithSeverity Observatory.LOGLEVEL[options.profileLoglevel], options.message + " starting for " + obj.function, 'profiler'
    if options.errors
      try
        t = Date.now() if options.profile
        ret = f.call this
        t2 = Date.now() - t if options.profile
      catch e
        t2 = new Date - t if options.profile
        @trace e
    else
      t = Date.now() if options.profile
      ret = f.call this
      t2 = Date.now() - t if options.profile

    obj.timeElapsed = t2
    @_emitWithSeverity Observatory.LOGLEVEL[options.profileLoglevel], options.message + " done in #{t2} ms", obj, 'profiler' if options.profile
    ret


  profile: (message, time, object, module = 'profiler', severity = 'VERBOSE')->
    object = object ? {}
    object.timeElapsed = time
    @_emitWithSeverity Observatory.LOGLEVEL[severity], message, object, module, 'profile'


  inspect: (obj, long = true, print = false)->
    ret =
      functions: []
      objects: []
      vars: []
    for k,v of obj
      switch typeof v
        when 'function' then ret.functions.push key: k, value: v
        when 'object' then ret.objects.push key: k, value: v
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