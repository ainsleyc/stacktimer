
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

