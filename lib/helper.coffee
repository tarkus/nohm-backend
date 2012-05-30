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

exports.isObject = (v) ->
  return Object.prototype.toString.call(v) is '[object Object]' or \
         Object.prototype.toString.call(v) is '[object Function]'

exports.isArray = (v) ->
  return Object.prototype.toString.call(v) is '[object Array]'

exports.formatDate = (date) ->
  if date not instanceof Date
    date = new Date(date * 1000)
  string = [date.getFullYear(), date.getMonth() + 1, date.getDate()].join("-")
  string + " " + date.toLocaleTimeString()
