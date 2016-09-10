import React, { Component } from 'react'
import ReactDOM from 'react-dom'
import { join } from 'path-extra'
import Promise from 'bluebird'
import { Nav, NavItem } from 'react-bootstrap'
import { cloneDeep } from 'lodash'
import { Provider } from 'react-redux'

import { store, extendReducer } from 'views/create-store'
import { TabMain } from './tab_main'
import { TabBookmarks } from './tab_bookmarks'
import { portRuleList } from './filter_selector'
import ModalMain from './modal'
import { reducer } from './redux'
import initServices from './services'

class PluginMain extends Component {
  constructor(props) {
    super(props)
    this.state = {
      nowNav: 1,
    }
  }

  handleNav = (key) => {
    this.setState({
      nowNav: key,
    })
  }

  render() {
    const decideNavShow = (key) =>
      key == this.state.nowNav ?
        {}
      :
        {display: 'none'}
    return (
      <div id='main-wrapper'>
        <div>
          <ModalMain id='modal-wrapper'/>
        </div>
        <Nav bsStyle="tabs" activeKey={this.state.nowNav} onSelect={this.handleNav}>
          <NavItem eventKey={1}>{__('Table')}</NavItem>
          <NavItem eventKey={2}>{__('Bookmarks')}</NavItem>
        </Nav>
          <div style={decideNavShow(1)} key={1}>
            <TabMain />
          </div>
          <div style={decideNavShow(2)} key={2}>
            <TabBookmarks />
          </div>
      </div>
    )
  }
}

extendReducer('poi-plugin-wheres-my-fuel-gone', reducer)

initServices()

ReactDOM.render(
  <Provider store={store}>
    <PluginMain />
  </Provider>,
  $('main')
)
