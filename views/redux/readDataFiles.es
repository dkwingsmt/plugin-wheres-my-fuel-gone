import { promisify } from 'bluebird'
import { writeFile, readJson, access, move, constants as fsConstants } from 'fs-extra'
import { map, get } from 'lodash'
import { observer } from 'redux-observers'

import { pluginDataSelector } from './selectors'
import { store } from 'views/create-store'
import { pluginDataPath, currentAdmiralId } from '../utils'

// Return whether a re-read is needed
export const migrateDataPath = async (admiralId, nicknameId) => {
  const oldPath = pluginDataPath(nicknameId)
  const newPath = pluginDataPath(admiralId)
  try {
    try {
      await promisify(access)(newPath, fsConstants.F_OK)
    } catch(e) {
      try {
        await promisify(access)(oldPath, fsConstants.F_OK)
      } catch(e) {
        return false
      }
      await promisify(move)(oldPath, newPath)
      return true
    }
  } catch(e) {
    console.error(e.stack)
  }
  return false
}

const dataToSave = {
  'records': 'sortie_records.json',
  'filters': 'filters.json',
  'history': 'bucket_record.json',
}

function saveDataFile(data, filename) {
  const path = pluginDataPath(currentAdmiralId(), filename)
  if (typeof data !== 'string')
    data = JSON.stringify(data)
  return promisify(writeFile)(path, data)
}

export const saveDataObservers = map(dataToSave, (filename, field) =>
  observer(
    (state) => get(pluginDataSelector(state), field),
    (dispatch, current, previous) =>
      saveDataFile(current, filename)
  )
)

export function readDataFiles(admiralId) {
  const tasks = map(dataToSave, async (filename, field) => {
    const path = pluginDataPath(admiralId, filename)
    let data
    try {
      data = await promisify(readJson)(path)
    } catch(e) {
      console.warn(`Unable to read ${path}: `, e.stack)
      data = undefined
    }
    return [data, field]
  })
  return Promise.all(tasks).then((dataList) => {
    const result = {}
    dataList.forEach(([data, field]) => {
      result[field] = data
    })
    store.dispatch({
      type: '@@poi-plugin-wheres-my-fuel-gone/readDataFiles',
      result,
    })
  })
}
