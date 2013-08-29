chai = require 'chai'
should = chai.should()
{MessageEmitter} = (require '../src/MessageEmitter.coffee').Observatory

Spy =
  calledMethod: ['', '']

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
  it 'should send messages to each subscribed logger', ->
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
