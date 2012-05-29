should = require 'should'
{Nohm} = require 'nohm'
NohmInstance = require '../lib/nohm-instance'
instance = new NohmInstance models: [
  "test_model"
]


describe "Test 'Check Index' functionality", ->

  alist = ['less', 'is', 'more', 'than', 'this']

  describe 'Insert some ids', ->

    it 'clear', (done) ->
      redis_client = instance.getRedisClient()
      redis_client.keys instance.get('prefix') + ':*', (err, keys) ->
        return done() if not keys or keys.length == 0
        len = keys.length
        k = 0
        cb = (key) ->
          k = k + 1
          done() if k == len
        for key in keys
          redis_client.del(key, cb(key))

    it 'should have 3 ids', (done) ->
      counter = 0
      for i in [0..2]
        t = instance.getModel('Unindexed')
        t.properties.rel.index = false
        t.properties.rel_id.index = false
        t.properties.name.unique = false
        t.properties.created_at.index = false
        t.p 'rel', 'nevermind'
        t.p 'rel_id', (i + 1) * 10
        t.p 'name', alist[i]
        t.save (err) ->
          counter++
          done() if counter == 3

  describe 'change the model definition, and add more ids', ->
    it 'add more data', (done) ->
      counter = 0
      for i in [3..4]
        t = instance.getModel('Unindexed')
        t.p 'rel', 'nevermind'
        t.p 'rel_id', (i + 1) * 10
        t.p 'name', alist[i]
        t.save (err) ->
          counter++
          done() if counter == 2

  describe 'the indices of the model should be out-of-sync now', ->
    it 'can find ids after we index on name property', (done) ->
      t = instance.getModel('Unindexed')
      t.find name: alist[4], (err, ids) ->
        ids.length.should.be.eql 1
        done()

    it 'cannot find ids before we index on name property', (done) ->
      t = instance.getModel('Unindexed')
      t.find name: alist[2], (err, ids) ->
        ids.length.should.be.eql 0
        done()

  describe 'then use nohm-instance to check index on the model', ->
    
    it 'the indices should be OK now', (done) ->
      instance.checkIndex 'Unindexed', (report) ->
        t = instance.getModel('Unindexed')
        t.find name: alist[1], (err, ids) ->
          ids.length.should.be.eql 1
          done()

