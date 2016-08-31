//import { promisify } from 'bluebird'
import { combineReducers } from 'redux'
import { get } from 'lodash'
import { observer } from 'redux-observers'

import { migrateDataPath, readDataFiles } from './readDataFiles'
import { currentAdmiralId } from '../utils'
import records from './records'
import filters from './filters'
import history from './history'
import sortie from './sortie'

export default combineReducers({
  records,
  sortie,
  filters,
  history,
})

export const admiralIdObserver = observer(
  (state) => get(state, 'info.basic.api_member_id'),
  (dispatch, current, previous) => {
    if (current != previous) {
      readDataFiles(current)
    }
  }
)

let readNicknameId = false

// Migrate from nicknameId to admiralId
export function listenToNicknameId({detail: {path, body}}) {
  if (path === '/kcsapi/api_start2') {
    readNicknameId = false
  }
  if (path === '/kcsapi/api_port/port') {
    if (!readNicknameId) {
      const nicknameId = body.api_basic.api_nickname_id
      const admiralId = currentAdmiralId()
      readNicknameId = true
      migrateDataPath(admiralId, nicknameId).then((shouldReRead) => {
        if (shouldReRead) {
          readDataFiles(admiralId)
        }
      })
    }
  }
}

export function initReadDataFiles() {
  const admiralId = currentAdmiralId()
  if (admiralId)
    readDataFiles(admiralId)
}

export { saveDataObservers } from './readDataFiles'
