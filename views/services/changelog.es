import React from 'react'
import { readFile, readJson } from 'fs-extra'
import { join } from 'path-extra'
import semver from 'semver'
import ReactMarkdown from 'react-remarkable'

import { store } from 'views/create-store'
import { displayModal } from '../redux/modal'

let initPromise = null

export function showChangelog() {
  if (initPromise) {
    initPromise.then(({ contents }) =>
      store.dispatch(displayModal('看看新版本更新了什么！', (
        <div className='changelog'>
          <ReactMarkdown source={contents} skipHtml />
        </div>
      )))
    )
  } else {
    console.error('No initPromise!')
  }
}

function tryShowChangelog() {
  const { config } = window
  const lastVersionConfigPath = 'plugin.poi-plugin-wheres-my-fuel-gone.lastShowChangelogVersion'
  const lastVersion = config.get(lastVersionConfigPath, '0.0.0')
  if (initPromise) {
    initPromise.then(({ contents, version }) => {
      console.warn(version, lastVersion, semver.gt(version, lastVersion))
      if (!version || semver.gt(version, lastVersion)) {
        showChangelog()
      }
      if (version && version !== lastVersion) {
        config.set(lastVersionConfigPath, version)
      }
    })
  } else {
    console.error('No initPromise!')
  }
}

export default function initChangelog() {
  const contentsPromise = readFile(join(__dirname, '../../assets/changelog-cn.md'))
  const packagePromise = readJson(join(__dirname, '../../package.json'))
  initPromise = Promise.all([contentsPromise, packagePromise])
    .then(([contents='', packageData={}]) =>
      ({ contents: `${contents}`, version: packageData.version }))
    .catch((e) => console.error(e.stack))
  initPromise.then(tryShowChangelog)
}
