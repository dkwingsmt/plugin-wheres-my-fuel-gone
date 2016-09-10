//import { promisify } from 'bluebird'
import { combineReducers } from 'redux'
import { get } from 'lodash'
import { observe, observer } from 'redux-observers'

import { saveDataObservers, migrateDataPath, readDataFiles } from './readDataFiles'
import { currentAdmiralId } from '../utils'
import { store } from 'views/create-store'
import records from './records'
import filters from './filters'
import history from './history'
import sortie from './sortie'
import modal from './modal'

export const reducer = combineReducers({
  records,
  sortie,
  filters,
  history,
  modal,
})

const initData = (function() {
  let unsubscribeSaveDataFiles = null

  return function (admiralId) {
    if (unsubscribeSaveDataFiles) {
      unsubscribeSaveDataFiles()
      unsubscribeSaveDataFiles = null
    }
    return readDataFiles(admiralId).then(() => {
      unsubscribeSaveDataFiles = observe(store, saveDataObservers)
    })
  }
})()


export const admiralIdObserver = observer(
  (state) => get(state, 'info.basic.api_member_id'),
  (dispatch, current, previous) => {
    if (current != previous) {
      initData(current)
    }
  }
)

// Migrate from nicknameId to admiralId
export const listenToNicknameId = (function() {
  let readNicknameId = false

  return function ({detail: {path, body}}) {
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
            initData(admiralId)
          }
        })
      }
    }
  }
})()

export function initDataWithAdmiralId() {
  const admiralId = currentAdmiralId()
  if (admiralId)
    initData(admiralId)
}

