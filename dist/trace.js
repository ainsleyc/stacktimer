(function() {
  var TraceBlock;

  module.exports = function(task) {
    var rootBlock, self;
    self = this;
    rootBlock = new TraceBlock(task, null);
    self.start = rootBlock.start;
    self.stop = rootBlock.stop;
    self.add = rootBlock.add;
    self.toJSON = rootBlock.toJSON;
  };

  TraceBlock = function(task, root) {
    var self;
    self = this;
    self.root = root || self;
    self.TraceBlock = self;
    self.subTasks = [];
    self.task = task;
    self.startTime = Date.now();
    self.meta = {};
    self.start = function(task) {
      var newTask;
      newTask = new self.constructor(task, self.root);
      self.subTasks.push(newTask);
      return newTask;
    };
    self.stop = function(meta) {
      if (!self.endTime) {
        return self.endTime = Date.now();
      }
    };
    self.add = function(tag, data) {
      return self.meta[tag] = data;
    };
    self.toJSON = function() {
      var data, key, result, _i, _len, _ref, _ref1;
      result = {
        task: self.task,
        start: self.root.startTime - self.startTime,
        end: self.endTime != null ? self.root.startTime - self.endTime : void 0,
        duration: self.endTime != null ? self.endTime - self.startTime : void 0
      };
      if (self.subTasks.length > 0) {
        result.subTasks = [];
        _ref = self.subTasks;
        for (_i = 0, _len = _ref.length; _i < _len; _i++) {
          task = _ref[_i];
          result.subTasks.push(task.toJSON());
        }
      }
      _ref1 = self.meta;
      for (key in _ref1) {
        data = _ref1[key];
        if (!result[key]) {
          result[key] = data;
        }
      }
      return result;
    };
  };

}).call(this);
