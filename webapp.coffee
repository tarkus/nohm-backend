express = require 'express'
namespace = require 'express-namespace'
stylus = require 'stylus'
assets = require 'connect-assets'
SessionStore = require('connect-redis')(express)
NohmInstance = require './lib/nohm-instance'

class NohmBackendApp

  settings:
    port: 3003
    path: ''
    instance:
      models: "test/test_model"

  boot: ->
    @app.listen process.env.port || @settings.port

  constructor: (options = {}) ->
    @settings extends options
    @instance = new NohmInstance @settings.instance
    throw "No nohm instance founded." unless @instance?
    @app = express.createServer()
    @setup(@app)

  setup: (app) =>
    context = {}
    app.configure =>
      app.use express.cookieParser()
      app.use express.bodyParser()
      app.use express.session
        secret: "nohm rocks!"
        maxAge: new Date Date.now() + 7200000
        store: new SessionStore {client: require('./lib/helper').connectRedis()}
      app.use assets
        src: __dirname + '/assets'
        helperContext: context
        servePath: @settings.path
      app.use express.static __dirname + '/assets'
      app.set 'view engine', 'jade'
      app.set 'views', __dirname + "/views"

    app.helpers
      title: ""
      models: @instance.models
      model_name: ''
      basepath: @settings.path
      context: context

    app.dynamicHelpers
      user: (req, res) ->
        req.session

    need_login = (req, res, next) ->
      return res.redirect '/login' unless req.session.auth?
      next()

    app.param 'model', (req, res, next, name) =>
      req.params.model_name = name
      res.local 'model_name', name
      return next() unless @instance.models[name]?
      res.local 'model', @instance.getModel name
      next()

    app.get '/model/:model', need_login, (req, res) =>
      res.render "model_overview",
        title: req.params.model + " model overview"
        is_overview: true

    app.get '/model/:model/check_index', need_login, (req, res) =>
      @instance.checkIndex req.params.model_name, (report) ->
        res.send report
      
    app.get '/model/:model/detail', need_login, (req, res) =>
      res.render "model_detail",
        title: req.params.model + " model detail"
        is_detail: true

    app.get '/dashboard', need_login, (req, res) =>
      res.render "dashboard", title: "Dashboard"

    app.get '/login', (req, res) ->
      res.render "login", title: "Login"

    app.post '/login', (req, res) =>
      user = req.body.user
      password = req.body.password
      console.log @instance.login
      if @instance.login user, password
        req.session.auth = true
        res.redirect '/dashboard'
      else
        res.redirect '/login'

    app.get '/logout', (req, res) =>
      req.session.destroy()
      res.render 'login', title: 'Logout'

    app.get '/', (req, res, next) =>
      console.log "hello"
      if req.session.auth
        res.redirect '/dashboard'
      else
        res.redirect '/login'

  connect: ()->
    @app


module.exports = NohmBackendApp

if require.main is module
  app = new NohmBackendApp
  app.boot()
