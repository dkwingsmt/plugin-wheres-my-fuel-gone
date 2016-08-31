import { sum, get, zip, sortedUniqBy, map, forEachRight } from 'lodash'

import { sumArray } from 'views/utils/tools'
import { pluginDataSelector } from './selectors'
const { getStore } = window

// Fix some problems in records.
// This function modifies `records`
function fixRecords(records=[]) {
  // Remove duplicate records that may appear somehow 
  records = sortedUniqBy(records, 'time')
  // Fix NaN caused by a bug from poi
  records.forEach((record) => {
    record.fleet.forEach((ship) => {
      ship.consumption.forEach((n, i) => {
        if (typeof n !== 'number' || !n)
          ship.consumption[i] = 0
      })
    })
  })
  return records
}

function checkConsistant(fleet, fleetId) {
  return getStore(`info.fleets.${fleetId-1}.api_ship`).every((nowId, index) =>
    (nowId == -1 && index >= fleet.length) || fleet[index] == nowId
  )
}

// Married ships has 15% off their resupply consumption
function marriageFactorFactory(lv) {
  return (lv >= 100) ?
    (r) => Math.floor(r * 0.85)
  : 
    (r) => r
}

function fleetConsumption(fleet) {
  return fleet.map((ship) => ({
    id: ship.id,
    shipId: getStore(`info.ships.${ship.id}.api_ship_id`),
    consumption: shipConsumption(ship),
  }))
}

function shipConsumption(recordShip) {
  const nowShip = getStore('info.ships')[recordShip.id]
  if (!nowShip)
    return [0, 0, 0, 0, 0]
  const marriageFactor = marriageFactorFactory(nowShip.api_lv)
  const resupplyFuel = marriageFactor(recordShip.fuel - nowShip.api_fuel)
  const resupplyAmmo = marriageFactor(recordShip.bull - nowShip.api_bull)
  // Every slot costs 5 bauxites
  const resupplyBauxite = 5 * sum(zip(recordShip.onSlot, nowShip.api_onslot)
    .map(([slot1, slot2]) => slot1-slot2))
  const repairFuel = nowShip.api_ndock_item[0] - recordShip.repair[0]
  const repairSteel = nowShip.api_ndock_item[1] - recordShip.repair[1]
  return [resupplyFuel, resupplyAmmo, resupplyBauxite, repairFuel, repairSteel]
}

function shipExpeditionConsumption(shipId) {
  const nowShip = getStore('info.ships')[shipId]
  if (!nowShip)
    return [0, 0, 0, 0]
  const marriageFactor = marriageFactorFactory(nowShip.api_lv)
  const resupplyFuel = marriageFactor(nowShip.api_fuel_max - nowShip.api_fuel)
  const resupplyAmmo = marriageFactor(nowShip.api_bull_max - nowShip.api_bull)
  // Every slot costs 5 bauxites
  const resupplyBauxite = 5 * sum(zip(nowShip.api_maxeq, nowShip.api_onslot).map(
    ([slot1, slot2]) => slot1-slot2))
  return [resupplyFuel, resupplyAmmo, 0, resupplyBauxite]
}

// Will return a result only when "valid" and "consistant" and "non-empty"
// Format: {
//   map: {
//     name: e.g. "2-5"
//     rank: undefined | 1 | 2 | 3           # 1 for easy, 3 for hard
//     hp: undefined | [<now_remaining>, <max>]  # undefined after cleared
//   }
//   time: <Unix Time Milliseconds>
//   fleet: [        # Include both fleets in a combined fleet
//     {     # One ship
//       id: <int>           # api_id as in $ships
//       shipId: <int>       # api_ship_id as in $ships
//       consumption: [<resupplyFuel>, <resupplyAmmo>, <resupplyBauxite>,
//         <repairFuel>, <repairSteel>]
//       bucket: <boolean>   # undefined at the beginning. Becomes true later.
//     }, ...   
//   ]
//   fleet1Size: <int>
//   supports: [
//     {
//       shipId: [<int>, ...]    # api_ship_id as in $ships
//       consumption: [<fuel>, <ammo>, 0, <bauxite>]     # Total only
//     }, ...
//   ]
// }
function generateResult(sortieInfo) {
  const {ships} = getStore('info')
  const {fleetId, fleet, map, time, fleet1Size, supports} = sortieInfo
  // Check consistency.
  // Inconsistancy may occur if you sortie, close poi without porting, log in from
  // another browser or device, do something else and then log back in poi.
  // Do as much as we can to check if anything changes and reject that.
  const fleet1 = fleet.slice(0, fleet1Size)
  const fleet2 = fleet.slice(fleet1Size)
  if (!checkConsistant(map(fleet1, 'id'), fleetId))
    return
  if (fleet2.length && !checkConsistant(map(fleet2, 'id'), 2))
    return
  if (supports && !supports.every((support) =>
    checkConsistant(support.fleet, support.fleetId)))
    return

  // Calculate result.
  const result = {
    fleet: fleetConsumption(fleet),
    map,
    time,
    fleet1Size,
  }
  if (supports.length) {
    result.supports = supports.map((support) => ({
      shipId: support.fleet.map((i) => get(ships[i], 'api_ship_id')).filter(Boolean),
      consumption: sumArray(support.fleet.map((id) => shipExpeditionConsumption(id))),
    }))
  }
  return result
}

export default function reducer(state=[], action) {
  const {type, result} = action
  switch (type) {
  case '@@poi-plugin-wheres-my-fuel-gone/readDataFiles':
    return fixRecords(result.records)
  case '@@Response/kcsapi/api_port/port': {
    // Collect sortie history
    const sortieInfo = pluginDataSelector(getStore()).sortie || {}
    if (!sortieInfo.time)        // Test if sortie record is valid
      break
    const newRecord = generateResult(sortieInfo)
    if (newRecord)
      return state.concat([newRecord])
    break
  }
  }
  return state
}
