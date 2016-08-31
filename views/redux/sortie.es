import { flatten } from 'lodash'

import { sortieShipsId } from '../utils'
const { getStore } = window

function recordFleets(fleetsShipsId=[], ships={}) {
  return fleetsShipsId.map((fleetShipsId) => fleetShipsId.map((id) => {
    const ship = ships[id]
    if (!ship)
      return
    return {
      id,
      fuel: ship.api_fuel,
      bull: ship.api_bull,
      repair: ship.api_ndock_item,
      onSlot: ship.api_onslot.slice(),
    }
  }).filter(Boolean))
}

const empty = {}

// Returns [nowHp, maxHp, gaugeType]
// where nowHp === 0 means cleared
// Copied from views/utils/selectors
function getMapHp(map, $map) {
  if (!map || !$map)
    return
  if (map.api_eventmap) {
    const {api_now_maphp, api_max_maphp, api_gauge_type} = map.api_eventmap
    return [api_now_maphp, api_max_maphp, api_gauge_type]
  }
  const maxCount = $map.api_required_defeat_count
  if (!maxCount)
    return
  const nowCount = map.api_defeat_count || maxCount
  const nowHp = maxCount - nowCount
  return [nowHp, maxCount, undefined]
}

export default function reducer(state={}, action) {
  const {type, result, postBody, body} = action
  switch (type) {
  case '@@poi-plugin-wheres-my-fuel-gone/readDataFiles':
    return result.sortie || empty
  case '@@Response/kcsapi/api_req_map/start': {
    const {api_deck_id, api_maparea_id, api_mapinfo_no} = postBody
    const {$maps, $missions: $expeditions} = getStore('const')
    const {maps={}, fleets=[], ships={}} = getStore('info')
    const fleetsShipsId = sortieShipsId(api_deck_id)
    const fleetsShips = recordFleets(fleetsShipsId, ships)
    const fleet1Size = fleetsShips[0].length
    const sortieShips = flatten(fleetsShips)
    const time = new Date().getTime()

    const map = {id: `${api_maparea_id}-${api_mapinfo_no}`}
    // Get mapRank (if exists)
    const mapId = `${api_maparea_id}${api_mapinfo_no}`
    if ((maps[mapId] || {}).api_eventmap)
      map.rank = maps[mapId].api_eventmap.api_selected_rank

    // Get mapHp (if exists)
    const mapHp = getMapHp(maps[mapId], $maps[mapId])
    if (mapHp && mapHp[0])
      map.hp = mapHp

    // Get support expeditions
    const supports = fleets.map((fleet, fleetId) => {
      if (fleet.api_mission[0] != 1) {
        return
      }
      const $expedition = $expeditions[fleet.api_mission[1]]
      // "$expedition.api_return_flag == 0" means a support expedition (?)
      if (!$expedition || $expedition.api_return_flag != 0
        || $expedition.api_maparea_id != api_maparea_id) {
        return
      }
      return {
        fleetId,
        fleet: fleet.api_ship.filter((i) => i != -1),
      }
    }).filter(Boolean)

    return {
      fleetId: api_deck_id,
      fleet: sortieShips,
      map,
      time,
      fleet1Size,
      supports,
    }
  }
  case '@@Response/kcsapi/api_port/port':
    return empty
  }
  return state
}
