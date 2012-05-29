fs = require 'fs'
path = require 'path'
helper = require './helper'
async = require 'async'

Nohm = null

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
    nohm: null

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
    Nohm = if @conf.nohm then @conf.nohm else require('nohm').Nohm
    models = []
    @conf.models = [@conf.models] unless helper.isArray(@conf.models)

    for v in @conf.models
      if helper.isObject(v)
        models.push v
        continue

      if typeof v is 'string' and v[0] != '/' and module.parent?
        parent = module.parent
        while parent.parent?
          parent = parent.parent
        v = path.dirname(parent.filename) + "/" + v

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
    
  checkIndex: (model_name, next) ->
    report = {}
    indices = {}
    row_count = 0
    checked_count = 0
    m = @getModel(model_name)

    unless m?
      return if next then next(null) else null
    
    for name, prop of m.properties
      unique = index = false
      continue unless prop.unique? or prop.index?
      unique = prop.unique? and prop.unique is true
      index = prop.index? and prop.index is true
      if unique and index
        report[name] = {warning: "has duplicated indices."}
        return if next then next(report) else report
      indices[name] = if unique then 'unique index' else 'index'

    m.find (err, ids) ->
      row_count = ids.length
      checked = 0
      for id in ids
        row = Nohm.factory model_name
        row.load id, (err, properties) ->
          row = this
          check(row)

    check = (row) ->
      for n, t of indices
        row.properties[n].__updated = true
        if t is 'unique index'
          # Because when saving a updated row, nohm remove old unique value,
          # so I create a fake one to fool it.
          row.properties[n].__oldValue = Nohm.prefix.unique + model_name + ':' + n + ':'
          row.getClient().del Nohm.prefix.unique + model_name + ':' + n + ':' + row.properties[n].value
      row.save (err) ->
        checked_count++ unless err
        if checked_count is row_count
          for n, t of indices
            report[n] = {success: t + " checked"}
          return if next then next(report) else report

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
