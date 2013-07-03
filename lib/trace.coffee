
module.exports = (task) ->
  self = this
  rootBlock = new TraceBlock(task, null)
  self.start = rootBlock.start
  self.stop = rootBlock.stop
  self.add = rootBlock.add
  self.toJSON = rootBlock.toJSON
  return

TraceBlock = (task, root) ->
  self = this
  self.root = root || self
  self.TraceBlock = self
  self.subTasks = []
  self.task = task
  self.startTime = Date.now()
  self.meta = {}

  self.start = (task) ->
    newTask = new self.constructor(task, self.root)
    self.subTasks.push(newTask)
    return newTask

  self.stop = (meta) ->
    if not self.endTime
      self.endTime = Date.now()

  self.add = (tag, data) ->
    self.meta[tag] = data

  self.toJSON = ->
    result = {
      task: self.task
      start: self.startTime - self.root.startTime
      end: self.endTime - self.root.startTime if self.endTime?
      duration: self.endTime - self.startTime if self.endTime?
    }
    if self.subTasks.length > 0
      result.subTasks = []
      for task in self.subTasks
        result.subTasks.push(task.toJSON())
    for key, data of self.meta
      if not result[key]
        result[key] = data
    result
  return


