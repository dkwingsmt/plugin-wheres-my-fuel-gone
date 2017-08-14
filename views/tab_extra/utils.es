import { get } from 'lodash'

export const CONFIG_PREFIX = 'poi-plugin-wheres-my-fuel-gone'

export const sortieFleetDisplayModeSelector = (state) =>
  get(state.config, `${CONFIG_PREFIX}.sortieFleetDisplayMode`, 'ship')
