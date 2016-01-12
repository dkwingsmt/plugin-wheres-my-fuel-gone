{React, ReactDOM, config} = window
{Grid, Row, Col, Input, Button, Table, Well} = ReactBootstrap
path = require 'path-extra'
{TempRecord, RecordManager} = require path.join(__dirname, 'records')
_ = require 'underscore'
classnames = require 'classnames'

$('#font-awesome')?.setAttribute 'href', "#{ROOT}/components/font-awesome/css/font-awesome.min.css"

DataRow = React.createClass
  getInitialState: ->
    expanded: false
  
  deckSortieConsumption: (deck) ->
    # return [fuel, ammo, steel, bauxite]
    # See format of TempRecord#generateResult
    sum4([ship.consumption[0]+ship.consumption[3],
          ship.consumption[1],
          ship.consumption[4],
          ship.consumption[2]] for ship in deck)

  onToggle: ->
    current = !@state.expanded
    @setState
      expanded: current
    @props.setExpanded current

  render: ->
    record = @props.record
    # Date
    timeText = new Date(record.time).toLocaleString window.language,
      hour12: false

    # Map text
    mapText = "#{record.map.name}(#{record.map.id})"
    if record.map.rank?
      mapText += ['', 'Easy', 'Medium', 'Hard' ][record.map.rank]

    mapHp = if record.map.hp?
      "#{record.map.hp[0]}/#{record.map.hp[1]}"
    else
      ''

    # Deck
    total = @deckSortieConsumption record.deck
    if record.deck2?
      total = sum4 total, @deckSortieConsumption record.deck2
    if record.reinforcements?
      total = sum4 [total].concat(for reinforcement in record.reinforcements
        reinforcement.consumption)

    buckets = record.buckets || 0

    <tr onClick=@onToggle>
      <td>{@props.id}   </td>
      <td>{timeText}    </td>
      <td>{mapText}     </td>
      <td>{mapHp}       </td>
      <td>{total[0]}    </td>
      <td>{total[1]}    </td>
      <td>{total[2]}    </td>
      <td>{total[3]}    </td>
      <td>{buckets}     </td>
    </tr>

InfoRow = React.createClass
  getInitialState: ->
    height: null
    hidden: false

  componentDidMount: ->
    if !@state.height?
      @setState
        height: @refs.wrapper.offsetHeight
        hidden: true

  componentWillReceiveProps: (nextProps) ->
    return if !nextProps.expanded?
    if !@props.expanded && nextProps.expanded
      @setState
        hidden: false
    if @props.expanded && !nextProps.expanded
      # 100ms more delay
      setTimeout (=> @setState {hidden: true}), 350+100  

  render: ->
    trClasses = classnames 
      'collapsible-tr': true
      hidden1: @state.height? && @state.hidden

    wrapperStyle = if !@state.height?
      {}
    else if @props.expanded
      console.log "now prop expanded true"
      height: @state.height
    else
      console.log "now prop expanded false"
      height: 0

    <tr className=trClasses>
      <td colSpan=9 style={'padding-top': 0, 'padding-bottom': 0}>
        <div className='collapsible-wrapper' style=wrapperStyle ref='wrapper'>
          <div style={padding: '5px'} >
            {@props.record.map.name}
          </div>
        </div>
      </td>
    </tr>

PluginMain = React.createClass
  getInitialState: ->
    data: []
    rowsExpanded: {}

  componentDidMount: ->
    @recordManager = new RecordManager()
    @recordManager.onRecordUpdate @handleUpdate
  componentWillUnmount: ->
    @recordManager.stopListening()

  handleSetExpanded: (time, expanded) ->
    console.log time
    rowsExpanded = @state.rowsExpanded
    rowsExpanded[time] = expanded
    @setState {rowsExpanded}
    console.log @state
    console.log @state.rowsExpanded

  handleUpdate: ->
    if !@recordManager?
      @setState
        data: []
    else
      data = @recordManager.getRecord(null, null)
      @setState {data}

  render: ->
    <Table bordered condensed hover>
      <thead>
        <tr>
          <th>{'#'}      </th>
          <th>{'Time'}   </th>
          <th>{'Map'}    </th>
          <th>{'Hp'}     </th>
          <th>{'Fuel'}   </th>
          <th>{'Ammo'}   </th>
          <th>{'Steel'}  </th>
          <th>{'Bauxite'}</th>
          <th>{'Buckets'}</th>
        </tr>
      </thead>
      <tbody>
       {
        _.flatten(for record, i in @state.data
          [
            <DataRow 
              key={"data-#{record.time}"}
              record={record}
              setExpanded={@handleSetExpanded.bind(this, record.time)}
              id={i+1} />,
            <InfoRow 
              key={"info-#{record.time}"}
              record={record}
              expanded={@state.rowsExpanded[record.time] || false}
              />
          ])
       }
      </tbody>
    </Table>

ReactDOM.render <PluginMain />, $('main-table')
