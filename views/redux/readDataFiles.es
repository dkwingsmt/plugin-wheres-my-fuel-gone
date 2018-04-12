import { readJson, access, move, F_OK } from 'fs-extra'
import { map, get } from 'lodash'
import { observer } from 'redux-observers'

import { pluginDataSelector } from './selectors'
import { store } from 'views/create-store'
import { ioWorker } from 'views/services/worker'
import { pluginDataPath, currentAdmiralId } from '../utils'

ioWorker.initialize()

// Return whether a re-read is needed
export const migrateDataPath = async (admiralId, nicknameId) => {
  const oldPath = pluginDataPath(nicknameId)
  const newPath = pluginDataPath(admiralId)
  try {
    try {
      await access(newPath, F_OK)
    } catch(e) {
      try {
        await access(oldPath, F_OK)
      } catch(e) {
        return false
      }
      await move(oldPath, newPath)
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
  'sortie': '_temp_records.json',
}

function saveDataFile(data, filename) {
  if (!data || Object.keys(data).length === 0) return
  const path = pluginDataPath(currentAdmiralId(), filename)
  return ioWorker.port.postMessage(['WriteFile', path, data])
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
      data = await readJson(path)
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
