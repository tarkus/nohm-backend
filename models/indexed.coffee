{Nohm} = require 'nohm'

module.exports = Nohm.model 'Indexed',
  idGenerator: "increment"
  properties:
    rel:
      type: (value, key, old) ->
        some_words = ['good', 'bad', 'ugly']
        return some_words[Math.round(Math.random() * (some_words.length - 1))]
      index: true
    rel_id:
      type: 'integer'
      defaultValue: 0
      index: true
    name:
      type: 'string'
      unique: true
    created_at:
      type: 'timestamp'
      defaultValue: ->
        Math.round(Date.now() / 1000)
      index: true
