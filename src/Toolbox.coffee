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

  exec: (f, options = errors: true, profile: true, profileLoglevel: LOGLEVEL.INFO, message: "exec() call" )=>
    @error "Tried to call exec() without a function as an argument"; return if typeof f isnt 'function'
    @_emitWithSeverity options.profileLoglevel, options.message + " starting for " + f.toString()
    if options.errors
      try
        t = new Date if options.profile
        ret = f()
        t2 = new Date - t if options.profile
      catch e
        t2 = new Date - t if options.profile
        @trace e
    else
      t = new Date if options.profile
      ret = f()
      t2 = new Date - t if options.profile
    @_emitWithSeverity options.profileLoglevel, options.message + " done in #{t2} ms" if options.profile
    ret


  inspect: (obj, long = true, print = true)->
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