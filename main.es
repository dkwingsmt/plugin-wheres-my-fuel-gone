import "views/env"

import { join } from 'path-extra'
import i18n2 from 'i18n-2'
import { observe } from 'redux-observers'
import { debounce } from 'lodash'

import { store } from 'views/create-store'
import { arraySum } from 'views/utils/tools'
import { saveDataObservers, admiralIdObserver, listenToNicknameId, initReadDataFiles } from './views/redux'

const i18n = new i18n2({
  locales: ['en-US', 'ja-JP', 'zh-CN', 'zh-TW'],
  defaultLocale: 'zh-CN',
  directory: join(__dirname, 'i18n'),
  devMode: false,
  extension: '.json',
})
i18n.setLocale(window.language)
window.__ = i18n.__.bind(i18n)
window.PLUGIN_ROOT = __dirname
document.title = __('window-title')

window.pluginRecordsPath = () => 
  join(window.PLUGIN_RECORDS_PATH, window._nickNameId)

window.sumArray = arraySum

window.sum4 = window.sumArray

window.resource4to5 = (res4) => {
  // From [fuel, ammo, 0, bauxite]
  // To   [fuel, ammo, bauxite, 0, 0]
  return [res4[0], res4[1], res4[3], 0, 0]
}

window.resource5to4 = (res5) => {
  // From [fuel, ammo, bauxite, repairFuel, repairSteel]
  // To   [fuel, ammo, steel, bauxite]
  if (res5 && res5.length)
    return [res5[0]+res5[3], res5[1], res5[4], res5[2]]
  else
    return [0, 0, 0, 0]
}

window.resource5toSupply = (res5) => {
  // From [fuel, ammo, -, -, -]
  // To   [fuel, ammo, 0, 0]
  if (res5 && res5.length)
    return [res5[0], res5[1], undefined, undefined]
  else
    return [0, 0, 0, 0]
}

window.resource5toRepair = (res5) => {
  // From [-, -, bauxite, repairFuel, repairSteel]
  // To   [fuel, 0, steel, bauxite]
  if (res5 && res5.length)
    return [res5[3], undefined, res5[4], res5[2]]
  else
    return [0, 0, 0, 0]
}

window.sumUpConsumption = (recordList) => {
  if (!recordList.length)
    return [0, 0, 0, 0, 0, 0]
  return sumArray(recordList.map((record) => {
    const fleetConsumption = (record.fleet.concat(record.fleet2 || []).map((ship) =>
      ship.consumption.concat(ship.bucket ? 1 : 0)))
    const supportConsumption = ((record.supports || []).map((support) =>
      resource4to5(support.consumption).concat(0)))
    return sumArray(fleetConsumption.concat(supportConsumption))
  }))
}

// Record the size and position of  
window.wheresMyFuelGoneWindow = remote.getCurrentWindow()
const handleWindowMoveResize = debounce(() => {
  config.set('plugin.WheresMyFuelGone.bounds',
    window.wheresMyFuelGoneWindow.getBounds())
}, 5000)
window.wheresMyFuelGoneWindow.on('move', handleWindowMoveResize)
window.wheresMyFuelGoneWindow.on('resize', handleWindowMoveResize)

if ($('#font-awesome'))
  $('#font-awesome').setAttribute('href', require.resolve('font-awesome/css/font-awesome.css'))

// Read data files now if we have admiral id in store
initReadDataFiles()
observe(
  store,
  // When admiral id changes, re-read data files
  [admiralIdObserver]
  // When data change, save to the corresponding file
  .concat(saveDataObservers)
)
// The first time we got /api_port/port, read nickname_id and see if we need
// to migrate from the old position
window.addEventListener('game.response', listenToNicknameId)

require('./views')
