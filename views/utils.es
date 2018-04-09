import { get } from 'lodash'
import { join } from 'path-extra'
const { getStore } = window

export function pluginDataPath(id, filename='') {
  return join(window.PLUGIN_RECORDS_PATH, `${id}`, filename)
}

export function currentAdmiralId() {
  return getStore('info.basic.api_member_id')
}

// Argument:
//   api_deck_id: postBody.api_deck_id given on /kcsapi/api_req_map/start
// Return:
//   [[shipId for each ship] for each fleet]
export function sortieShipsId(api_deck_id, store) {
  if (!store) {
    store = getStore()
  }
  const { combinedFlag } = get(store, 'sortie')
  const { fleets=[]} = get(store, 'info')
  // It is possible to hasCombinedFleet but sortie with fleet 3/4
  const fleetsId = combinedFlag > 0 && api_deck_id == 1 ? [0, 1] : [api_deck_id-1]
  const fleetsShipsId = fleetsId.map((fleetId) =>
    get(fleets[fleetId], 'api_ship', []).filter((i) => i != -1))
  return fleetsShipsId
}
