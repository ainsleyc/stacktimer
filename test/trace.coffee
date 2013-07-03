
Trace = require('../dist/trace')
expect = require('chai').expect

describe 'trace.js', ->
  it 'should export the correct api', ->
    trace = new Trace('test')
    expect(trace.start).to.exist
    expect(trace.stop).to.exist
    expect(trace.add).to.exist
    expect(trace.toJSON).to.exist
  it 'should initialize a new root node correctly', ->
    trace = new Trace('test')
    results = trace.toJSON()
    expect(results.task).to.equal('test')
    expect(results.start).to.equal(0)
    expect(results.end).to.not.exist
    expect(results.duration).to.not.exist
    expect(results.subTasks).to.not.exist
  it 'should create a new subtask when start() is called', ->
    trace = new Trace('test')
    subTrace = trace.start('subTest')
    subTrace2 = trace.start('subTest2')
    subSubTrace = subTrace.start('subSubTest')
    results = trace.toJSON()
    expect(results.subTasks.length).to.equal(2)
    expect(results.subTasks[0].task).to.equal('subTest')
    expect(results.subTasks[0].subTasks.length).to.equal(1)
    expect(results.subTasks[0].subTasks[0].task).to.equal('subSubTest')
    expect(results.subTasks[1].task).to.equal('subTest2')
    expect(results.subTasks[1].subTasks).to.not.exist
  it 'should close tasks that have stop() called on them', ->
    trace = new Trace('test')
    subTrace = trace.start('subTest')
    subTrace.stop()
    results = trace.toJSON()
    expect(results.end).to.not.exist
    expect(results.duration).to.not.exist
    expect(results.subTasks[0].end).to.exist
    expect(results.subTasks[0].duration).to.exist
  it 'should add extra data to trace when add() is called', ->
    trace = new Trace('test')
    trace.add('string', 'data')
    trace.add('number', 10)
    trace.add('object', { tag : 'data' })
    results = trace.toJSON()
    expect(results.string).to.equal('data')
    expect(results.number).to.equal(10)
    expect(results.object.tag).to.equal('data')

