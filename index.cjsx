module.exports =
  windowOptions:
    x: config.get 'plugin.WheresMyFuelGone.bounds.x', 0
    y: config.get 'plugin.WheresMyFuelGone.bounds.y', 0
    width: config.get 'plugin.WheresMyFuelGone.bounds.width', 1020
    height: config.get 'plugin.WheresMyFuelGone.bounds.height', 650
  windowURL:
    "file://#{__dirname}/index.html"
