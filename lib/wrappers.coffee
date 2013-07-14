
Caddy = require('caddy')
EventEmitter = require('events').EventEmitter
CURR_FRAME_KEY = require('./consts').CURR_FRAME_KEY

wrap = (once, event, callback) ->
  frame = Caddy.get(CURR_FRAME_KEY)
  if frame
    savedFrame = frame
  ->
    if savedFrame
      Caddy.set(CURR_FRAME_KEY, savedFrame)
    if once
      this.removeListener(event, callback)
    callback.apply(this, arguments)

_nextTick = process.nextTick
process.nextTick = (callback) ->
  args = Array::slice.call(arguments)
  args[0] = wrap(false, null, callback)
  _nextTick.apply(this, args)

_setTimeout = global.setTimeout
global.setTimeout = (callback) ->
  args = Array::slice.call(arguments)
  args[0] = wrap(false, null, callback)
  _setTimeout.apply(this, args)

_setInterval = global.setInterval
global.setInterval = (callback) ->
  args = Array::slice.call(arguments)
  args[0] = wrap(false, null, callback)
  _setInterval.apply(this, args)

_on = EventEmitter.prototype.on
EventEmitter.prototype.on = (event, callback) ->
  args = Array::slice.call(arguments)
  args[1] = wrap(false, event, callback)
  _on.apply(this, args)
  listeners = this.listeners(event)
  listeners[listeners.length-1]._origCallback = callback
  return this

_addListener = EventEmitter.prototype.addListener
EventEmitter.prototype.addListener = (event, callback) ->
  args = Array::slice.call(arguments)
  args[1] = wrap(false, null, callback)
  _addListener.apply(this, args)
  listeners = this.listeners(event)
  listeners[listeners.length-1]._origCallback = callback
  return this

_once = EventEmitter.prototype.once
EventEmitter.prototype.once = (event, callback) ->
  args = Array::slice.call(arguments)
  args[1] = wrap(true, event, callback)
  args[1]._origCallback = callback
  _once.apply(this, args)
  listeners = this.listeners(event)
  listeners[listeners.length-1]._origCallback = callback
  return this

_removeListener = EventEmitter.prototype.removeListener
EventEmitter.prototype.removeListener = (event, callback) ->
  args = Array::slice.call(arguments)
  called = false
  for listener in this.listeners(event)
    if listener?._origCallback is callback
      called = true
      args[1] = listener
      _removeListener.apply(this, args)
      break
  if not called
    _removeListener.apply(this, args)
  return this

