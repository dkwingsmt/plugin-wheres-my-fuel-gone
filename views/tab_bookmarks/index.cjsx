{React, ReactDOM} = window
{Grid, Col, Row, Alert, Panel} = ReactBootstrap
InlineEdit = require('react-edit-inline').default
{join} = require 'path-extra'
classnames = require 'classnames'
{ connect } = require 'react-redux'

{MaterialIcon} = require join(ROOT, 'views', 'components', 'etc', 'icon')
{translateRuleList} = require '../filter_selector'
{ pluginDataSelector } = require '../redux/selectors'
{ addFilter, removeFilter, renameFilter } = require '../redux/filters'

HalfCollapsiblePanel = React.createClass
  getInitialState: ->
    showDetail: false

  onSwitchDetail: ->
    cur = !@state.showDetail
    @setState
      showDetail: cur
    @props.onToggleExpanded? cur

  mouseOverDetailPanel: (cur) ->
    @setState
      hoverDetailPanel: cur

  render: ->
    # Hover over 1|2 should highlight 1&2
    # Through css we can achieve 1:hover->1, 1:hover->2, 2:hover->2
    # We must use js to achieve 2:hover->1
    wrapperClassName = classnames 'hcp-wrapper', @props.wrapperClassName
    panel1ClassName = classnames 'hcp-panel1',
      'hcp-hover-highlight': !@state.hoverDetailPanel
      'hcp-panel-highlight': @state.hoverDetailPanel
      @props.panel1ClassName
    panel2ClassName = classnames 'hcp-panel2 hcp-hover-highlight',
      @props.panel2ClassName
    <div className={wrapperClassName}>
      <div className='hcp-hover-highlight-from' onClick={@onSwitchDetail}>
        <Panel className={panel1ClassName} header={@props.header}>
          { @props.panel1Body }
        </Panel>
      </div>
      {
        if @props.panel2Body?
          <div className='hcp-panel2-psuedo hcp-hover-highlight-to'
            onClick={@onSwitchDetail}>
            <div className='hcp-panel2-positioner'>
              <Panel className={panel2ClassName}
                collapsible expanded={@state.showDetail}
                onMouseOver={@mouseOverDetailPanel.bind(this, true)}
                onMouseLeave={@mouseOverDetailPanel.bind(this, false)}
                >
                { @props.panel2Body || '' }
              </Panel>
            </div>
          </div>
      }
    </div>

BookmarkTile = React.createClass
  getInitialState: ->
    showDetail: false

  onSwitchDetail: (cur) ->
    @setState
      showDetail: cur

  render: ->
    fullRecords = @props.fullRecords
    filterJson = @props.filterJson
    filter = translateRuleList filterJson.rules
    if filter.errors
      title = [<i className='fa fa-exclamation-triangle icon-margin-right-5' key=1></i>,
        <span key=2>{__ 'Invalid filter'}</span>]
      body = <ul className='bookmark-ul'>
       {
        for error, i in filter.errors
          <li key=i>{error}</li>
       }
      </ul>
    else
      data = fullRecords.filter filter.func
      ruleTexts = filter.texts || []
      consumption = sumUpConsumption data
      consumption = resource5to4(consumption[0..4]).concat(consumption[5])
      title = [<InlineEdit
        key='name-text'
        validate={(text) -> (text.length > 0 && text.length < 32)}
        text={filterJson.name}
        paramName='name'
        className='bookmark-name-editing'
        activeClassName='bookmark-name-editing-active'
        change={@props.onChangeName}
        stopPropagation
        />
        <i className='fa fa-pencil-square-o bookmark-title-icon-hover-show grey-icon icon-margin-left-5'
          key='name-edit-icon'></i> ]
      body = 
        <Row>
          {
            for [num, iconNo] in _.zip(consumption, [1, 2, 3, 4, 6])
              <Col xs=3 key={iconNo}>
                <div className='bookmark-icon-wrapper'>
                  <MaterialIcon materialId={iconNo} />
                </div>
                {num}
              </Col>
          }
          <Col xs=9>
            <div className='bookmark-icon-wrapper'>
              <i className='fa fa-paper-plane-o'></i>
            </div>
            {__ "%s sorties", data.length}
          </Col>
        </Row>
      body2 =
        <ul className='bookmark-ul'>
         {
          for ruleText, i in ruleTexts
            <li key={i}>
              {ruleText}
            </li>
         }
        </ul>
    removeWrapperStyle = classnames {'bookmark-hover-show': !@state.showDetail}
    header = <div style={position: 'relative'}>
        { title }
        <div style={position: 'absolute', top: 0, right: 0} 
          className={removeWrapperStyle}>
          <i className='fa fa-trash-o remove-rule-icon'
            onClick={@props.onRemoveFilter}></i>
        </div>
      </div>
    <HalfCollapsiblePanel
      wrapperClassName='col-xs-12 bookmark-width'
      panel1ClassName='bookmark-maxwidth bookmark-panel'
      panel2ClassName='bookmark-maxwidth'
      header={header}
      panel1Body={body}
      panel2Body={body2}
      onToggleExpanded={@onSwitchDetail}
      />

TabBookmarks = connect(
  (state) =>
    records: pluginDataSelector(state).records,
    filters: pluginDataSelector(state).filters,
  , {addFilter, removeFilter, renameFilter}
)(React.createClass
  changeName: (time, value) ->
    name = value.name
    @props.renameFilter time, name

  removeFilter: (time) ->
    @props.removeFilter time

  render: ->
    fullRecords = @props.records
    <div className='tabcontents-wrapper'>
     {
      if !@props.filters || !Object.keys(@props.filters).length
        <Alert bsStyle="warning" style={maxWidth: 800}>
          <h3>
            {__ "You do not have any filters currently"}
          </h3>
          {__ "Create a filter in the Table tab, and bookmark it to show it here"}
        </Alert>
      else
        <div>
         {
          for time, filterJson of @props.filters
            <BookmarkTile
              key={"bookmark-#{time}"}
              fullRecords=fullRecords
              filterJson=filterJson
              onRemoveFilter={@removeFilter.bind(this, time)}
              onChangeName={@changeName.bind(this, time)}
              />
              
         }
        </div>
     }
    </div>
)

module.exports = {TabBookmarks}
