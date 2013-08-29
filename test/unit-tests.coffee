chai = require 'chai'
should = chai.should()
Observatory = (require '../src/Observatory.coffee').Observatory
{MessageEmitter, GenericEmitter, LOGLEVEL} = Observatory
#console.log MessageEmitter

Spy =
  calledMethod: ['', '', '']
logger1 =
  name: "logger1"
  addMessage: (msg)-> Spy.calledMethod[0] = msg
logger2 =
  name: "logger2"
  addMessage: (msg)-> Spy.calledMethod[1] = msg
logger3 =
  name: "logger3"
  addMessage: (msg)-> Spy.calledMethod[2] = msg

describe 'Observatory - centralized code and functions', ->
  it 'should be created with empty loggers buffer and provide correct log levels arrays',->
    Observatory._loggers.should.be.empty
    Observatory.LOGLEVEL.should.be.eql
      SILENT: -1
      FATAL: 0
      ERROR: 1
      WARNING: 2
      INFO: 3
      VERBOSE: 4
      DEBUG: 5
      MAX: 6
      NAMES: ["FATAL", "ERROR", "WARNING", "INFO", "VERBOSE", "DEBUG", "MAX"]
  it 'should allow logger subscription',->
    Observatory.subscribeLogger logger1
    Observatory.subscribeLogger logger2
    Observatory._loggers.length.should.equal 2
    Observatory._loggers[0].should.equal logger1
    Observatory._loggers[1].should.equal logger2
  it 'should unsubscribe loggers', ->
    Observatory.unsubscribeLogger logger1
    Observatory._loggers.length.should.equal 1
    Observatory._loggers[0].should.equal logger2
    Observatory.unsubscribeLogger logger2
    Observatory._loggers.should.be.empty

  describe 'MessageEmitter - base class for anything that can produce a message to log', ->
    me = new MessageEmitter "newEmitter"
    logger1 =
      name: "logger1"
      addMessage: (msg)-> Spy.calledMethod[0] = msg
    logger2 =
      name: "logger2"
      addMessage: (msg)-> Spy.calledMethod[1] = msg

    it 'should be created with empty loggers buffer and name set correctly',->
      me._loggers.should.be.empty
      me.name.should.equal "newEmitter"

    it 'should allow logger subscription',->
      me.subscribeLogger logger1
      me.subscribeLogger logger2
      me._loggers.length.should.equal 2
      me._loggers[0].should.equal logger1
      me._loggers[1].should.equal logger2

    it 'should send messages to each subscribed logger, both local and global', ->
      Observatory.subscribeLogger logger3
      msg = "test message"
      me.emitMessage msg
      for m in Spy.calledMethod
        m.should.equal msg

    it 'should unsubscribe loggers', ->
      me.unsubscribeLogger logger1
      me._loggers.length.should.equal 1
      me._loggers[0].should.equal logger2
      me.unsubscribeLogger logger2
      me._loggers.should.be.empty

  describe 'GenericEmitter - typical logging functionality provider to be used in apps', ->
    gem = new GenericEmitter "Gem", LOGLEVEL.MAX
    it 'should be created with correct name and should set maximum severity', ->
      gem.name.should.equal "Gem"
      gem.maxSeverity.should.equal LOGLEVEL.MAX
    it 'should respond to all severity logging methods', ->
      for m in ['fatal','error','warn','info','verbose','debug','insaneVerbose']
        gem.should.respondTo m

