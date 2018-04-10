import { zip, get, flatten, flattenDepth, sum } from 'lodash'

import { sortieShipsId } from '../utils'
import { reduxSet } from 'views/utils/tools'

function reduxSetAdd(state, path, number) {
  if (number) {
    return reduxSet(state, path, get(state, path, 0) + number)
  }
  return state
}

function recordFleets(fleetsShipsId=[], ships={}) {
  return fleetsShipsId.map((fleetShipsId) => fleetShipsId.map((id) => {
    const ship = ships[id]
    if (!ship)
      return
    return {
      id,
      shipId: ship.api_ship_id,
      fuel: ship.api_fuel,
      bull: ship.api_bull,
      repair: ship.api_ndock_item,
      onSlot: ship.api_onslot.slice(),
    }
  }).filter(Boolean))
}

// Input:
//   planesInfo: [ [slotId, count ], ... ]
//     where slotId can be empty or invalid id, since their consumption will be considered 0 anyway.
// Return: [0, 0, steel, 0]
function calculatejetAssaultConsumption(planesInfo, store) {
  const steels = sum(planesInfo.map(([slotId, count]) => {
    const slotItemId = parseInt(get(store, `info.equips.${slotId}.api_slotitem_id`, 0), 10)
    let equipConsumption = 0
    switch(slotItemId) {
    case 199:
      equipConsumption = 14
      break
    case 200:
      equipConsumption = 13
      break
    default:
    }
    return Math.round(equipConsumption * 0.2 * count)
  }))
  return steels
}

const empty = {}

// Returns [nowHp, maxHp, gaugeType]
// where nowHp === 0 means cleared
// Copied from views/utils/selectors
function getMapHp(map, $map) {
  if (!map || !$map)
    return
  if (map.api_eventmap) {
    const { api_now_maphp, api_max_maphp, api_gauge_type } = map.api_eventmap
    return [api_now_maphp, api_max_maphp, api_gauge_type]
  }
  const maxCount = $map.api_required_defeat_count
  if (!maxCount)
    return
  const nowCount = map.api_defeat_count == null ? maxCount : map.api_defeat_count
  const nowHp = maxCount - nowCount
  return [nowHp, maxCount, undefined]
}

//sortie: {
//  time,       # Unix milliseconds. Existence means validity of sortie record
//  fleet: [{   # Ship info from all fleets (combined)
//    id,       # api_id
//    shipId,   # api_ship_id
//    fuel,
//    bull,
//    repair,   # [fuel, steel]
//    onSlot,   # api_slot
//  }, ...],
//  fleet1Size, # Integer
//  fleetJetAssaultSteels: [<int>], in the same order as fleet
//  supports: [{
//      fleetId: 0 | 1 | 2 | 3
//      fleet: [shipId]     # api_id
//  }, ...]
//  map: {
//    id: '35-1',
//    rank: undefined | 1 | 2 | 3,
//    hp: [nowHp, maxHp, gaugeType] # hp = 0 means clear
//  }
//  airbase: {
//    valid: <bool>                 # Set true after api_req_map/start_air_base
//    info: [{...}]                 # Same as store.info.airbase
//    _destructionInfo: {           # Temp var
//      baseMaxHp: [<int>]
//    }
//    baseHpLost: <int>    # May not exist if no destruction happened
//  }
function generateSortieInfo(postBody, time, store) {
  const { api_deck_id, api_maparea_id, api_mapinfo_no } = postBody
  const { $maps, $missions: $expeditions } = get(store, 'const')
  const { maps={}, fleets=[], ships={}, resources, airbase: airbaseInfo } = get(store, 'info')

  const result = {}
  /* Basic info */
  result.time = time
  result.resources = resources

  /* Map */
  const sortieMap = {
    id: `${api_maparea_id}-${api_mapinfo_no}`,
  }
  // Get mapRank (if exists)
  const mapId = `${api_maparea_id}${api_mapinfo_no}`
  sortieMap.name = get($maps[mapId], 'api_name', '???')
  if ((maps[mapId] || {}).api_eventmap)
    sortieMap.rank = maps[mapId].api_eventmap.api_selected_rank
  // Get mapHp (if exists)
  const mapHp = getMapHp(maps[mapId], $maps[mapId])
  if (mapHp && mapHp[0]) {
    sortieMap.hp = mapHp
  }
  result.map = sortieMap

  /* Fleet */
  const fleetsShipsId = sortieShipsId(api_deck_id, store)
  const fleetsShips = recordFleets(fleetsShipsId, ships)
  result.fleetId = api_deck_id
  result.fleet = flatten(fleetsShips)
  result.fleet1Size = fleetsShips[0].length

  /* Support expeditions */
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
  if (supports.length)
    result.supports = supports

  const airbase = {
    info: airbaseInfo,
  }
  result.airbase = airbase

  return result
}

