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
    realHeight: null
    height: 0
    hidden: false

  componentDidMount: ->
    # Init render: Force showing, get height, and switch to normal mode
    if !@state.realHeight?
      realHeight = @refs.wrapper.offsetHeight
      @setState
        realHeight: realHeight
        hidden: !@props.expanded
        height: if @props.expanded then realHeight else 0

  componentWillReceiveProps: (nextProps) ->
    return if !nextProps.expanded?
    if !@props.expanded && nextProps.expanded
      @setState
        hidden: false
      # A height change started at "display: none" will not trigger transition
      # Therefore we change height after a 1ms timeout of removing display-none
      setTimeout (=> @setState {height: @state.realHeight}), 1
    if @props.expanded && !nextProps.expanded
      @setState
        height: 0
      # Allow an extra 100ms timeout before hiding 
      setTimeout (=> @setState {hidden: true}), 350+100

  render: ->
    trClasses = classnames 
      hidden: @state.hidden

    wrapperStyle = if !@state.realHeight?
      {}
    else
      height: @state.height

    <tr className=trClasses>
      <td colSpan=9 style={paddingTop: 0, paddingBottom: 0}>
        <div className='collapsible-wrapper' style=wrapperStyle ref='wrapper'>
          <div style={paddingTop: '5px', paddingBottom: '5px'} >
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
    rowsExpanded = @state.rowsExpanded
    rowsExpanded[time] = expanded
    @setState {rowsExpanded}

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
