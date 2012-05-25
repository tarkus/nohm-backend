fs = require 'fs'
path = require 'path'
{Nohm} = require 'nohm'
helper = require './helper'

class NohmInstance

  conf:
    login: (username, password) ->
      return true
    redis:
      host: 'localhost'
      port: '6379'
      auth: null
    prefix: "nihil"
    models: []

  models: []

  get: () ->
    c = @conf
    for arg in arguments
      return null unless c[arg]?
      c = c[arg]
    c

  set: () ->
    return @conf if arguments.length < 2
    node = @conf
    for arg, k in arguments
      unless node[arg]?
        if k is arguments.length - 2
          node[arg] = arguments[arguments.length - 1]
          break
        node[arg] = {}
      node = node[arg]
    @setupNohm()
    @conf

  setupNohm: ->
    models = []
    unless helper.isArray(@conf.models)
      @conf.models = [@conf.models]

    for v in @conf.models
      if helper.isObject(v)
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
