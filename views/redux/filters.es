import { cloneDeep, omit } from 'lodash'

export default function reducer(state={}, action) {
  const {type, result} = action
  switch (type) {
  case '@@poi-plugin-wheres-my-fuel-gone/readDataFiles':
    return result.filters || {}
  case '@@poi-plugin-wheres-my-fuel-gone/filters/add':
    return {
      ...state,
      [Date.now()]: {
        rules: cloneDeep(action.rules),
        name: window.__('New filter'),
      },
    }
  case '@@poi-plugin-wheres-my-fuel-gone/filters/remove':
    return omit(state, [action.time])
  case '@@poi-plugin-wheres-my-fuel-gone/filters/rename':
    return {
      ...state,
      [action.time]: {
        ...state[action.time],
        name: action.name,
      },
    }
  }
  return state
}

export function addFilter(rules) {
  return {
    type: '@@poi-plugin-wheres-my-fuel-gone/filters/add',
    rules,
  }
}

export function removeFilter(time) {
  return {
    type: '@@poi-plugin-wheres-my-fuel-gone/filters/remove',
    time,
  }
}

export function renameFilter(time, name) {
  return {
    type: '@@poi-plugin-wheres-my-fuel-gone/filters/rename',
    time,
    name,
  }
}
