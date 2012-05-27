{Nohm} = require 'nohm'

module.exports = Nohm.model 'Unindexed',
  idGenerator: "increment"
  properties:
    rel:
      type: (value, key, old) ->
        some_words = ['good', 'bad', 'ugly']
        return some_words[Math.round(Math.random() * (some_words.length - 1))]
    rel_id:
      type: 'integer'
      defaultValue: 0
    name:
      type: 'string'
    created_at:
      type: 'timestamp'
      defaultValue: ->
        Math.round(Date.now() / 1000)
