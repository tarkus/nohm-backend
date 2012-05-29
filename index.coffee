NohmBackendApp = require './app'

module.exports = (options) ->
  app = new NohmBackendApp options
  app.connect()

