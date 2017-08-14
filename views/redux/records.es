import { zipWith, flatten, sum, get, sortedUniqBy, map, forEachRight } from 'lodash'

import { arraySum, reduxSet, indexify } from 'views/utils/tools'
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

function checkConsistent(fleet, nowFleetShipsId) {
  return nowFleetShipsId.every((nowId, index) =>
    (nowId == -1 && index >= fleet.length) || fleet[index] == nowId
  )
}

// Married ships has 15% off of their resupply consumption
function marriageFactorFactory(lv) {
  return (lv >= 100) ?
    (r) => Math.floor(r * 0.85)
    :
    (r) => r
}

function fleetConsumption(fleet, nowShips, fleetJetAssaultSteels) {
  return zipWith(fleet, fleetJetAssaultSteels, (ship, jetAssaultSteel) => ({
    id: ship.id,
    shipId: ship.shipId,
    consumption: shipConsumption(ship, nowShips[ship.id]).concat([jetAssaultSteel || 0]),
  }))
}

function shipConsumption(recordShip, nowShip) {
  if (!nowShip)
    return [0, 0, 0, 0, 0]
  const marriageFactor = marriageFactorFactory(nowShip.api_lv)
  const resupplyFuel = marriageFactor(recordShip.fuel - nowShip.api_fuel)
  const resupplyAmmo = marriageFactor(recordShip.bull - nowShip.api_bull)
  // Every slot costs 5 bauxites
  const resupplyBauxite = 5 * sum(zipWith(recordShip.onSlot, nowShip.api_onslot,
    (slot1, slot2) => slot1-slot2))
  const repairFuel = nowShip.api_ndock_item[0] - recordShip.repair[0]
  const repairSteel = nowShip.api_ndock_item[1] - recordShip.repair[1]
  return [resupplyFuel, resupplyAmmo, resupplyBauxite, repairFuel, repairSteel]
}

function shipExpeditionConsumption(shipId, ships) {
  const nowShip = ships[shipId]
  const $ship = getStore(`const.$ships.${get(nowShip, 'api_ship_id')}`)
  if (!nowShip || !$ship)
    return [0, 0, 0, 0]
  const marriageFactor = marriageFactorFactory(nowShip.api_lv)
  const resupplyFuel = marriageFactor($ship.api_fuel_max - nowShip.api_fuel)
  const resupplyAmmo = marriageFactor($ship.api_bull_max - nowShip.api_bull)
  // Every slot costs 5 bauxites
  const resupplyBauxite = 5 * sum(zipWith($ship.api_maxeq, nowShip.api_onslot,
    (slot1, slot2) => slot1-slot2))
  return [resupplyFuel, resupplyAmmo, 0, resupplyBauxite]
}

// Returns [fuel, ammo, 0, 0].
// From http://nga.178.com/read.php?tid=10551944 . However, the described formula
// is a little inconsistent between full-squadron and non-full-squadron. The
// true formula is yet to be confirmed.
function airbaseSquadronSortieConsumption(squadron) {
  const empty = [0, 0, 0, 0]
  if (!squadron || squadron.api_state != 1 || !squadron.api_slotid)
    return empty
  const count = squadron.api_count
  const equipId = getStore(`info.equips.${squadron.api_slotid}.api_slotitem_id`)
  if (!equipId)
    return empty
  const equipType = getStore(`const.$equips.${equipId}.api_type.0`)
  if (equipType == 21) {        // Land-base fighters
    const fullCount = 18
    if (count == fullCount) {
      return [27, 12, 0, 0]
    }
    return [Math.floor(count * 1.5 + 0.0001), Math.floor(count * 0.66), 0, 0]
  } else if (equipType == 5 || equipType == 17) {       // Reconnaissance; Large flying boat
    const fullCount = 4
    if (count == fullCount) {
      return [4, 3, 0, 0]
    }
    return [count, Math.floor(count * 0.66), 0, 0]
  } else {
    const fullCount = 18
    if (count == fullCount) {
      return [18, 11, 0, 0]
    }
    return [count, Math.floor(count * 0.66), 0, 0]
  }
}

function resourcesAutoRegenLimit() {
  const admiralLv = getStore('info.basic.api_level', 0)
  return 750 + admiralLv * 250
}

function regenResource(startResource, startTime, endTime, regenLimit, isBaux) {
  const oneMinute = 60 * 1000
  const minutesElapsed = (endTime - startTime) / oneMinute
  const regenFactor = isBaux ? (1/3) : 1
  const regenableAmount = Math.floor(minutesElapsed * regenFactor)
  return Math.max(Math.min(startResource + regenableAmount, regenLimit), startResource)
}

