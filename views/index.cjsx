{React, ReactDOM} = window
{join} = require 'path-extra'
Promise = require 'bluebird'
fs = Promise.promisifyAll(require 'fs-extra')
{Nav, NavItem} = ReactBootstrap
{cloneDeep} = require 'lodash'
{Provider} = require 'react-redux'

{store, extendReducer} = require 'views/create-store'
{TabMain} = require './tab_main'
{TabBookmarks} = require './tab_bookmarks'
#{RecordManager} = require './records'
{portRuleList} = require './filter_selector'
{reducer} = require './redux'

PluginMain = React.createClass
  getInitialState: ->
    nowNav: 1

  handleNav: (key) ->
    @setState
      nowNav: key

  render: ->
    decideNavShow = (key) =>
      if key == @state.nowNav
        {}
      else
        {display: 'none'}
    <div id='main-wrapper'>
      <Nav bsStyle="tabs" activeKey={@state.nowNav} onSelect={@handleNav}>
        <NavItem eventKey=1>{__ 'Table'}</NavItem>
        <NavItem eventKey=2>{__ 'Bookmarks'}</NavItem>
      </Nav>
        <div style={decideNavShow(1)} key=1>
          <TabMain />
        </div>
        <div style={decideNavShow(2)} key=2>
          <TabBookmarks />
        </div>
    </div>

extendReducer('poi-plugin-wheres-my-fuel-gone', reducer)

ReactDOM.render(
  <Provider store={store}>
    <PluginMain />
  </Provider>,
  $('main')
)
