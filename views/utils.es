const { getStore } = window

export function pluginDataPath(id, filename='') {
  return join(window.PLUGIN_RECORDS_PATH, id, filename)
}

export function currentAdmiralId() {
  return getStore('info.basic.api_member_id')
}
