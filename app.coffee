express = require 'express'
stylus = require 'stylus'
assets = require 'connect-assets'
SessionStore = require('connect-redis')(express)
NohmInstance = require './lib/nohm-instance'
manifest = require './instance'
instance = new NohmInstance manifest

unless instance?
  throw "No nohm instance founded."

app = express.createServer()

app.use express.cookieParser()
app.use express.bodyParser()
app.use express.session
  secret: "nohm rocks!"
  maxAge: new Date Date.now() + 7200000
  store: new SessionStore {client: require('./lib/helper').connectRedis()}
app.use assets()
app.use express.static __dirname + '/assets'

app.set 'view engine', 'jade'

app.helpers
  title: ""
  models: instance.models
  model_name: ''

app.dynamicHelpers
  user: (req, res) ->
    req.session

need_login = (req, res, next) ->
  return res.redirect '/login' unless req.session.auth?
  next()

app.param 'model', (req, res, next, name) ->
  res.local 'model_name', name
  return next() unless instance.models[name]?
  console.log  instance.getModel name
  res.local 'model', instance.getModel name
  next()

app.get '/model/:model', need_login, (req, res) ->
  res.render "model_overview", {
    title: res.local('model').modelName + " model overview"
    is_overview: true
  }
  
app.get '/model/:model/detail', need_login, (req, res) ->
  res.render "model_detail", {
    title: res.local('model').modelName + " model detail"
    is_detail: true
  }

app.get '/dashboard', need_login, (req, res) ->
  res.render "dashboard", {
    title: "Dashboard"
  }

app.get '/login', (req, res) ->
  res.render "login", {
    title: "Login"
  }

app.post '/login', (req, res) ->
  username = req.body.username
  password = req.body.password
  if typeof instance.get('login') is 'function'
    login = instance.get('login')(username, password)
  else
    login = username is instance.get("login", "user") and \
            password is instance.get("login", "password")
  if login
    req.session.auth = true
    res.redirect '/dashboard'
  else
    res.redirect '/login'

app.get '/logout', (req, res) ->
  req.session.destroy()
  res.render 'login', title: 'Logout'

app.get '/', (req, res, next) ->
  if req.session.auth
    res.redirect '/dashboard'
  else
    res.redirect '/login'

boot = exports.boot = (port = 3003) ->
  app.listen process.env.port || 3003

if require.main = module
  boot()
