chai = require 'chai'
should = chai.should()
#expect = chai.expect
Observatory = (require '../src/Observatory.coffee').Observatory
{MessageEmitter, GenericEmitter, Logger, LOGLEVEL} = Observatory
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
    Observatory.maxSeverity.should.equal Observatory.LOGLEVEL.INFO

  describe 'subscribeLogger()',->
    it 'should allow logger subscription',->
      Observatory.subscribeLogger logger1
      Observatory.subscribeLogger logger2
      Observatory._loggers.length.should.equal 2
      Observatory._loggers[0].should.equal logger1
      Observatory._loggers[1].should.equal logger2

  describe 'unsubscribeLogger()',->
    it 'should unsubscribe loggers', ->
      Observatory.unsubscribeLogger logger1
      Observatory._loggers.length.should.equal 1
      Observatory._loggers[0].should.equal logger2
      Observatory.unsubscribeLogger logger2
      Observatory._loggers.should.be.empty

  describe 'reset()',->
    it 'should clean up subscribed loggers and reset settings to the defaults',->
      Observatory.reset()
      Observatory.maxSeverity.should.equal LOGLEVEL.INFO
      Observatory.getLoggers().should.be.empty

  describe 'Formatters - functions that take arbitrary json and format it into message to log', ->
    describe 'basicFormatter',->
      it 'should format object with severity, client / server, date and message', ->
        obj = a: 'a', b: 1
        msgr = Observatory.formatters.basicFormatter severity: LOGLEVEL.INFO, message: 'test message', module: 'module', obj: obj
        msgr.timestamp.should.exist
        msgr.severity.should.equal LOGLEVEL.INFO
        msgr.textMessage.should.equal 'test message'
        msgr.module.should.equal 'module'
        msgr.isServer.should.equal Observatory.isServer()
        msgr.object.should.equal obj

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

    it 'should be created with correct name, should set maximum severity and default formatter', ->
      gem.name.should.equal "Gem"
      gem.maxSeverity.should.equal LOGLEVEL.MAX
      gem.formatter.should.equal Observatory.formatters.basicFormatter

    it 'should respond to all severity logging methods and emit them at the correct level', ->
      obj = a: 'a', b: 1
      #console.log Observatory.getLoggers()
      for m,i in ['fatal','error','warn','info','verbose','debug','insaneVerbose']
        gem.should.respondTo m
        msgr = gem[m] 'test message', obj
        msgr.timestamp.should.exist
        msgr.severity.should.equal i
        msgr.textMessage.should.equal 'test message'
        msgr.module.should.equal 'Gem'
        msgr.isServer.should.equal Observatory.isServer()
        msgr.object.should.equal obj
        msgr.should.be.equal Spy.calledMethod[2]
        #console.log Spy.calledMethod[2]

    describe '_emitWithSeverity - main method for forming messages',->
      it 'should shift arguments around correctly',->
        obj = a: 'a', b: 1
        # skipping message - obj used instead
        m = gem.info obj, 'module'
        m.object.should.equal obj
        m.module.should.equal 'module'
        m.textMessage.should.equal (JSON.stringify obj)
        # just the message
        m = gem.info 'test message'
        should.not.exist m.object
        m.module.should.equal 'Gem'
        m.textMessage.should.equal 'test message'
        # skipping object - module name used instead
        m = gem.info 'test message', 'module'
        should.not.exist m.object
        m.module.should.equal 'module'
        m.textMessage.should.equal 'test message'

  describe 'Logger - base class for all loggers that listen to messages and output them somewhere',->
    l = new Logger 'logger'
    it 'should be created with defaults',->
      l.name.should.equal 'logger'
      l.useBuffer.should.be.false
      l.interval.should.equal 3000
    describe 'addMessage(message)',->
      it 'should not accept malformed messages',->
        (-> l.addMessage(null)).should.throw Error
      it 'should accept well-formed messages but throw error when logging',->
        goodm = timestamp: new Date, severity: 0, textMessage: 'error', isServer: true
        l.messageAcceptable(goodm).should.be.true
        (-> l.addMessage(goodm)).should.throw Error
    describe 'addMessage(message) with buffer',->
      l1 = new Logger 'logger1', true
      goodm = timestamp: new Date, severity: 0, textMessage: 'error', isServer: true
      it 'should add well-formed message to the buffer',->
        l1.addMessage goodm
        l1.messageBuffer.length.should.equal 1
      it 'should not add malformed message to the buffer',->
        (-> l1.addMessage(null)).should.throw Error
        l1.messageBuffer.length.should.equal 1
      describe 'processBuffer()',->
        it 'should throw exception as log() must be overriden',->
          (-> l1.processBuffer()).should.throw Error



