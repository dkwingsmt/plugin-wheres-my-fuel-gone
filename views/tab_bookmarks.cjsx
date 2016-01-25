{React, ReactDOM} = window
{Grid, Col, Row, Alert, Panel} = ReactBootstrap
InlineEdit = require('react-edit-inline').default
path = require 'path-extra'

{MaterialIcon} = require path.join(ROOT, 'views', 'components', 'etc', 'icon')
{translateRuleList} = require path.join(__dirname, 'filter_selector')

BookmarkTile = React.createClass
  render: ->
    fullRecords = @props.fullRecords
    filterJson = @props.filterJson
    filter = translateRuleList filterJson.rules
    if filter.errors
      title = [<i className="fa fa-exclamation-triangle icon-margin-right-5"></i>,
        __ 'Invalid filter']
      body = <ul className="error-ul">
       {
        for error in filter.errors
          <li>{error}</li>
       }
      </ul>
    else
      data = fullRecords.filter filter.func
      time = filterJson.time
      consumption = sumUpConsumption data
      consumption = resource5to4(consumption[0..4]).concat(consumption[5])
      title = [<InlineEdit
        validate={(text) -> (text.length > 0 && text.length < 32)}
        text={filterJson.name}
        paramName="name"
        className="name-editing"
        activeClassName="name-editing-active"
        change={@props.onChangeName}
        />
        <i className="fa fa-pencil-square-o title-hover-show-inline grey-icon icon-margin-left-5"></i> ]
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
              <i className="fa fa-paper-plane-o"></i>
            </div>
            {__ "%s sorties", data.length}
          </Col>
        </Row>
    header = <div style={position: 'relative'}>
        { title }
        <div style={position: 'absolute', top: 0, right: 0} 
          className="bookmark-hover-show">
          <i className="fa fa-trash-o remove-rule-icon"
            onClick={@props.onRemoveFilter}></i>
        </div>
      </div>
    <div className="col-xs-12 bookmark-width">
      <Panel key="bookmark-#{time}" style={maxWidth: 430}
        className="bookmark-panel" header={header} >
        { body }
      </Panel>
    </div>

TabBookmarks = React.createClass
  changeName: (time, value) ->
    name = value.name
    @props.onChangeFilterName? time, name

  removeFilter: (time) ->
    @props.onRemoveFilter? time

  render: ->
    fullRecords = @props.fullRecords
    <div className='tabcontents-wrapper'>
     {
      if !@props.filterList || !Object.keys(@props.filterList).length
        <Alert bsStyle="warning" style={maxWidth: 800}>
          <h3>
            {__ "You do not have any filters currently"}
          </h3>
          {__ "Create a filter in the Table tab, and bookmark it to show it here"}
        </Alert>
      else
        <div>
         {
          for time, filterJson of @props.filterList
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

module.exports = {TabBookmarks}
