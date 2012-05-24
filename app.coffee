express = require 'express'
SessionStore = require('connect-redis')(express)
stylus = require 'stylus'
assets = require 'connect-assets'
{Nohm} = require 'nohm'

if process.env.REDISTOGO_URL
  rtg = require('url').parse process.env.REDISTOGO_URL
  redis = require('redis').createClient rtg.port, rtg.hostname
  redis.auth rtg.auth.split(':')[1]
else
  redis = require('redis').createClient()

app = express.createServer()

app.use express.cookieParser()
app.use express.bodyParser()
app.use express.session
  secret: "nohm rocks!"
  maxAge: new Date Date.now() + 7200000
  store: new SessionStore {client: redis}
app.use assets()

app.set 'view engine', 'jade'

app.helpers
  title: "Nohm Admin"

app.dynamicHelpers
  user: (req, res) -> req.session


app.get '/model/overview/:model', (req, res) ->
  model_name = req.params.model
  res.render "model_overview", {
    title: model_name + " model overview - Nohm Admin"
  }

app.get '/dashboard', (req, res) ->
  res.render "dashboard", {
    title: "Dashboard - Nohm Admin"
  }

app.get '/login', (req, res) ->
  res.render "login", {
    title: "Login - Nohm Admin"
  }

app.post '/login', (req, res) ->
  username = req.body.username
  password = req.body.password
  if username is "admin" and password is "redis"
    req.session.auth = true
  res.redirect '/dashboard'

app.get '/logout', (req, res) ->
  req.session.destroy()
  res.render 'login'

app.get '/*', (req, res, next) ->
  if req.session.auth
    res.redirect '/dashboard'
  else
    res.redirect '/login'

boot = exports.boot = (port = 3003) ->
  app.listen process.env.port || 3003

if require.main = module
  boot()