// Returns [fuel, 0, 0, baux].
// From http://bbs.nga.cn/read.php?tid=9759958 . It is randomly chosen whether
// it is fuel or bauxite that is consumed, therefore we need to "guess" it
// according to the change in resources.
// TODO: Do airbaseSortieConsumption and airbaseDestructionConsumption take
// place at the start of and during the process of the sortie, so that auto regen
// is effective throughout the whole sortie; or do they only take place at the
// first porting back so that you'll never reach auto-regen limit at porting?
// For now we assume that sortieCons takes place at the start of the sortie,
// while destructCons at porting.
function airbaseDestructionConsumption(baseHpLost, startResources, nowResources,
  startTime, endTime, airbaseSortieConsumption) {
  const resConsumed = Math.round(baseHpLost * 0.9 + 0.1)
  // Calculate the resources if the base had not been destructed at all
  const regenLimit = resourcesAutoRegenLimit()
  const endRawFuel = regenResource(startResources[0] - airbaseSortieConsumption[0],
    startTime, endTime, regenLimit, false)
  const endRawBaux = regenResource(startResources[3] - airbaseSortieConsumption[3],
    startTime, endTime, regenLimit, true)
  if (endRawFuel - nowResources[0] > endRawBaux - nowResources[3])
    return [resConsumed, 0, 0, 0]
  else
    return [0, 0, 0, resConsumed]
}

// Will return a result only when "valid" and "consistent"
// * Inconsistency occurs when you sortie, close poi without porting, log in from
//   another browser or device, do something else and then log back in poi.
//   Do as much as we can to check if anything changes and reject such results.
// Format: {
//   map: {
//     name: "2-5"
//     rank: undefined | 1 | 2 | 3           # 1 for easy, 3 for hard
//     hp: undefined | [<now_remaining>, <max>, <gaugeType>]
//       # undefined after cleared. gaugeType is the same as api_gauge_type
//   }
//   time: <Unix Time Milliseconds>
//   fleet: [        # Include both fleets if it's a combined fleet
//     {     # One ship
//       id: <int>           # api_id as in ships
//       shipId: <int>       # api_ship_id as in $ships
//       consumption: [<resupplyFuel>, <resupplyAmmo>, <resupplyBauxite>,
//         <repairFuel>, <repairSteel>, <jetAssaultSteel>]
//       bucket: <boolean>   # undefined at the beginning. Becomes true later.
//     }, ...
//   ]
//   fleet1Size: <int>      # undefined in the old format for a single fleet
//   supports: [            # undefined if does not have supports
//     {
//       shipId: [<int>, ...]    # api_ship_id as in $ships
//       consumption: [<fuel>, <ammo>, 0, <bauxite>]     # Fleet total
//     }, ...
//   ]
//   airbase: {
//     _startAirbase: [...]     # Same as store.info.airbase, removed after base_air_corps
//     sortie: [f, a, s, b]     # [fuel, ammo, steel, baux]
//     destruction: [f, a, s, b]    # Automatically deducted resources bc of base destruction
//     jetAssault: [f, a, s, b]
//     resupply: [f, a, s, b]   # Recorded after base_air_corps
//   }
// }
function generateResult(sortieInfo, body, endTime) {
  const {api_deck_port: nowFleets, api_material: nowResources} = body
  const nowShips = indexify(body.api_ship)
  const {
    time: startTime,
    map: sortieMap,
    resources,
    fleetId,
    fleet,
    fleetJetAssaultSteels,
    supports=[],
    airbase: sortieAirbase,
  } = sortieInfo
  const {fleet1Size=fleet.length} = sortieInfo

  /* Check consistency */
  const fleet1 = fleet.slice(0, fleet1Size)
  const fleet2 = fleet.slice(fleet1Size)
  if (!checkConsistent(map(fleet1, 'id'), get(nowFleets[fleetId-1], 'api_ship', [])))
    return
  if (fleet2.length && !checkConsistent(map(fleet2, 'id'), get(nowFleets[1], 'api_ship', [])))
    return
  if (supports && !supports.every((support) =>
    checkConsistent(support.fleet, get(nowFleets[support.fleetId], 'api_ship', []))))
    return

  const result = {}
  /* Basic info */
  result.map = sortieMap
  result.time = startTime

  /* Fleet */
  result.fleet = fleetConsumption(fleet, nowShips, fleetJetAssaultSteels)
  result.fleet1Size = fleet1Size

  /* Support */
  if (supports.length) {
    result.supports = supports.map((support) => ({
      shipId: support.fleet.map((i) => get(nowShips[i], 'api_ship_id')).filter(Boolean),
      consumption: arraySum(support.fleet.map((id) => shipExpeditionConsumption(id, nowShips))),
    }))
  }

  /* Airbase */
  if (sortieAirbase) {
    const airbaseRecord = {}
    airbaseRecord._startAirbase = sortieAirbase.info
    airbaseRecord.sortie = arraySum(flatten(
      sortieAirbase.info.filter((a) => a.api_action_kind == 1)
        .map((a) => a.api_plane_info.map(airbaseSquadronSortieConsumption))
    ))
    if (sortieAirbase.baseHpLost) {
      airbaseRecord.destruction = airbaseDestructionConsumption(
        sortieAirbase.baseHpLost,
        resources, nowResources.map(r => r.api_value),
        startTime, endTime,
        airbaseRecord.sortie)
    }
    if (sortieAirbase.jetAssaultConsumption) {
      airbaseRecord.jetAssault = sortieAirbase.jetAssaultConsumption
    }
    result.airbase = airbaseRecord
  }

  return result
}

