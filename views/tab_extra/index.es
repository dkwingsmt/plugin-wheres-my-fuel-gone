import React, { Component } from 'react'
import { Grid, Col, Row, Button, ButtonGroup } from 'react-bootstrap'
import { connect } from 'react-redux'
import { get } from 'lodash'
import { shell } from 'electron'
import { ensureDirSync } from 'fs-extra'

import { displayModal } from '../redux/modal'
import { pluginDataPath } from '../utils'
import { showChangelog } from '../services/changelog'

export default connect(
  (state) => ({
    admiralId: get(state, 'info.basic.api_member_id'),
  }), {
    displayModal,
  }
)(class TabExtra extends Component {

  openDirectory(path, ensure=true) {
    try {
      if (ensure)
        ensureDirSync(path)
      shell.openItem(path)
    }
    catch (e) {
      console.error(e.stack)
      this.props.displayModal(
        __('Open records folder'),
        __("Failed. Perhaps you don't have permission to it."),
      )
    }
  }

  render() {
    const { __ } = window
    const {admiralId} = this.props
    return (
      <div className='tabcontents-wrapper'>
        <h3>设置</h3>
        <p>现在还没有什么设置项目 :(</p>
        <h3>关于耗资记录</h3>
        <p>
          耗资记录是一个记录舰队出击消耗资源、并加以统计和分析的插件。本插件现在支持的项目有：
          <ul>
            <li> 舰队出击补给及破损；</li>
            <li> 入渠耗桶；</li>
            <li> 联合舰队；</li>
            <li> 支援舰队补给。</li>
          </ul>
          暂不支持的项目有：
          <ul>
            <li> 排除未实际补给/维修的船；</li>
            <li> 演习耗资；</li>
            <li> 基地航空队的相关耗资；</li>
            <li> 道中资源点的资源获取；</li>
            <li> 从道中捞得的船上获取的资源。</li>
          </ul>
        </p>

        <ButtonGroup>
          <Button bsStyle='info' onClick={showChangelog} >
            {__('Changelog')}
          </Button>
          <Button bsStyle='info' disabled={!admiralId}
            onClick={() => this.openDirectory(pluginDataPath(admiralId))}
          >
            {__('Open records folder')}
          </Button>
        </ButtonGroup>
      </div>
    )
  }
})
