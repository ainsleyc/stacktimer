
require('./wrappers')
Caddy = require('caddy')
Trace = require('./trace')
EventEmitter = require('events').EventEmitter

Stacktimer = {}
emitter = new EventEmitter()

STACK_KEY = require('./consts').STACK_KEY
CURR_FRAME_KEY = require('./consts').CURR_FRAME_KEY

Stacktimer.START_EVENT = "STACKTIMER_START"
Stacktimer.STOP_EVENT = "STACKTIMER_STOP"

Stacktimer.start = (req, res, next) ->
  Caddy.start()
  stack = [new Trace('request')]
  Caddy.set(STACK_KEY, stack)
  Caddy.set(CURR_FRAME_KEY, stack[0])
  emit(Stacktimer.START_EVENT, 'request')
  next()
  return

Stacktimer.stop = () ->
  stack = Caddy.get(STACK_KEY)
  Caddy.set(STACK_KEY, undefined)
  if stack and stack[0]
    emit(Stacktimer.STOP_EVENT, 'request')
    stack[0].stop()
    return stack[0].toJSON()
  else
    return null

Stacktimer.stub = (tag, fn) ->
  stub(tag, fn, true)

Stacktimer.exec = (tag, thisArg, args, fn) ->
  exec(tag, thisArg, args, fn, true)

Stacktimer.stubs = (tag, fn) ->
  stub(tag, fn, false)

Stacktimer.execs = (tag, thisArg, args, fn) ->
  exec(tag, thisArg, args, fn, false)

Stacktimer.add = (key, data) ->
  frame = Caddy.get(CURR_FRAME_KEY)
  if frame
    frame.add(key, data)
  return

Stacktimer.on = (event, cb) ->
  if event is Stacktimer.START_EVENT or event is Stacktimer.STOP_EVENT
    emitter.on(event, cb)
  return

Stacktimer.toJSON = ->
  stack = Caddy.get(STACK_KEY)
  if stack
    return stack[0].toJSON()

exec = (tag, thisArg, args, fn, atomic) ->
  if typeof(fn) isnt 'function'
    throw new Error("typeof(fn) !== 'function'")
  if not Array.isArray(args)
    throw new Error("provided args is not an array")
  if not tag
    throw new Error("provided tag does not exist")

  stack = Caddy.get(STACK_KEY)
  if not stack
    fn.apply(thisArg ? this, args)
    return
  trace = stack[stack.length-1].start(tag)
  Caddy.set(CURR_FRAME_KEY, trace)
  argCount = args.length
  if not atomic then stack.push(trace)
  if argCount > 0 and typeof(args[argCount-1]) is 'function'
    stoppedFlag = false
    callback = args[argCount-1]
    args[argCount-1] = ->
      trace.stop()
      if not atomic and not stoppedFlag then stack.pop()
      stoppedFlag = true
      Caddy.set(CURR_FRAME_KEY, stack[stack.length-1])
      Caddy.set(STACK_KEY, stack)
      emit(Stacktimer.STOP_EVENT, tag)
      callback.apply(this, Array::slice.call(arguments))
    emit(Stacktimer.START_EVENT, tag)
    fn.apply(thisArg ? this, args)
  else
    emit(Stacktimer.START_EVENT, tag)
    fn.apply(thisArg ? this, args)
    emit(Stacktimer.STOP_EVENT, tag)
    trace.stop()
    if not atomic then stack.pop()
    Caddy.set(CURR_FRAME_KEY, stack[stack.length-1])
    Caddy.set(STACK_KEY, stack)
  return

stub = (tag, fn, atomic) ->
  if typeof(fn) isnt 'function'
    throw new Error("typeof(fn) !== 'function'")
  if not tag
    throw new Error("provided tag does not exist")

  return ->
    args = Array::slice.call(arguments)
    exec(tag, this, args, fn, atomic)

emit = (event, tag) ->
  process.nextTick(->
    emitter.emit(event, tag)
  )

module.exports = Stacktimer

