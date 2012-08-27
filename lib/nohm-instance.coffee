fs = require 'fs'
path = require 'path'
helper = require './helper'
async = require 'async'

class NohmInstance

  options:
    redis:
      host: 'localhost'
      port: '6379'
      auth: null
      db: null
    prefix: "nihil"
    models: []
    nohm: null

  models: []

  get: () ->
    c = @options
    for arg in arguments
      return null unless c[arg]?
      c = c[arg]
    c

  set: () ->
    return @options if arguments.length < 2
    node = @options
    for arg, k in arguments
      unless node[arg]?
        if k is arguments.length - 2
          node[arg] = arguments[arguments.length - 1]
          break
        node[arg] = {}
      node = node[arg]
    @setup()
    @options

  setup: ->
    models = []
    @options.models = [@options.models] unless helper.isArray(@options.models)

    if module.parent?
      toplevel = module.parent
      while toplevel.parent?
        toplevel = toplevel.parent

    try
      @nohm = toplevel.require('nohm').Nohm
    catch e
      return console.log e

    for v in @options.models
      if helper.isObject(v)
        models.push v
        continue

      continue if typeof v isnt 'string'

      v = path.dirname(toplevel.filename) + "/" + v if v[0] isnt '/'

      try
        models.push require(v)
      catch e
        try
          fs.readdirSync(v).forEach (file) ->
            models.push require(v + "/" + file)
        catch e
          console.log e

    unless @nohm.client?
      redisClient = @getRedisClient()
      redisClient.on 'connect', =>
        @nohm.setClient redisClient
        @nohm.setPrefix @options.prefix if @nohm.prefix.ids == 'nohm:ids:'

    @models = @nohm.getModels()

  constructor: (options = {}) ->
    @options extends options
    @setup()
    
  truncate: (model_name, next) ->
    @nohm.client.keys @nohm.prefix.ids.split(':')[0] + ':*', (err, keys) =>
      return next warning: "0 key removed" if not keys or keys.length == 0
      total = keys.length
      count = 0
      cb = ->
        count++
        next success: total + " keys removed" if count == total
      @nohm.client.del key, cb for key in keys

  checkIndex: (model_name, next) ->
    report = {}
    indices = {}
    row_count = 0
    checked_count = 0
    m = @getModel(model_name)

    return next?(null) unless m?
    
    for name, prop of m.properties
      unique = index = false
      continue unless prop.unique? or prop.index?
      unique = prop.unique? and prop.unique is true
      index = prop.index? and prop.index is true
      if unique and index
        report[name] = warning: "has duplicated indices."
        return if next then next(report) else report
      indices[name] = if unique then 'unique index' else 'index'

    m.find (err, ids) =>
      return next warning: "empty" if err or ids.length is 0
      row_count = ids.length
      checked = 0
      for id in ids
        row = @nohm.factory model_name
        load_func = if row._super_load? then row._super_load.bind(row) else row.load.bind(row)
        load_func id, (err) ->
          check(@)

    check = (row) =>
      for n, t of indices
        row.properties[n].__updated = true
        if t is 'unique index'
          # Because when saving a updated row, nohm remove old unique value,
          # so I create a fake one to fool it.
          row.properties[n].__oldValue = @nohm.prefix.unique + model_name + ':' + n + ':'
          row.getClient().del @nohm.prefix.unique + model_name + ':' + n + ':' + row.properties[n].value

      save_func = if row._super_save? then row._super_save.bind(row) else row.save.bind(row)
      save_func (err) ->
        checked_count++ unless err
        if checked_count is row_count
          for n, t of indices
            report[n] = success: t + " checked"
          return next?(report)

  getRedisClient: ->
    client = helper.connectRedis @options.redis
    client.select @options.redis.db if @options.redis.db?
    client

  getModel: (name) ->
    return null unless @models[name]?
    return @nohm.factory(name)

module.exports = NohmInstance
