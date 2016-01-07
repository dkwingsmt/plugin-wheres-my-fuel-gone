{React, ReactBootstrap, FontAwesome} = window
{Button} = ReactBootstrap
remote = require 'remote'
windowManager = remote.require './lib/window'

path = require 'path-extra'

pluginVersion = require(path.join __dirname, 'package.json').version

i18n = new(require 'i18n-2')
  locales: ['en-US', 'ja-JP', 'zh-CN', 'zh-TW'],
  defaultLocale: 'zh-CN',
  directory: path.join(__dirname, 'i18n'),
  devMode: false,
  extension: '.json'
i18n.setLocale(window.language)
__ = i18n.__.bind(i18n)


window.wheresMyFuelGoneWindow = null
handleWindowMoveResize = ->
  b1 = window.wheresMyFuelGoneWindow.getBounds()
  setTimeout((->
    b2 = window.wheresMyFuelGoneWindow.getBounds()
    if JSON.stringify(b2) == JSON.stringify(b1)
      config.set 'plugin.WheresMyFuelGone.bounds', b2
  ), 5000)
initialPluginWindow = ->
  window.wheresMyFuelGoneWindow = windowManager.createWindow
    x: config.get 'plugin.WheresMyFuelGone.bounds.x', 0
    y: config.get 'plugin.WheresMyFuelGone.bounds.y', 0
    width: config.get 'plugin.WheresMyFuelGone.bounds.width', 1020
    height: config.get 'plugin.WheresMyFuelGone.bounds.height', 650
  window.wheresMyFuelGoneWindow.on 'move', handleWindowMoveResize
  window.wheresMyFuelGoneWindow.on 'resize', handleWindowMoveResize
  window.wheresMyFuelGoneWindow.loadURL "file://#{__dirname}/index.html"
  if process.env.DEBUG?
    window.wheresMyFuelGoneWindow.openDevTools
      detach: true
if config.get('plugin.WheresMyFuelGone.enable', true)
  initialPluginWindow()

module.exports =
  name: 'Where\'s My Fuel Gone'
  priority: 50
  displayName: <span><FontAwesome name='battery-1' key={0} />{' ' + __('plugin-list-name')}</span>
  author: 'DKWings'
  link: 'https://github.com/dkwingsmt'
  version: pluginVersion
  description: __ 'plugin-list-description'
  handleClick: ->
    window.wheresMyFuelGoneWindow.show()
