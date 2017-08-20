import "views/env"

import { join } from 'path-extra'
import i18n2 from 'i18n-2'
import { observe } from 'redux-observers'
import { debounce } from 'lodash'
import { remote } from 'electron'

import { store } from 'views/create-store'
import { admiralIdObserver, listenToNicknameId, initDataWithAdmiralId } from './views/redux'
const { $, config } = window

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
document.title = window.__('window-title')

window.pluginRecordsPath = () =>
  join(window.PLUGIN_RECORDS_PATH, window._nickNameId)

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
initDataWithAdmiralId()
observe(
  store,
  // When admiral id changes, re-read data files
  [admiralIdObserver]
)
// The first time we got /api_port/port, read nickname_id and see if we need
// to migrate from the old position
window.addEventListener('game.response', listenToNicknameId)

require('./views')
