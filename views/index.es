import React, { Component } from 'react'
import PropTypes from 'prop-types'
import { Nav, NavItem } from 'react-bootstrap'
import { get } from 'lodash'
import { connect  } from 'react-redux'
import { join } from 'path-extra'

import { generateRecordCalculator } from './tab_main/calculate_record'
import TabMain from './tab_main'
import TabBookmarks from './tab_bookmarks'
import TabExtra from './tab_extra'
import ModalMain from './modal'
import initServices from './services'

const { __ } = window.i18n["poi-plugin-wheres-my-fuel-gone"]

export const reactClass = connect(
  (state) => ({
    admiralId: get(state, 'info.basic.api_member_id'),
  })
)(class PluginMain extends Component {
  static childContextTypes = {
    recordCalculator: PropTypes.func.isRequired,
  }

  constructor(props) {
    super(props)
    this.state = {
      nowNav: 1,
    }
  }

  getChildContext() {
    return {
      recordCalculator: generateRecordCalculator(this.props.admiralId),
    }
  }

  handleNav = (key) => {
    this.setState({
      nowNav: key,
    })
  }

  componentDidMount() {
    initServices()
  }

  render() {
    const decideNavShow = (key) =>
      key == this.state.nowNav ?
        {}
        :
        { display: 'none' }
    return (
      <div id='wmfg-main-wrapper'>
        <link rel="stylesheet" href={join(__dirname, '..', 'assets', 'main.css')} />
        <link rel="stylesheet" href={join(__dirname, '..', 'assets', 'table.css')} />
        <div>
          <ModalMain id='modal-wrapper'/>
        </div>
        <Nav bsStyle="tabs" activeKey={this.state.nowNav} onSelect={this.handleNav}>
          <NavItem eventKey={1}>{__('Table')}</NavItem>
          <NavItem eventKey={2}>{__('Bookmarks')}</NavItem>
          <NavItem eventKey={3}>{__('Extra')}</NavItem>
        </Nav>
        <div style={decideNavShow(1)}>
          <TabMain />
        </div>
        <div style={decideNavShow(2)}>
          <TabBookmarks />
        </div>
        <div style={decideNavShow(3)}>
          <TabExtra />
        </div>
      </div>
    )
  }
})

export { reducer } from './redux'
