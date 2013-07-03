
Caddy = require('caddy')
EventEmitter = require('events').EventEmitter
STACK_KEY = require('./consts').STACK_KEY

wrap = (callback) ->
  stack = Caddy.get(STACK_KEY)
  if stack
    savedTrace = stack[stack.length-1]
  ->
    stack = Caddy.get(STACK_KEY)
    if stack and savedTrace and savedTrace.end?
      for frame in stack
        if frame is savedTrace
          found = true
      if not found
        stack.push(savedTrace)
    callback.apply(this, arguments)

_nextTick = process.nextTick
process.nextTick = (callback) ->
  args = Array::slice.call(arguments)
  args[0] = wrap(callback)
  _nextTick.apply(this, args)

_setTimeout = global.setTimeout
global.setTimeout = (callback) ->
  args = Array::slice.call(arguments)
  args[0] = wrap(callback)
  _setTimeout.apply(this, args)

_setInterval = global.setInterval
global.setInterval = (callback) ->
  args = Array::slice.call(arguments)
  args[0] = wrap(callback)
  _setInterval.apply(this, args)

_on = EventEmitter.prototype.on
EventEmitter.prototype.on = (event, callback) ->
  args = Array::slice.call(arguments)
  args[1] = wrap(callback)
  args[1]._origCallback = callback
  _on.apply(this, args)

_addListener = EventEmitter.prototype.addListener
EventEmitter.prototype.addListener = (event, callback) ->
  args = Array::slice.call(arguments)
  args[1] = wrap(callback)
  args[1]._origCallback = callback
  _addListener.apply(this, args)

_once = EventEmitter.prototype.once
EventEmitter.prototype.once = (event, callback) ->
  args = Array::slice.call(arguments)
  args[1] = wrap(callback)
  args[1]._origCallback = callback
  _once.apply(this, args)

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

