const { copyIfSame } = window
import { pluginDataSelector } from './selectors'
import { get } from 'lodash'

const empty = {}

export default function reducer(state={}, action, store) {
  const { type, body, result } = action
  switch (type) {
  case '@@poi-plugin-wheres-my-fuel-gone/readDataFiles':
    return result.history || empty
  case '@@Response/kcsapi/api_get_member/require_info': {
    if (get(store, 'info.basic.api_member_id') != body.api_basic.api_member_id) {
      return []
    }
    break
  }

  case '@@Response/kcsapi/api_port/port': {
    const stateBackup = state
    // Collect sortie history
    const sortieInfo = pluginDataSelector(store).sortie || {}
    if (sortieInfo.time) {      // If sortie record is valid
      const { fleet: sortieShips, time: sortieTime } = sortieInfo
      state = copyIfSame(state, stateBackup)
      sortieShips.forEach((ship) => {
        state[ship.id] = sortieTime
      })
    }
    // Remove unexisting ships
    const ships = get(store, 'info.ships')
    Object.keys(state).forEach((shipId) => {
      if (!(shipId in ships)) {
        state = copyIfSame(state, stateBackup)
        delete state[shipId]
      }
    })
    return state
  }
  }
  return state
}
