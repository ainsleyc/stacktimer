(function() {
  var CURR_FRAME_KEY, Caddy, EventEmitter, STACK_KEY, Stacktimer, Trace, emitter, exec, stub;

  require('./wrappers');

  Caddy = require('caddy');

  Trace = require('./trace');

  EventEmitter = require('events').EventEmitter;

  Stacktimer = {};

  emitter = new EventEmitter();

  STACK_KEY = require('./consts').STACK_KEY;

  CURR_FRAME_KEY = require('./consts').CURR_FRAME_KEY;

  Stacktimer.START_EVENT = "STACKTIMER_START";

  Stacktimer.STOP_EVENT = "STACKTIMER_STOP";

  Stacktimer.start = function(req, res, next) {
    var stack;
    Caddy.start();
    stack = [new Trace('request')];
    Caddy.set(STACK_KEY, stack);
    Caddy.set(CURR_FRAME_KEY, stack[0]);
    emitter.emit(Stacktimer.STACKTIMER_START, 'request');
    next();
  };

  Stacktimer.stop = function() {
    var stack;
    stack = Caddy.get(STACK_KEY);
    Caddy.set(STACK_KEY, void 0);
    if (stack) {
      emitter.emit(Stacktimer.STACKTIMER_STOP, 'request');
      stack[0].stop();
      return stack[0].toJSON();
    }
  };

  Stacktimer.stub = function(tag, fn) {
    return stub(tag, fn, true);
  };

  Stacktimer.exec = function(tag, thisArg, args, fn) {
    return exec(tag, thisArg, args, fn, true);
  };

  Stacktimer.stubs = function(tag, fn) {
    return stub(tag, fn, false);
  };

  Stacktimer.execs = function(tag, thisArg, args, fn) {
    return exec(tag, thisArg, args, fn, false);
  };

  Stacktimer.add = function(key, data) {
    var frame;
    frame = Caddy.get(CURR_FRAME_KEY);
    if (frame) {
      frame.add(key, data);
    }
  };

  Stacktimer.on = function(event, cb) {
    if (event === Stacktimer.STACKTIMER_START || event === Stacktimer.STACKTIMER_STOP) {
      emitter.on(event, cb);
    }
  };

  Stacktimer.toJSON = function() {
    var stack;
    stack = Caddy.get(STACK_KEY);
    if (stack) {
      return stack[0].toJSON();
    }
  };

  exec = function(tag, thisArg, args, fn, atomic) {
    var argCount, callback, stack, trace;
    if (typeof fn !== 'function') {
      throw new Error("typeof(fn) !== 'function'");
    }
    if (!Array.isArray(args)) {
      throw new Error("provided args is not an array");
    }
    if (!tag) {
      throw new Error("provided tag does not exist");
    }
    stack = Caddy.get(STACK_KEY);
    if (!stack) {
      fn.apply(thisArg != null ? thisArg : this, args);
      return;
    }
    trace = stack[stack.length - 1].start(tag);
    Caddy.set(CURR_FRAME_KEY, trace);
    argCount = args.length;
    if (!atomic) {
      stack.push(trace);
    }
    if (argCount > 0 && typeof args[argCount - 1] === 'function') {
      callback = args[argCount - 1];
      args[argCount - 1] = function() {
        trace.stop();
        if (!atomic) {
          stack.pop();
        }
        Caddy.set(CURR_FRAME_KEY, stack[stack.length - 1]);
        emitter.emit(Stacktimer.STACKTIMER_STOP, tag);
        return callback.apply(this, Array.prototype.slice.call(arguments));
      };
      emitter.emit(Stacktimer.STACKTIMER_START, tag);
      fn.apply(thisArg != null ? thisArg : this, args);
    } else {
      emitter.emit(Stacktimer.STACKTIMER_START, tag);
      fn.apply(thisArg != null ? thisArg : this, args);
      emitter.emit(Stacktimer.STACKTIMER_STOP, tag);
      trace.stop();
      if (!atomic) {
        stack.pop();
      }
      Caddy.set(CURR_FRAME_KEY, stack[stack.length - 1]);
    }
  };

  stub = function(tag, fn, atomic) {
    if (typeof fn !== 'function') {
      throw new Error("typeof(fn) !== 'function'");
    }
    if (!tag) {
      throw new Error("provided tag does not exist");
    }
    return function() {
      var args;
      args = Array.prototype.slice.call(arguments);
      return exec(tag, this, args, fn, atomic);
    };
  };

  module.exports = Stacktimer;

}).call(this);