export default function reducer(state=empty, action, store) {
  const { type, result, postBody, body, time } = action
  const hasAirbase = !!get(state, 'airbase.valid')
  switch (type) {
  case '@@poi-plugin-wheres-my-fuel-gone/readDataFiles':
    return result.sortie || empty
  case '@@Response/kcsapi/api_req_map/start': {
    return generateSortieInfo(postBody, time, store)
  }
  case '@@Response/kcsapi/api_req_map/start_air_base': {
    return reduxSet(state, ['airbase', 'valid'], true)
  }
  case '@@Response/kcsapi/api_req_map/next':
    if (hasAirbase && body.api_destruction_battle) {
      const fdam = get(body, 'api_destruction_battle.api_air_base_attack.api_stage3.api_fdam', [])
      const thisTotalDamage = sum(fdam.slice(1))
      const alreadyTotalDamage = get(state, ['airbase', 'baseHpLost'], 0)
      return reduxSet(state, ['airbase', 'baseHpLost'], alreadyTotalDamage + thisTotalDamage)
    }
    break
  case '@@Response/kcsapi/api_req_sortie/battle':
  case '@@Response/kcsapi/api_req_sortie/airbattle':
  case '@@Response/kcsapi/api_req_sortie/ld_airbattle':
  case '@@Response/kcsapi/api_req_combined_battle/battle':
  case '@@Response/kcsapi/api_req_combined_battle/battle_water':
  case '@@Response/kcsapi/api_req_combined_battle/airbattle':
  case '@@Response/kcsapi/api_req_combined_battle/ld_airbattle':
  case '@@Response/kcsapi/api_req_combined_battle/ec_battle':
  case '@@Response/kcsapi/api_req_combined_battle/each_battle':
  case '@@Response/kcsapi/api_req_combined_battle/each_battle_water': {
    let newState = state
    if (hasAirbase && body.api_air_base_injection) {
      const slotsIds = flattenDepth(state.airbase.info
        .filter((squad) => squad.api_action_kind == 1 && squad.api_area_id == state.map.id.split('-')[0])
        .map((squad) =>
          squad.api_plane_info.map((plane) =>
            [plane.api_slotid, plane.api_count]
          )), 2)
      const jetAssaultSteels = calculatejetAssaultConsumption(slotsIds, store)
      newState = reduxSetAdd(newState, ['airbase', 'jetAssaultSteels'], jetAssaultSteels)
    }
    if (hasAirbase && body.api_injection_kouku) {
      if (!newState.fleetJetAssaultSteels) {
        newState = { ...newState, fleetJetAssaultSteels: []}
      }
      state.fleet.forEach(({ id: shipId }, i) => {
        const ship = store.info.ships[shipId]
        const jetAssaultSteels = calculatejetAssaultConsumption(zip(ship.api_slot, ship.api_onslot), store)
        newState = reduxSetAdd(newState, ['fleetJetAssaultSteels', i], jetAssaultSteels)
      })
    }
    return newState
  }
  case '@@Response/kcsapi/api_port/port':
    return empty
  }
  return state
}
