exports.connectRedis = (config) ->
  require 'redis'
  if config?
    redis = require('redis').createClient config.port, config.host
    redis.auth config.auth if config.auth?
  else if process.env.REDISTOGO_URL
    rtg = require('url').parse process.env.REDISTOGO_URL
    redis = require('redis').createClient rtg.port, rtg.hostname
    redis.auth rtg.auth.split(':')[1]
  else
    redis = require('redis').createClient()
  redis
