(function() {
  var Caddy, STACK_KEY, Stacktimer, Trace;

  require('./wrappers');

  Caddy = require('caddy');

  Trace = require('./trace');

  Stacktimer = {};

  STACK_KEY = require('./consts').STACK_KEY;

  Stacktimer.start = function(req, res, next) {
    var stack;
    Caddy.start();
    stack = [new Trace('request')];
    Caddy.set(STACK_KEY, stack);
    next();
  };

  Stacktimer.stop = function() {
    var stack;
    stack = Caddy.get(STACK_KEY);
    Caddy.set(STACK_KEY, void 0);
    if (stack) {
      stack[0].stop();
      return stack[0].toJSON();
    }
  };

  Stacktimer.stub = function(tag, thisArg, fn) {
    if (typeof fn !== 'function') {
      throw new Error("typeof(fn) !== 'function'");
    }
    if (!tag) {
      throw new Error("provided tag does not exist");
    }
    return function() {
      var args;
      args = Array.prototype.slice.call(arguments);
      return Stacktimer.exec(tag, thisArg, args, fn);
    };
  };

  Stacktimer.exec = function(tag, thisArg, args, fn) {
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
    argCount = args.length;
    stack.push(trace);
    if (argCount > 0 && typeof args[argCount - 1] === 'function') {
      callback = args[argCount - 1];
      args[argCount - 1] = function() {
        trace.stop();
        return callback.apply(this, Array.prototype.slice.call(arguments));
      };
      fn.apply(thisArg != null ? thisArg : this, args);
      stack.pop();
    } else {
      fn.apply(thisArg != null ? thisArg : this, args);
      trace.stop();
      stack.pop();
    }
  };

  Stacktimer.add = function(key, data) {
    var stack;
    stack = Caddy.get(STACK_KEY);
    if (stack) {
      stack[stack.length - 1].add(key, data);
    }
  };

  Stacktimer.toJSON = function() {
    var stack;
    stack = Caddy.get(STACK_KEY);
    if (stack) {
      return stack[0].toJSON();
    }
  };

  module.exports = Stacktimer;

}).call(this);
