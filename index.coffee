BackendApp = require './webapp'

module.exports = (options) ->
  app = new BackendApp options
  app.connect()

