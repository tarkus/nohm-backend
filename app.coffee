express = require 'express'
stylus = require 'stylus'
assets = require 'connect-assets'
SessionStore = require('connect-redis')(express)
NohmInstance = require './lib/nohm-instance'

context = {}

class NohmBackendApp

  settings:
    port: 3003
    path: ''
    instance:
      nohm: null
      models: []

  boot: ->
    @app.listen process.env.port || @settings.port

  connect: () ->
    @app

  constructor: (options = {}) ->
    @settings extends options
    @instance = new NohmInstance @settings.instance
    throw "No nohm instance founded." unless @instance?
    @app = express.createServer()
    @setup(@app)

  setup: (app) =>
    app.configure ->
      app.use express.cookieParser()
      app.use express.bodyParser()
      app.use express.session
        secret: "nohm rocks!"
        maxAge: new Date Date.now() + 7200000
        store: new SessionStore {client: require('./lib/helper').connectRedis()}
      app.use assets
        src: __dirname + '/assets'
        helperContext: context
      app.use express.static __dirname + '/assets'
      app.set 'view engine', 'jade'
      app.set 'views', __dirname + "/views"

    app.helpers
      title: ""
      models: @instance.models
      model_name: ''
      context: context
      basepath: ''
      formatDate: require('./lib/helper').formatDate

    app.dynamicHelpers
      user: (req, res) ->
        req.session

    app.__mounted = (parent) ->
      basepath = app.route
      app.use assets
        src: __dirname + '/assets'
        helperContext: context
        servePath: app.route
      app.helpers
        basepath: basepath

    need_login = (req, res, next) ->
      return res.redirect '/login' unless req.session.auth?
      next()

    app.param 'model', (req, res, next, name) =>
      res.local 'model_name', name
      return next() unless @instance.models[name]?
      res.local 'model', @instance.getModel name
      next()

    app.get '/model/:model', need_login, (req, res) =>
      res.render "model_overview",
        title: req.params.model + " model overview"
        is_overview: true

    app.get '/model/:model/check_index', need_login, (req, res) =>
      @instance.checkIndex req.params.model, (report) ->
        res.send report
      
    app.get '/model/:model/detail', need_login, (req, res) =>
      rows = []
      count = 0
      model = @instance.getModel req.params.model
      model.sort
        field: 'created_at'
        direction: 'DESC'
        start: 0
        amount: 30
      , (err, ids) =>
        for id in ids
          row = @instance.getModel req.params.model
          row.load id, (err) ->
            count++ unless err
            rows.push row
            render() if count == ids.length

        render = () ->
          res.render "model_detail",
            title: req.params.model + " model detail"
            rows: rows
            is_detail: true

    app.get '/dashboard', need_login, (req, res) =>
      res.render "dashboard", title: "Dashboard"

    app.get '/login', (req, res) ->
      res.render "login", title: "Login"

    app.post '/login', (req, res) =>
      user = req.body.user
      password = req.body.password
      if @instance.login user, password
        req.session.auth = true
        res.redirect '/dashboard'
      else
        res.redirect '/login'

    app.get '/logout', (req, res) =>
      req.session.destroy()
      res.render 'login', title: 'Logout'

    app.get '/', (req, res, next) =>
      if req.session.auth
        res.redirect '/dashboard'
      else
        res.redirect '/login'


module.exports = NohmBackendApp

if require.main is module
  app = new NohmBackendApp
    instance:
      models: 'test/test_model'
  app.boot()
