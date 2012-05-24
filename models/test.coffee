{Nohm} = require 'nohm'

module.exports = Nohm.model 'Tag',
  idGenerator: 'increment'
  properties:
    rel:
      type: 'string'
    rel_id:
      type: 'integer'
    name:
      type: 'string'
