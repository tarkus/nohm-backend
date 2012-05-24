fs = require 'fs'
path = require 'path'
{Nohm} = require 'nohm'
helper = require './helper'

isObject = (v) ->
  return Object.prototype.toString.call(v) is '[object Object]' or \
         Object.prototype.toString.call(v) is '[object Function]'

isArray = (v) ->
  return if Object.prototype.toString.call(v) is '[object Array]'

class NohmInstance

  conf:
    login:
      user: 'admin'
      password: 'nohm'
    redis:
      host: 'localhost'
      port: '6379'
      auth: null
    prefix: "nihil"
    models: []

  models: []

  config: (name, value) ->
    unless value?
      return if @conf.name? then @conf.name else null

    @conf.name = value
    @setupNohm()
    @conf

  setupNohm: ->
    models = []
    unless isArray(@conf.models)
      @conf.models = [@conf.models]

    for v in @conf.models
      if isObject(v)
        models.push v
        continue

      if module.parent?
        v = path.dirname(module.parent.filename) + "/" + v

      try
        models.push require(v)
      catch e
        try
          fs.readdirSync(v).forEach (file) ->
            models.push require(v + "/" + file)
        catch e
          console.log e

    Nohm.setClient helper.connectRedis @conf.redis
    Nohm.setPrefix @conf.prefix
    @models = Nohm.getModels()

  constructor: (options) ->
    @conf = if options? then @conf extends options
    @setupNohm()

module.exports = NohmInstance
