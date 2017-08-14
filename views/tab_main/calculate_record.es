import {defaultMemoize} from 'reselect'
import {constant} from 'lodash'
import { arraySum } from 'views/utils/tools'

// Same as arraySum, but in order to fix
//   arraySum([]) => []
// We define
//   safeArraySum([]) => [0, 0, 0, 0]
function safeArraySum(arrays) {
  return arraySum([[0, 0, 0, 0]].concat((arrays || []).filter(Boolean)))
}

//  Return: {
//    sum: <FASB>
//    bucketNum: <int>
//    fleet: {
//      sum: <FASB>
//      repair: <FASB>
//      resupply: <FASB>
//      ships: [<FASB>] for each ship
//      bucketNum: <int>
//    }
//    supports: {
//      sum: <FASB>
//    }
//    airbase: {
//      sum: <FASB>
//    }
//  }
const calculateRecordCore = (record) => {

  const result = {}

  const sumCollection = []

  // fleet
  const fleetShips = []
  const repairCollection = []
  const resupplyCollection = []
  let bucketNum = 0
  record.fleet.forEach(({consumption, bucket}) => {
    const resupplyRow = [consumption[0], consumption[1], 0, consumption[2]]
    const repairRow = [consumption[3], 0, consumption[4], 0]
    const rowSum = safeArraySum([resupplyRow, repairRow])
    if (bucket) {
      bucketNum++
    }
    sumCollection.push(rowSum)
    fleetShips.push(rowSum)
    repairCollection.push(repairRow)
    resupplyCollection.push(resupplyRow)
  })
  result.fleet = {
    sum: safeArraySum(fleetShips),
    bucketNum,
    ships: fleetShips,
    repair: safeArraySum(repairCollection),
    resupply: safeArraySum(resupplyCollection),
  }

  // supports
  const supportsSum = safeArraySum(
    (record.supports || []).map(({consumption}) => consumption)
  )
  if (record.supports) {
    sumCollection.push(supportsSum)
    result.supports = {
      sum: supportsSum,
    }
  }

  // airbase
  const recordAirbase = record.airbase || {}
  const airbaseSum = safeArraySum([
    recordAirbase.sortie,
    recordAirbase.destruction,
    recordAirbase.jetAssault,
    recordAirbase.resupply,
  ])
  if (record.airbase) {
    sumCollection.push(airbaseSum)
    result.airbase = {
      sum: airbaseSum,
    }
  }

  // sum
  result.sum = safeArraySum(sumCollection)
  result.bucketNum = result.fleet.bucketNum

  return result
}

// USAGE:
//   const recordCalculator = generateRecordCalculator(admiralId)
//   recordCalculator(record) // => result
export const generateRecordCalculator = defaultMemoize((admiralId) => {
  if (!admiralId) {
    return constant({sum: [0, 0, 0, 0]})
  }
  const cache = {}
  return (record) => {
    const key = record.time
    if (!cache[key]) {
      cache[key] = defaultMemoize(calculateRecordCore)
    }
    return cache[key](record)
  }
})
