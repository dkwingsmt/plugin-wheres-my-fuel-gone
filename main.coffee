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

window.resource4to5 = (res4) ->
  # From [fuel, ammo, 0, bauxite]
  # To   [fuel, ammo, bauxite, 0, 0]
  [res4[0], res4[1], res4[3], 0, 0]

window.resource5to4 = (res5) ->
  # From [fuel, ammo, bauxite, repairFuel, repairSteel]
  # To   [fuel, ammo, steel, bauxite]
  [res5[0]+res5[3], res5[1], res5[4], res5[2]]

window.cloneByJson = (o) -> JSON.parse(JSON.stringify(o))

window.sumUpConsumption = (recordList) ->
  if !recordList.length
    return [0, 0, 0, 0, 0, 0]
  sumArray (for record in recordList
    fleetConsumption = (for ship in record.fleet.concat(record.fleet2 || [])
      ship.consumption.concat(if ship.bucket then 1 else 0))
    supportConsumption = (for support in (record.supports || []) 
      resource4to5(support.consumption).concat(0))
    sumArray fleetConsumption.concat(supportConsumption))

$('#font-awesome')?.setAttribute 'href', "#{ROOT}/components/font-awesome/css/font-awesome.min.css"

require './views'
