express = require 'express'
stylus = require 'stylus'
assets = require 'connect-assets'
SessionStore = require('connect-redis')(express)
NohmInstance = require './lib/nohm-instance'
helper = require('./lib/helper')

context = {}

class NohmBackendApp

  options:
    port: 3003
    login:
      user: 'admin'
      password: 'nohm'
    models: []

  boot: ->
    server = require('http').createServer(@app)
    server.listen process.env.PORT || @options.port

  connect: () ->
    @app

  constructor: (options = {}) ->
    @options extends options
    @instance = new NohmInstance models: @options.models
    @app = express()
    @setup(@app)

  setup: (app) =>
    models = @instance.models
    app.configure ->
      app.set 'view engine', 'jade'
      app.set 'views', __dirname + "/views"
      app.use express.favicon()
      app.use express.logger('dev')
      app.use express.cookieParser()
      app.use express.bodyParser()
      app.use express.session
        secret: "nohm rocks!"
        maxAge: new Date Date.now() + 7200000
        store: new SessionStore
          client: helper.connectRedis(), db: 4
      app.use assets
        src: __dirname + '/assets'
        helperContext: context
        servePath: app.path()
      app.use (req, res, next) ->
        app.locals.title = ''
        app.locals.models = models
        app.locals.model_name = ''
        app.locals.basepath = app.path()
        app.locals.context = context
        app.locals.formatDate = require('./lib/helper').formatDate
        app.locals.user = req.session
        next()
      app.use app.router
      app.use express.static __dirname + '/assets'

    app.on 'mount', (parent) ->
      app.use assets
        src: __dirname + '/assets'
        helperContext: context
        servePath: app.path()

      app.locals.basepath = app.path()

    need_login = (req, res, next) ->
      return res.redirect 'login' unless req.session.auth?
      next()

    app.param 'model', (req, res, next, name) =>
      app.locals.model_name = name
      return next() unless @instance.models[name]?
      app.locals.model = @instance.getModel name
      next()

    app.get '/model/:model', need_login, (req, res) =>
      res.render "model_overview",
        title: req.params.model + " model overview"
        is_overview: true

    app.get '/model/:model/check', need_login, (req, res) =>
      @instance.checkIndex req.params.model, (report) ->
        res.send report

    app.get '/model/:model/truncate', need_login, (req, res) =>
      @instance.truncate req.params.model, (report) ->
        res.send report
      
    app.get '/model/:model/detail', need_login, (req, res) =>
      rows = []
      count = 0
      model = @instance.getModel req.params.model
      model.find (err, ids) =>
        render = () ->
          res.render "model_detail",
            title: req.params.model + " model detail"
            rows: rows
            is_detail: true

        return render() if ids.length is 0
        for id in ids
          row = @instance.getModel req.params.model
          load_func = if row._super_load? then row._super_load.bind(row) else row.load.bind(row)
          load_func id, (err) ->
            return render() if err?
            count++
            rows.push if this._super_allProperties
            then this._super_allProperties.call(this)
            else this.allProperties()
            render() if count == ids.length

    app.get '/dashboard', need_login, (req, res) =>
      res.render "dashboard", title: "Dashboard"

    app.get '/login', (req, res) ->
      res.render "login", title: 'Login'

    app.post '/login', (req, res) =>
      user = req.body.user
      password = req.body.password
      callback = (is_auth) ->
        return res.redirect 'login' unless is_auth
        req.session.auth = true
        res.redirect 'dashboard'
      if typeof @options.login is 'function'
        @options.login user, password, callback
      else
        callback user is @options.login.user and \
          password is @options.login.password

    app.get '/logout', (req, res) =>
      req.session.destroy()
      res.render 'login', title: 'Logout'

    app.get '/', (req, res, next) =>
      if req.session.auth
        res.redirect 'dashboard'
      else
        res.redirect 'login'

module.exports = NohmBackendApp

if require.main is module
  app = new NohmBackendApp
    instance:
      models: 'test/test_model'
  app.boot()
