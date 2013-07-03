
expect = require('chai').expect
sinon = require('sinon')
Caddy = require('caddy')
Stacktimer = require('../dist/stacktimer')
STACK_KEY = require('../dist/consts').STACK_KEY

describe 'stacktimer.js', ->
  it 'should export the correct interface', ->
    expect(Stacktimer.start).to.exist
    expect(Stacktimer.stop).to.exist
    expect(Stacktimer.stub).to.exist
    expect(Stacktimer.exec).to.exist
    expect(Stacktimer.add).to.exist
    expect(Stacktimer.toJSON).to.exist

  it 'should create/delete a Caddy key when start()/stop() is called', ->
    next = sinon.stub()
    expect(Caddy.get(STACK_KEY)).to.not.exist
    Stacktimer.start(null, null, next)
    expect(Caddy.get(STACK_KEY)).to.exist
    Stacktimer.stop()
    expect(Caddy.get(STACK_KEY)).to.not.exist

  it 'should call next() when start() is called', ->
    next = sinon.stub()
    Stacktimer.start(null, null, next)
    expect(next.calledOnce).to.be.true
    Stacktimer.stop()

  it 'should start new trace when start() is called', ->
    Stacktimer.start(null, null, ->)
    results = Stacktimer.toJSON()
    expect(results.task).to.equal('request')
    expect(results.start).to.equal(0)
    expect(results.end).to.not.exist
    expect(results.duration).to.not.exist
    expect(results.subTasks).to.not.exist
    Stacktimer.stop()

  it 'should end the trace when stop() is called', ->
    Stacktimer.start(null, null, ->)
    results = Stacktimer.stop()
    expect(results.task).to.equal('request')
    expect(results.start).to.equal(0)
    expect(results.end).to.exist
    expect(results.duration).to.exist
    expect(results.subTasks).to.not.exist

  it 'should add metadata to the trace when add is called', ->
    Stacktimer.start(null, null, ->)
    Stacktimer.add('string', 'data')
    Stacktimer.add('number', 20)
    Stacktimer.add('object', { tag: 'data'})
    results = Stacktimer.stop()
    expect(results.string).to.equal('data')
    expect(results.number).to.equal(20)
    expect(results.object.tag).to.equal('data')

  it 'should throw an error if exec() is not called with a function parameter', (done) ->
    try
      Stacktimer.exec(null, null, null, null)
    catch error
      expect(error.message).to.equal("typeof(fn) !== 'function'")
      done()

  it 'should throw an error if exec() is not called with an Array arg parameter', (done) ->
    try
      Stacktimer.exec(null, null, 'string', ->)
    catch error
      expect(error.message).to.equal("provided args is not an array")
      done()

  it 'should throw an error if exec() is not called with a tag', (done) ->
    try
      Stacktimer.exec(null, null, [], ->)
    catch error
      expect(error.message).to.equal("provided tag does not exist")
      done()

  it 'should call function normally if exec() is called before start()', ->
    stub = sinon.stub()
    Stacktimer.exec('test', null, ["arg1", "arg2"], stub)
    stack = Caddy.get(STACK_KEY)
    expect(stack).to.not.exist
    expect(stub.calledOnce).to.be.true
    expect(stub.calledWith("arg1", "arg2")).to.be.true

  it 'should push() and pop() the stack frome if exec is called on a sync function', ->
    func = ->
      stack = Caddy.get(STACK_KEY)
      expect(stack.length).to.equal(2)
      expect(stack[1].toJSON().task).to.equal("subTask")
    Stacktimer.start(null, null, ->)
    stack = Caddy.get(STACK_KEY)
    expect(stack.length).to.equal(1)
    Stacktimer.exec('subTask', this, [], func)
    expect(stack.length).to.equal(1)
    result = Stacktimer.stop()

  it 'should push() and pop() the stack frome if exec is called on an async function', (done) ->
    func = ->
      setTimeout(->
        stack = Caddy.get(STACK_KEY)
        expect(stack.length).to.equal(2)
        expect(stack[1].toJSON().task).to.equal("subTask")
        result = Stacktimer.stop()
        done()
      , 100)
      return
    Stacktimer.start(null, null, ->)
    stack = Caddy.get(STACK_KEY)
    expect(stack.length).to.equal(1)
    Stacktimer.exec('subTask', this, [], func)
    expect(stack.length).to.equal(1)
