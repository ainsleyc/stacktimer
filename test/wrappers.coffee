
expect = require('chai').expect
require('../dist/wrappers')
Caddy = require('caddy')
EventEmitter = require('events').EventEmitter
STACK_KEY = require('../dist/consts').STACK_KEY

describe 'wrappers.js', ->
  beforeEach ->
    Caddy.set('STACK_KEY', [{ task : 'data' }, { end : 0 }])

  afterEach ->
    Caddy.set('STACK_KEY', undefined)

  it 'should save caddy stack for nextTick()', (done) ->
    stack = Caddy.get('STACK_KEY')
    process.nextTick(->
      expect(stack.length).to.equal(2)
      expect(stack[1].end).to.equal(0)
      done()
    )
    stack.pop()
    expect(stack.length).to.equal(1)

  it 'should save caddy stack for setTimeout()', (done) ->
    stack = Caddy.get('STACK_KEY')
    setTimeout(->
      expect(stack.length).to.equal(2)
      expect(stack[1].end).to.equal(0)
      done()
    , 100)
    stack.pop()
    expect(stack.length).to.equal(1)

  it 'should save caddy stack for setInterval()', (done) ->
    stack = Caddy.get('STACK_KEY')
    intervalId = setInterval(->
      expect(stack.length).to.equal(2)
      expect(stack[1].end).to.equal(0)
      clearInterval(intervalId)
      done()
    , 100)
    stack.pop()
    expect(stack.length).to.equal(1)

  it 'should save caddy stack for EventEmitter.on', (done) ->
    emitter = new EventEmitter()
    stack = Caddy.get('STACK_KEY')
    emitter.on('test', ->
      expect(stack.length).to.equal(2)
      expect(stack[1].end).to.equal(0)
      done()
    )
    stack.pop()
    expect(stack.length).to.equal(1)
    emitter.emit('test')

  it 'should save caddy stack for EventEmitter.addListener', (done) ->
    emitter = new EventEmitter()
    stack = Caddy.get('STACK_KEY')
    emitter.addListener('test', ->
      expect(stack.length).to.equal(2)
      expect(stack[1].end).to.equal(0)
      done()
    )
    stack.pop()
    expect(stack.length).to.equal(1)
    emitter.emit('test')

  it 'should save caddy stack for EventEmitter.once', (done) ->
    emitter = new EventEmitter()
    stack = Caddy.get('STACK_KEY')
    emitter.once('test', ->
      expect(stack.length).to.equal(2)
      expect(stack[1].end).to.equal(0)
      done()
    )
    stack.pop()
    expect(stack.length).to.equal(1)
    emitter.emit('test')