// This constant is used for backward compatibility.
// Previous history is recorded in "recordId", while now we record in time.
// Use this as a judgement.
const TIME_LOWLIM = new Date('2015-1-1').getTime()

function useBucket(state, shipId) {
  const targetSortieTime = (pluginDataSelector(getStore()).history || {})[shipId]
  if (!targetSortieTime || targetSortieTime < TIME_LOWLIM)
    return state
  // Search from latest to earliest, since usually we care for the last few records
  forEachRight(state, (record, idx) => {
    if (record.time < targetSortieTime) {
      return false
    }
    if (record.time == targetSortieTime) {
      const shipIdx = record.fleet.findIndex((ship) => ship.id == shipId)
      if (shipIdx === -1)
        return false
      state = reduxSet(state, [idx, 'fleet', shipIdx, 'bucket'], true)
      return false
    }
  })
  return state
}

function updateAirbaseResupply(state, nowAirbase) {
  if (!nowAirbase) {
    return state
  }
  // You can't go for a new sortie without meeting base_air_corps.
  // Therefore we only need to check the last record.
  const lastRecord = state[state.length - 1]
  // record.airbase._startAirbase exists if and only if airbase resupply
  // consumption needs updating.
  const startAirbase = get(lastRecord, 'airbase._startAirbase')
  if (!startAirbase)
    return state
  // Count lost planes while checking consistency.
  let consistent = true
  const totalCountLost = sum(zipWith(startAirbase, nowAirbase, (startBase, nowBase) => {
    if (!startBase !== !nowBase)
      consistent = false
    if (!startBase || !nowBase)
      return
    if (startBase.api_action_kind !== nowBase.api_action_kind)
      consistent = false
    const baseCountLost = sum(zipWith(startBase.api_plane_info, nowBase.api_plane_info,
      (startSquadron, nowSquadron) => {
        if (startSquadron.api_slotid != nowSquadron.api_slotid) {
          consistent = false
          return 0
        }
        const countLost = startSquadron.api_count - nowSquadron.api_count
        if (countLost < 0) {
          consistent = false
        }
        return countLost
      }
    ))
    return baseCountLost
  }))
  const airbaseRecord = {...lastRecord.airbase}
  delete airbaseRecord._startAirbase
  if (consistent && totalCountLost) {
    airbaseRecord.resupply = [totalCountLost * 3, 0, 0, totalCountLost * 5]
  }
  state = state.slice()
  state[state.length - 1] = {
    ...lastRecord,
    airbase: airbaseRecord,
  }
  return state
}

export default function reducer(state=[], action) {
  const {type, result, body, postBody, time} = action
  switch (type) {
  case '@@poi-plugin-wheres-my-fuel-gone/readDataFiles':
    return fixRecords(result.records)

  case '@@Response/kcsapi/api_get_member/require_info': {
    if (get(getStore(), 'info.basic.api_member_id') != body.api_basic.api_member_id) {
      return []
    }
    break
  }
  case '@@Response/kcsapi/api_port/port': {
    // Collect sortie history
    const sortieInfo = pluginDataSelector(getStore()).sortie || {}
    if (!sortieInfo.time)        // Test if sortie record is valid
      break
    const newRecord = generateResult(sortieInfo, body, time)
    if (newRecord)
      return state.concat([newRecord])
    break
  }
  case '@@Response/kcsapi/api_req_nyukyo/start':
    if (postBody.api_highspeed == 1)
      return useBucket(state, postBody.api_ship_id)
    break
  case '@@Response/kcsapi/api_req_nyukyo/speedchange':
    return useBucket(state, getStore(`info.repairs.${postBody.api_ndock_id-1}.api_ship_id`, -1))
  case '@@Response/kcsapi/api_get_member/mapinfo':
    return updateAirbaseResupply(state, body.api_air_base)
  }
  return state
}
