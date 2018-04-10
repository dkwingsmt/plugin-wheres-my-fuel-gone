import { observe } from 'redux-observers'
import { admiralIdObserver, listenToNicknameId, initDataWithAdmiralId } from './views/redux'
import { store } from 'views/create-store'

let unsubscribeFunc

export const windowMode = true

export { reducer, reactClass } from './views'

export function pluginDidLoad() {
  // Read data files now if we have admiral id in store
  initDataWithAdmiralId()
  unsubscribeFunc = observe(
    store,
    // When admiral id changes, re-read data files
    [admiralIdObserver]
  )
  // The first time we got /api_port/port, read nickname_id and see if we need
  // to migrate from the old position
  window.addEventListener('game.response', listenToNicknameId)
}

export function pluginWillUnload() {
  unsubscribeFunc()
  window.removeEventListener('game.response', listenToNicknameId)
}
