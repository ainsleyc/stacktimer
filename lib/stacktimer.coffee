
require('./wrappers')
Caddy = require('caddy')
Trace = require('./trace')

Stacktimer = {}

STACK_KEY = require('./consts').STACK_KEY

Stacktimer.start = (req, res, next) ->
  Caddy.start()
  stack = [new Trace('request')]
  Caddy.set(STACK_KEY, stack)
  next()
  return

Stacktimer.stop = () ->
  stack = Caddy.get(STACK_KEY)
  Caddy.set(STACK_KEY, undefined)
  if stack
    stack[0].stop()
    return stack[0].toJSON()

Stacktimer.stub = (tag, thisArg, fn) ->
  if typeof(fn) isnt 'function'
    throw new Error("typeof(fn) !== 'function'")
  if not tag
    throw new Error("provided tag does not exist")

  return ->
    args = Array.slice.call(arguments)
    Stacktimer.exec(tag, thisArg, args, fn)

Stacktimer.exec = (tag, thisArg, args, fn) ->
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
  trace = new Trace(tag)
  stack.push(trace)
  fn.apply(thisArg ? this, args)
  stack.pop()
  return

Stacktimer.add = (key, data) ->
  stack = Caddy.get(STACK_KEY)
  if stack
    stack[stack.length-1].add(key, data)
  return

Stacktimer.toJSON = ->
  stack = Caddy.get(STACK_KEY)
  if stack
    return stack[0].toJSON()

module.exports = Stacktimer

