(function() {
  var CURR_FRAME_KEY, Caddy, EventEmitter, wrap, _addListener, _nextTick, _on, _once, _removeListener, _setInterval, _setTimeout;

  Caddy = require('caddy');

  EventEmitter = require('events').EventEmitter;

  CURR_FRAME_KEY = require('./consts').CURR_FRAME_KEY;

  wrap = function(callback) {
    var frame, savedFrame;
    frame = Caddy.get(CURR_FRAME_KEY);
    if (frame) {
      savedFrame = frame;
    }
    return function() {
      if (savedFrame) {
        Caddy.set(CURR_FRAME_KEY, savedFrame);
      }
      return callback.apply(this, arguments);
    };
  };

  _nextTick = process.nextTick;

  process.nextTick = function(callback) {
    var args;
    args = Array.prototype.slice.call(arguments);
    args[0] = wrap(callback);
    return _nextTick.apply(this, args);
  };

  _setTimeout = global.setTimeout;

  global.setTimeout = function(callback) {
    var args;
    args = Array.prototype.slice.call(arguments);
    args[0] = wrap(callback);
    return _setTimeout.apply(this, args);
  };

  _setInterval = global.setInterval;

  global.setInterval = function(callback) {
    var args;
    args = Array.prototype.slice.call(arguments);
    args[0] = wrap(callback);
    return _setInterval.apply(this, args);
  };

  _on = EventEmitter.prototype.on;

  EventEmitter.prototype.on = function(event, callback) {
    var args, listeners;
    args = Array.prototype.slice.call(arguments);
    args[1] = wrap(callback);
    _on.apply(this, args);
    listeners = this.listeners(event);
    listeners[listeners.length - 1]._origCallback = callback;
    return this;
  };

  _addListener = EventEmitter.prototype.addListener;

  EventEmitter.prototype.addListener = function(event, callback) {
    var args, listeners;
    args = Array.prototype.slice.call(arguments);
    args[1] = wrap(callback);
    _addListener.apply(this, args);
    listeners = this.listeners(event);
    listeners[listeners.length - 1]._origCallback = callback;
    return this;
  };

  _once = EventEmitter.prototype.once;

  EventEmitter.prototype.once = function(event, callback) {
    var args, listeners;
    args = Array.prototype.slice.call(arguments);
    args[1] = wrap(callback);
    args[1]._origCallback = callback;
    _once.apply(this, args);
    listeners = this.listeners(event);
    listeners[listeners.length - 1]._origCallback = callback;
    return this;
  };

  _removeListener = EventEmitter.prototype.removeListener;

  EventEmitter.prototype.removeListener = function(event, callback) {
    var args, called, listener, _i, _len, _ref;
    args = Array.prototype.slice.call(arguments);
    called = false;
    _ref = this.listeners(event);
    for (_i = 0, _len = _ref.length; _i < _len; _i++) {
      listener = _ref[_i];
      if ((listener != null ? listener._origCallback : void 0) === callback) {
        called = true;
        args[1] = listener;
        _removeListener.apply(this, args);
        break;
      }
    }
    if (!called) {
      _removeListener.apply(this, args);
    }
    return this;
  };

}).call(this);
