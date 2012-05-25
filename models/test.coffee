{Nohm} = require 'nohm'

module.exports = Nohm.model 'Tag',
  idGenerator: () ->
    ""
  properties:
    rel:
      type: 'string'
    rel_id:
      type: 'integer'
      index: true
      defaultValue: 0
    name:
      type: 'string'
      unique: true
    test:
      type: () ->
      index: true
      defaultValue: () ->
        new Date()
