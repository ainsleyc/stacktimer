
expect = require('chai').expect
sinon = require('sinon')
Caddy = require('caddy')
Stacktimer = require('../dist/stacktimer')
ROOT_KEY = require('../dist/consts').ROOT_KEY
CURR_FRAME_KEY = require('../dist/consts').CURR_FRAME_KEY
PREV_FRAME_KEY = require('../dist/consts').PREV_FRAME_KEY

describe 'stacktimer.js', ->
  it 'should export the correct interface', ->
    expect(Stacktimer.start).to.exist
    expect(Stacktimer.stop).to.exist
    expect(Stacktimer.stub).to.exist
    expect(Stacktimer.exec).to.exist
    expect(Stacktimer.add).to.exist
    expect(Stacktimer.addRoot).to.exist
    expect(Stacktimer.toJSON).to.exist

  it 'should create/delete a Caddy key when start()/stop() is called', ->
    next = sinon.stub()
    expect(Caddy.get(ROOT_KEY)).to.not.exist
    expect(Caddy.get(CURR_FRAME_KEY)).to.not.exist
    expect(Caddy.get(PREV_FRAME_KEY)).to.not.exist
    Stacktimer.start(null, null, next)
    expect(Caddy.get(ROOT_KEY)).to.exist
    expect(Caddy.get(CURR_FRAME_KEY)).to.exist
    expect(Caddy.get(PREV_FRAME_KEY)).to.not.exist
    Stacktimer.stop()
    expect(Caddy.get(ROOT_KEY)).to.not.exist
    expect(Caddy.get(CURR_FRAME_KEY)).to.not.exist
    expect(Caddy.get(PREV_FRAME_KEY)).to.not.exist

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
    Stacktimer.exec('sync', this, [], ->
      Stacktimer.add('string', 'data')
    )
    Stacktimer.exec('async1', this, [->
      Stacktimer.add('object', { tag: 'data' })
      Stacktimer.exec('async2', this, [->
        Stacktimer.add('more', 'more')
      ], (cb) ->
        Stacktimer.add('array', ['test'])
        cb()
      )
    ], (cb) ->
      Stacktimer.add('number', 20)
      cb()
    )
    results = Stacktimer.stop()
    expect(results.subTasks[0].string).is.equal('data')
    expect(results.subTasks[1].number).is.equal(20)
    expect(results.subTasks[1].object.tag).is.equal('data')
    expect(results.subTasks[2].array[0]).is.equal('test')
    expect(results.subTasks[2].more).is.equal('more')

  it 'should add metadata to the root when addRoot is called', ->
    Stacktimer.start(null, null, ->)
    Stacktimer.exec('sync', this, [], ->
      Stacktimer.addRoot('string', 'data')
    )
    Stacktimer.exec('async1', this, [->
      Stacktimer.addRoot('object', { tag: 'data' })
      Stacktimer.exec('async2', this, [->
        Stacktimer.addRoot('more', 'more')
      ], (cb) ->
        Stacktimer.addRoot('array', ['test'])
        cb()
      )
    ], (cb) ->
      Stacktimer.addRoot('number', 20)
      cb()
    )
    results = Stacktimer.stop()
    expect(results.string).is.equal('data')
    expect(results.number).is.equal(20)
    expect(results.object.tag).is.equal('data')
    expect(results.array[0]).is.equal('test')
    expect(results.more).is.equal('more')

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
    stack = Caddy.get(ROOT_KEY)
    expect(stack).to.not.exist
    expect(stub.calledOnce).to.be.true
    expect(stub.calledWith("arg1", "arg2")).to.be.true

  it 'should push onto the stack when exec is called on a sync function', ->
    Stacktimer.start(null, null, ->)
    Stacktimer.exec('subTask', this, [], ->
      trace = Caddy.get(ROOT_KEY).toJSON()
      expect(trace.subTasks[0].task).to.equal("subTask")
    )
    result = Stacktimer.stop()

  it 'should push onto the stack when exec is called on an a sync function with a callback', (done) ->
    Stacktimer.start(null, null, ->)
    Stacktimer.exec('subTask', this, [->
      result = Stacktimer.stop()
      expect(result.task).to.equal("request")
      expect(result.subTasks[0].task).to.equal("subTask")
      done()
    ], (cb) ->
      cb()
    )

  it 'should push onto the stack when exec is called on an an async function', (done) ->
    Stacktimer.start(null, null, ->)
    Stacktimer.exec('subTask', this, [->
      result = Stacktimer.stop()
      expect(result.task).to.equal("request")
      expect(result.subTasks[0].task).to.equal("subTask")
      done()
    ], (cb) ->
      process.nextTick(cb)
    )

  it 'should work when an async callback is called multiple times', (done) ->
    Stacktimer.start(null, null, ->)
    #stack = Caddy.get(STACK_KEY)
    #expect(stack.length).to.equal(1)
    Stacktimer.exec('subTask', this, [(finished) ->
      #expect(stack.length).to.equal(1)
      result = Stacktimer.toJSON()
      expect(result.task).to.equal("request")
      expect(result.subTasks[0].task).to.equal("subTask")
      if finished then done()
    ], (cb) ->
      cb()
      cb(true)
    )

  it 'should create a chain of subTasks when exec is called on sync functions', ->
    Stacktimer.start(null, null, ->)
    Stacktimer.exec('task', this, [], ->
      Stacktimer.exec('subTask', this, [], ->
        Stacktimer.exec('subSubTask', this, [], ->)
      )
      Stacktimer.exec('subTask2', this, [], ->)
    )
    result = Stacktimer.stop()
    expect(result.task).to.equal('request')
    expect(result.subTasks[0].task).to.equal('task')
    expect(result.subTasks[0].end).to.exist
    expect(result.subTasks[0].subTasks[0].task).to.equal('subTask')
    expect(result.subTasks[0].subTasks[0].end).to.exist
    expect(result.subTasks[0].subTasks[0].subTasks[0].task).to.equal('subSubTask')
    expect(result.subTasks[0].subTasks[0].subTasks[0].end).to.exist
    expect(result.subTasks[0].subTasks[1].task).to.equal('subTask2')
    expect(result.subTasks[0].subTasks[1].end).to.exist

  it 'should create a chain of subTasks when exec is called on async functions', ->
    Stacktimer.start(null, null, ->)
    Stacktimer.exec('task', this, [->], (cb) ->
      Stacktimer.exec('subTask', this, [->], (cb) ->
        Stacktimer.exec('subSubTask', this, [->], (cb) ->
          cb()
        )
        cb()
      )
      cb()
      result = Stacktimer.stop()
      expect(result.task).to.equal('request')
      expect(result.subTasks[0].task).to.equal('task')
      expect(result.subTasks[0].end).to.exist
      expect(result.subTasks[0].subTasks[0].task).to.equal('subTask')
      expect(result.subTasks[0].subTasks[0].end).to.exist
      expect(result.subTasks[0].subTasks[0].subTasks[0].task).to.equal('subSubTask')
      expect(result.subTasks[0].subTasks[0].subTasks[0].end).to.exist
    )

  it 'should return a wrapped function when stub is called', ->
    func = ->
      #stack = Caddy.get(STACK_KEY)
      #expect(stack.length).to.equal(2)
      #expect(stack[1].toJSON().task).to.equal("testWrap")
      expect(arguments[0]).to.equal("arg1")
      expect(arguments[1]).to.equal("arg2")
      Stacktimer.stop()
    Stacktimer.start(null, null, ->)
    #stack = Caddy.get(STACK_KEY)
    #expect(stack.length).to.equal(1)
    wrapped = Stacktimer.stub('testWrap', func)
    #expect(stack.length).to.equal(1)
    wrapped("arg1", "arg2")

  it 'should emit start and stop events for sync function calls', (done) ->
    stub = new sinon.stub()
    Stacktimer.on(Stacktimer.START_EVENT, stub)
    Stacktimer.on(Stacktimer.STOP_EVENT, stub)
    Stacktimer.start(null, null, ->)
    Stacktimer.exec('task', this, [], ->)
    Stacktimer.stop()
    process.nextTick(->
      expect(stub.getCall(0).args[0]).is.equal('request')
      expect(stub.getCall(1).args[0]).is.equal('task')
      expect(stub.getCall(2).args[0]).is.equal('task')
      expect(stub.getCall(3).args[0]).is.equal('request')
      expect(stub.callCount).to.equal(4)
      done()
    )

  it 'should emit start and stop events for async function calls', (done) ->
    stub = new sinon.stub()
    Stacktimer.on(Stacktimer.START_EVENT, stub)
    Stacktimer.on(Stacktimer.STOP_EVENT, stub)
    Stacktimer.start(null, null, ->)
    Stacktimer.exec('task', this, [->], (cb) ->
      cb()
    )
    Stacktimer.stop()
    process.nextTick(->
      expect(stub.getCall(0).args[0]).is.equal('request')
      expect(stub.getCall(1).args[0]).is.equal('task')
      expect(stub.getCall(2).args[0]).is.equal('task')
      expect(stub.getCall(3).args[0]).is.equal('request')
      expect(stub.callCount).to.equal(4)
      done()
    )

  it 'should work for the following series: sync -> asyncImmediateCallback', (done) ->
    Stacktimer.start(null, null, ->)
    expect(Caddy.get(CURR_FRAME_KEY).toJSON().task).to.equal('request')
    Stacktimer.exec('sync', this, [], ->
      expect(Caddy.get(CURR_FRAME_KEY).toJSON().task).to.equal('sync')
      Stacktimer.exec('asyncImmediateCallback', this, [->
        expect(Caddy.get(CURR_FRAME_KEY).toJSON().task).to.equal('sync')
      ], (cb) ->
        expect(Caddy.get(CURR_FRAME_KEY).toJSON().task).to.equal('asyncImmediateCallback')
        cb()
      )
      expect(Caddy.get(CURR_FRAME_KEY).toJSON().task).to.equal('sync')
    )
    expect(Caddy.get(CURR_FRAME_KEY).toJSON().task).to.equal('request')
    done()

  it 'should work for the following series: sync -> asyncDelayedCallback', (done) ->
    Stacktimer.start(null, null, ->)
    expect(Caddy.get(CURR_FRAME_KEY).toJSON().task).to.equal('request')
    Stacktimer.exec('sync', this, [], ->
      expect(Caddy.get(CURR_FRAME_KEY).toJSON().task).to.equal('sync')
      Stacktimer.exec('asyncDelayedCallback', this, [->
        expect(Caddy.get(CURR_FRAME_KEY).toJSON().task).to.equal('sync')
        done()
      ], (cb) ->
        expect(Caddy.get(CURR_FRAME_KEY).toJSON().task).to.equal('asyncDelayedCallback')
        process.nextTick(cb)
      )
      expect(Caddy.get(CURR_FRAME_KEY).toJSON().task).to.equal('sync')
    )
    expect(Caddy.get(CURR_FRAME_KEY).toJSON().task).to.equal('request')


