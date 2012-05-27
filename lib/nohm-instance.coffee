fs = require 'fs'
path = require 'path'
{Nohm} = require 'nohm'
helper = require './helper'

class NohmInstance

  conf:
    login:
      user: "admin"
      password: "nohm"
    redis:
      host: 'localhost'
      port: '6379'
      auth: null
      select: null
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
    @conf.models = [@conf.models] unless helper.isArray(@conf.models)

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

    Nohm.setClient @getRedisClient()
    Nohm.setPrefix @conf.prefix

    @models = Nohm.getModels()

  constructor: (options) ->
    @conf = if options? then @conf extends options

    @setupNohm()
    
  checkIndex: (name) ->
    report = {}
    m = @getModel(name)
    return null unless m?
    for name, prop of m.properties
      continue unless prop.unique? or prop.index?
      if prop.unique? and prop.index?
        report[name] = {warning: "has duplicated indices."}
        continue
      if prop.unique?
        # Handle unique index
        m.find (err, ids) ->
          m.__index prop, m.getClient().multi()
          report[name] = {success: "index checked"}
      else if prop.index?
        # Handle simple/numeric index
        report[name] = {success: "index checked"}
  
    report

  getRedisClient: () ->
    client = helper.connectRedis @conf.redis
    client.select @conf.redis.select if @conf.redis.select?
    client

  getModel: (name) ->
    return null unless @models[name]?
    m = Nohm.factory name
    return m

  login: (user, password) ->
    if typeof @conf.login is 'function'
      @conf.login(user, password)
    else
      user is @conf.login.user and \
      password is @conf.login.password

module.exports = NohmInstance
