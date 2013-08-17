(function() {
  var ADD_FRAME_KEY, CURR_FRAME_KEY, Caddy, EventEmitter, ROOT_KEY, Stacktimer, Trace, emit, emitter, stub;

  Caddy = require('caddy');

  Trace = require('./trace');

  EventEmitter = require('events').EventEmitter;

  Stacktimer = {};

  emitter = new EventEmitter();

  ROOT_KEY = require('./consts').ROOT_KEY;

  CURR_FRAME_KEY = require('./consts').CURR_FRAME_KEY;

  ADD_FRAME_KEY = require('./consts').ADD_FRAME_KEY;

  Stacktimer.START_EVENT = "STACKTIMER_START";

  Stacktimer.STOP_EVENT = "STACKTIMER_STOP";

  Stacktimer.start = function(req, res, next) {
    var stack;
    Caddy.start();
    stack = new Trace('request');
    Caddy.set(ROOT_KEY, stack);
    Caddy.set(CURR_FRAME_KEY, stack);
    Caddy.set(ADD_FRAME_KEY, null);
    emit(Stacktimer.START_EVENT, 'request');
    next();
  };

  Stacktimer.stop = function() {
    var stack;
    stack = Caddy.get(ROOT_KEY);
    Caddy.set(ROOT_KEY, void 0);
    Caddy.set(CURR_FRAME_KEY, void 0);
    Caddy.set(ADD_FRAME_KEY, void 0);
    if (stack) {
      emit(Stacktimer.STOP_EVENT, 'request');
      stack.stop();
      return stack.toJSON();
    } else {
      return null;
    }
  };

  Stacktimer.stub = function(tag, fn) {
    if (typeof fn !== 'function') {
      throw new Error("typeof(fn) !== 'function'");
    }
    if (!tag) {
      throw new Error("provided tag does not exist");
    }
    return function() {
      var args;
      args = Array.prototype.slice.call(arguments);
      return Stacktimer.exec(tag, this, args, fn);
    };
  };

  Stacktimer.add = function(key, data) {
    var frame;
    frame = Caddy.get(ADD_FRAME_KEY);
    if (frame == null) {
      frame = Caddy.get(CURR_FRAME_KEY);
    }
    if (frame) {
      frame.add(key, data);
    }
  };

  Stacktimer.addRoot = function(key, data) {
    var frame;
    frame = Caddy.get(ROOT_KEY);
    if (frame) {
      frame.add(key, data);
    }
  };

  Stacktimer.on = function(event, cb) {
    if (event === Stacktimer.START_EVENT || event === Stacktimer.STOP_EVENT) {
      emitter.on(event, cb);
    }
  };

  Stacktimer.toJSON = function() {
    var stack;
    stack = Caddy.get(ROOT_KEY);
    if (stack) {
      return stack.toJSON();
    }
  };

  Stacktimer.exec = function(tag, thisArg, args, fn) {
    var argCount, callback, currFrame, prevFrame, stack, stoppedFlag;
    if (typeof fn !== 'function') {
      throw new Error("typeof(fn) !== 'function'");
    }
    if (!Array.isArray(args)) {
      throw new Error("provided args is not an array");
    }
    if (!tag) {
      throw new Error("provided tag does not exist");
    }
    stack = Caddy.get(ROOT_KEY);
    if (!stack) {
      fn.apply(thisArg != null ? thisArg : this, args);
      return;
    }
    prevFrame = Caddy.get(CURR_FRAME_KEY);
    currFrame = prevFrame.start(tag);
    Caddy.set(CURR_FRAME_KEY, currFrame);
    Caddy.set(ADD_FRAME_KEY, null);
    argCount = args.length;
    if (argCount > 0 && typeof args[argCount - 1] === 'function') {
      stoppedFlag = false;
      callback = args[argCount - 1];
      args[argCount - 1] = function() {
        currFrame.stop();
        Caddy.set(CURR_FRAME_KEY, prevFrame);
        Caddy.set(ADD_FRAME_KEY, currFrame);
        emit(Stacktimer.STOP_EVENT, tag);
        callback.apply(this, Array.prototype.slice.call(arguments));
        return Caddy.set(ADD_FRAME_KEY, null);
      };
      emit(Stacktimer.START_EVENT, tag);
      fn.apply(thisArg != null ? thisArg : this, args);
      Caddy.set(CURR_FRAME_KEY, prevFrame);
      Caddy.set(ADD_FRAME_KEY, null);
    } else {
      emit(Stacktimer.START_EVENT, tag);
      fn.apply(thisArg != null ? thisArg : this, args);
      emit(Stacktimer.STOP_EVENT, tag);
      currFrame.stop();
      Caddy.set(CURR_FRAME_KEY, prevFrame);
    }
  };

  stub = function(tag, fn, atomic) {};

  emit = function(event, tag) {
    return process.nextTick(function() {
      return emitter.emit(event, tag);
    });
  };

  module.exports = Stacktimer;

}).call(this);
