require 'coffee-react/register'
require "#{ROOT}/views/env"

path = require 'path-extra'

window.i18n = {}
window.i18n.main = new(require 'i18n-2')
  locales: ['en-US', 'ja-JP', 'zh-CN', 'zh-TW'],
  defaultLocale: 'zh-CN',
  directory: path.join(__dirname, 'i18n'),
  devMode: false,
  extension: '.json'
window.i18n.main.setLocale(window.language)
window.__ = window.i18n.main.__.bind(window.i18n.main)
window.i18n.resources = {}
window.i18n.resources.__ = (str) -> return str
window.i18n.resources.translate = (locale, str) -> return str
window.i18n.resources.setLocale = (str) -> return

window.PLUGIN_ROOT = __dirname

document.title = __ 'window-title'

window.sum = (l) ->
  s = 0
  for i in l
    if typeof i == 'number'
      s += i
  s

window.sumArray = (lists) ->
  # Sum array of [int, ...] into one [int, ...]
  _.unzip(lists).map sum
window.sum4 = window.sumArray

$('#font-awesome')?.setAttribute 'href', "#{ROOT}/components/font-awesome/css/font-awesome.min.css"

require './views'
