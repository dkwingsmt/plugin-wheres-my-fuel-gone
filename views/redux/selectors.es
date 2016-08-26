import { createSelector } from 'reselect'

import {
  extensionSelectorFactory,
} from 'views/utils/selectors'

const empty = {}

export const pluginDataSelector = createSelector(
  extensionSelectorFactory('poi-plugin-wheres-my-fuel-gone'),
  (state) => state || empty
)
