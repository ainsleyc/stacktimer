
expect = require('chai').expect
require('../dist/wrappers')
Caddy = require('caddy')
EventEmitter = require('events').EventEmitter
CURR_FRAME_KEY = require('../dist/consts').CURR_FRAME_KEY

describe 'wrappers.js', ->
  beforeEach ->
    Caddy.set('CURR_FRAME_KEY', 'data')

  afterEach ->
    Caddy.set('CURR_FRAME_KEY', undefined)

  it 'should save caddy stack for nextTick()', (done) ->
    process.nextTick(->
      expect(Caddy.get('CURR_FRAME_KEY')).to.equal('data');
      done()
    )
    Caddy.set('CURR_FRAME_KEY', undefined)
    expect(Caddy.get('CURR_FRAME_KEY')).to.not.exist

  it 'should save caddy stack for _nextDomainTick()', (done) ->
    process._nextDomainTick(->
      expect(Caddy.get('CURR_FRAME_KEY')).to.equal('data');
      done()
    )
    Caddy.set('CURR_FRAME_KEY', undefined)
    expect(Caddy.get('CURR_FRAME_KEY')).to.not.exist

  it 'should save caddy stack for setTimeout()', (done) ->
    setTimeout(->
      expect(Caddy.get('CURR_FRAME_KEY')).to.equal('data');
      done()
    , 100)
    Caddy.set('CURR_FRAME_KEY', undefined)
    expect(Caddy.get('CURR_FRAME_KEY')).to.not.exist

  it 'should save caddy stack for setInterval()', (done) ->
    intervalId = setInterval(->
      clearInterval(intervalId)
      expect(Caddy.get('CURR_FRAME_KEY')).to.equal('data');
      done()
    )
    Caddy.set('CURR_FRAME_KEY', undefined)
    expect(Caddy.get('CURR_FRAME_KEY')).to.not.exist

  it 'should save caddy stack for setImmediate()', (done) ->
    setImmediate(->
      expect(Caddy.get('CURR_FRAME_KEY')).to.equal('data');
      done()
    )
    Caddy.set('CURR_FRAME_KEY', undefined)
    expect(Caddy.get('CURR_FRAME_KEY')).to.not.exist

  it 'should save caddy stack for EventEmitter.on', (done) ->
    emitter = new EventEmitter()
    emitter.on('test', ->
      expect(Caddy.get('CURR_FRAME_KEY')).to.equal('data');
      done()
    , 100)
    Caddy.set('CURR_FRAME_KEY', undefined)
    expect(Caddy.get('CURR_FRAME_KEY')).to.not.exist
    emitter.emit('test')

  it 'should save caddy stack for EventEmitter.addListener', (done) ->
    emitter = new EventEmitter()
    emitter.addListener('test', ->
      expect(Caddy.get('CURR_FRAME_KEY')).to.equal('data');
      done()
    , 100)
    Caddy.set('CURR_FRAME_KEY', undefined)
    expect(Caddy.get('CURR_FRAME_KEY')).to.not.exist
    emitter.emit('test')

  it 'should save caddy stack for EventEmitter.once', (done) ->
    emitter = new EventEmitter()
    emitter.once('test', ->
      expect(Caddy.get('CURR_FRAME_KEY')).to.equal('data');
      done()
    , 100)
    Caddy.set('CURR_FRAME_KEY', undefined)
    expect(Caddy.get('CURR_FRAME_KEY')).to.not.exist
    emitter.emit('test')

  it 'should remove event handlers correctly', ->
    emitter = new EventEmitter()

    addListener1 = ->
    addListener2 = ->
    expect(emitter.listeners('addListener').length).to.equal(0)
    emitter.addListener('addListener', addListener1)
    emitter.addListener('addListener', addListener2)
    expect(emitter.listeners('addListener').length).to.equal(2)

    once1 = ->
    once2 = ->
    expect(emitter.listeners('once').length).to.equal(0)
    emitter.once('once', once1)
    emitter.once('once', once2)
    expect(emitter.listeners('once').length).to.equal(2)

    on1 = ->
    on2 = ->
    expect(emitter.listeners('on').length).to.equal(0)
    emitter.on('on', on1)
    emitter.on('on', on2)
    expect(emitter.listeners('on').length).to.equal(2)

    emitter.removeListener('addListener', addListener2)
    expect(emitter.listeners('addListener').length).to.equal(1)
    emitter.removeListener('addListener', addListener1)
    expect(emitter.listeners('addListener').length).to.equal(0)

    emitter.removeListener('on', on1)
    expect(emitter.listeners('on').length).to.equal(1)
    emitter.removeListener('on', on2)
    expect(emitter.listeners('on').length).to.equal(0)

    emitter.removeListener('once', once2)
    expect(emitter.listeners('once').length).to.equal(1)
    emitter.removeListener('once', once1)
    expect(emitter.listeners('once').length).to.equal(0)

  it 'should once event handlers should be removed correctly after being emmited', (done) ->
    emitter = new EventEmitter()

    once1 = ->
    once2 = ->
    expect(emitter.listeners('once').length).to.equal(0)
    emitter.once('once', once1)
    emitter.once('once', once1)
    emitter.once('once', once2)
    emitter.once('once2', once1)
    emitter.once('once2', once2)
    expect(emitter.listeners('once').length).to.equal(3)
    expect(emitter.listeners('once2').length).to.equal(2)

    emitter.emit('once')
    process.nextTick(->
      expect(emitter.listeners('once').length).to.equal(0)
      expect(emitter.listeners('once2').length).to.equal(2)
      emitter.emit('once2')
      process.nextTick(->
        expect(emitter.listeners('once').length).to.equal(0)
        expect(emitter.listeners('once2').length).to.equal(0)
        done()
      )
    )

  it 'should return the original callbacks when EventEmitter.listeners() is called', () ->
    emitter = new EventEmitter()
    event1 = ->
      console.log('event1')
    event2 = ->
      console.log('event2')
    event3 = ->
      console.log('event3')
    emitter.on('eventA', event1)
    emitter.on('eventA', event2)
    emitter.on('eventB', event3)
    expect(emitter.listeners('eventA').length).to.equal(2)
    expect(emitter.listeners('eventB').length).to.equal(1)
    expect(emitter.listeners('eventA')[0]).to.equal(event1)
    expect(emitter.listeners('eventA')[1]).to.equal(event2)
    expect(emitter.listeners('eventB')[0]).to.equal(event3)

