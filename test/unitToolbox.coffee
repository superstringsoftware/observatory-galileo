_ = require 'underscore'
chai = require 'chai'
should = chai.should()
#expect = chai.expect
Observatory = (require '../src/Toolbox.coffee').Observatory
#console.log Observatory
#Observatory = (require '../src/Observatory.coffee').Observatory
{Toolbox, MessageEmitter, GenericEmitter, Logger, ConsoleLogger, LOGLEVEL} = Observatory

describe 'Toolbox - main set of tools and the only class a user may generally need to use',->
  it 'Should work',->
    tb = new Toolbox
    #tb.inspect tb
    tb.info "Toolbox created"
    tb.exec ->
      for i in [1..500000]
        b = i*i
    # what happens if we exec with arguments?
    f = (max)->
      for i in [1..max]
        throw new Error "Test error out of the wrapped function!" if i> 573000
        b = i*i
      b
    ret = tb.exec(-> f(1500000))
    tt = _.wrap f, tb.exec
    console.log "Do we see ret? " + ret
    tt()



