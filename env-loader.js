window.remote = require('remote');

window.ROOT = remote.getGlobal('ROOT');

window.APPDATA_PATH = remote.getGlobal('APPDATA_PATH');

window.POI_VERSION = remote.getGlobal('POI_VERSION');

window.SERVER_HOSTNAME = remote.getGlobal('SERVER_HOSTNAME');

window.MODULE_PATH = remote.getGlobal('MODULE_PATH');

window.PLUGIN_ROOT = __dirname

require('module').globalPaths.push(MODULE_PATH);

var path = require('path')

window.PLUGIN_RECORDS_PATH = path.join(APPDATA_PATH, 'wheres-my-fuel-gone')

