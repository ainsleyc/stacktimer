
Caddy = require('caddy')
Trace = require('./trace')
EventEmitter = require('events').EventEmitter

Stacktimer = {}
emitter = new EventEmitter()

ROOT_KEY = require('./consts').ROOT_KEY
CURR_FRAME_KEY = require('./consts').CURR_FRAME_KEY
ADD_FRAME_KEY = require('./consts').ADD_FRAME_KEY

Stacktimer.START_EVENT = "STACKTIMER_START"
Stacktimer.STOP_EVENT = "STACKTIMER_STOP"

Stacktimer.start = (req, res, next) ->
  Caddy.start()
  stack = new Trace('request')
  Caddy.set(ROOT_KEY, stack)
  Caddy.set(CURR_FRAME_KEY, stack)
  Caddy.set(ADD_FRAME_KEY, null)
  emit(Stacktimer.START_EVENT, 'request')
  next()
  return

Stacktimer.stop = () ->
  stack = Caddy.get(ROOT_KEY)
  Caddy.set(ROOT_KEY, undefined)
  Caddy.set(CURR_FRAME_KEY, undefined)
  Caddy.set(ADD_FRAME_KEY, undefined)
  if stack
    emit(Stacktimer.STOP_EVENT, 'request')
    stack.stop()
    return stack.toJSON()
  else
    return null

Stacktimer.stub = (tag, fn) ->
  if typeof(fn) isnt 'function'
    throw new Error("typeof(fn) !== 'function'")
  if not tag
    throw new Error("provided tag does not exist")

  return ->
    args = Array::slice.call(arguments)
    Stacktimer.exec(tag, this, args, fn)

Stacktimer.add = (key, data) ->
  frame = Caddy.get(ADD_FRAME_KEY)
  if not frame?
    frame = Caddy.get(CURR_FRAME_KEY)
  if frame
    frame.add(key, data)
  return

Stacktimer.addRoot = (key, data) ->
  frame = Caddy.get(ROOT_KEY)
  if frame
    frame.add(key, data)
  return

Stacktimer.on = (event, cb) ->
  if event is Stacktimer.START_EVENT or event is Stacktimer.STOP_EVENT
    emitter.on(event, cb)
  return

Stacktimer.toJSON = ->
  stack = Caddy.get(ROOT_KEY)
  if stack
    return stack.toJSON()

Stacktimer.exec = (tag, thisArg, args, fn) ->
  if typeof(fn) isnt 'function'
    throw new Error("typeof(fn) !== 'function'")
  if not Array.isArray(args)
    throw new Error("provided args is not an array")
  if not tag
    throw new Error("provided tag does not exist")

  stack = Caddy.get(ROOT_KEY)
  if not stack
    fn.apply(thisArg ? this, args)
    return
  prevFrame = Caddy.get(CURR_FRAME_KEY)
  currFrame = prevFrame.start(tag)
  Caddy.set(CURR_FRAME_KEY, currFrame)
  Caddy.set(ADD_FRAME_KEY, null)
  argCount = args.length
  if argCount > 0 and typeof(args[argCount-1]) is 'function'
    # If a function is provided then provide a wrapped callback
    stoppedFlag = false
    callback = args[argCount-1]
    args[argCount-1] = ->
      # Reset the previous frame when the callback has been called
      currFrame.stop()
      Caddy.set(CURR_FRAME_KEY, prevFrame)
      Caddy.set(ADD_FRAME_KEY, currFrame)
      emit(Stacktimer.STOP_EVENT, tag)
      callback.apply(this, Array::slice.call(arguments))
      Caddy.set(ADD_FRAME_KEY, null)
    emit(Stacktimer.START_EVENT, tag)
    fn.apply(thisArg ? this, args)
    # Reset the previous frame when the functionca call has completed
    Caddy.set(CURR_FRAME_KEY, prevFrame)
    Caddy.set(ADD_FRAME_KEY, null)
  else
    # If a function is not provided, assume it is a sync function and just execute
    emit(Stacktimer.START_EVENT, tag)
    fn.apply(thisArg ? this, args)
    emit(Stacktimer.STOP_EVENT, tag)
    currFrame.stop()
    Caddy.set(CURR_FRAME_KEY, prevFrame)
  return

stub = (tag, fn, atomic) ->
emit = (event, tag) ->
  process.nextTick(->
    emitter.emit(event, tag)
  )

module.exports = Stacktimer

