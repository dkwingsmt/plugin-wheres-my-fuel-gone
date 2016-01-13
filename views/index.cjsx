{React, ReactDOM, config} = window
{Grid, Row, Col, Input, Button, Table, Well} = ReactBootstrap
path = require 'path-extra'
{TempRecord, RecordManager} = require path.join(__dirname, 'records')
_ = require 'underscore'
classnames = require 'classnames'

$('#font-awesome')?.setAttribute 'href', "#{ROOT}/components/font-awesome/css/font-awesome.min.css"

DataRow = React.createClass
  getInitialState: ->
    rowExpanded: false

  deckSortieConsumption: (deck) ->
    # return [fuel, ammo, steel, bauxite]
    # See format of TempRecord#generateResult
    sumArray(ship.consumption for ship in deck)

  onToggle: ->
    current = !@state.rowExpanded
    @setState
      rowExpanded: current
    @props.setRowExpanded current

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
    total5 = @deckSortieConsumption record.deck.concat(record.deck2 || [])
    if record.reinforcements?
      totalRein = sumArray [].concat(for reinforcement in record.reinforcements
        reinforcement.consumption)
      total5 = sumArray [total5, [totalRein[0], totalRein[1], totalRein[3], 0, 0]]

    buckets = record.deck.concat(record.deck2 || []).filter((s) -> s.bucket).length

    data = [@props.id, timeText, mapText, mapHp]
    data = data.concat(if @props.colExpanded
      # fuel, ammo, bauxite, repairFuel, repairSteel
      total5
    else
      # fuel, ammo, steel, bauxite
      [total5[0]+total5[3], total5[1], total5[4], total5[2]])
    data.push buckets

    colNo = 0
    <tr onClick=@onToggle>
      <td>{data[colNo]}</td>{colNo++;null}
      <td>{data[colNo]}</td>{colNo++;null}
      <td>{data[colNo]}</td>{colNo++;null}
      <td>{data[colNo]}</td>{colNo++;null}
      <td>{data[colNo]}</td>{colNo++;null}
      <td>{data[colNo]}</td>{colNo++;null}
      <td>{data[colNo]}</td>{colNo++;null}
      <td>
        <div>
          {if @props.colExpanded then data[colNo] else ''}
        </div>
      </td>
      {(if @props.colExpanded then colNo++);null}
      <td>{data[colNo]}</td>{colNo++;null}
      <td>{data[colNo]}</td>{colNo++;null}
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
        hidden: !@props.rowExpanded
        height: if @props.rowExpanded then realHeight else 0

  componentWillReceiveProps: (nextProps) ->
    return if !nextProps.rowExpanded?
    if !@props.rowExpanded && nextProps.rowExpanded
      @setState
        hidden: false
      # A height change started at "display: none" will not trigger transition
      # Therefore we change height after a 1ms timeout of removing display-none
      setTimeout (=> @setState {height: @state.realHeight}), 1
    if @props.rowExpanded && !nextProps.rowExpanded
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
      <td colSpan=10 style={paddingTop: 0, paddingBottom: 0}>
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
    colExpanded: false

  componentDidMount: ->
    @recordManager = new RecordManager()
    @recordManager.onRecordUpdate @handleUpdate
  componentWillUnmount: ->
    @recordManager.stopListening()

  handleSetRowExpanded: (time, expanded) ->
    rowsExpanded = @state.rowsExpanded
    rowsExpanded[time] = expanded
    @setState {rowsExpanded}

  handleSetColExpanded: ->
    colExpanded = !@state.colExpanded
    @setState {colExpanded}

  handleUpdate: ->
    if !@recordManager?
      @setState
        data: []
    else
      data = @recordManager.getRecord(null, null)
      @setState {data}

  statics: {
    colWidths: [30, 140, 180, 80, 50, 50, 50, 50, 50, 30]
  }

  render: ->
    colNo = 0
    widths = @constructor.colWidths
    extraColWidth = if @state.colExpanded then widths[widths.length-2] else 0
    headerData = ['#', 'Time', 'Map', 'Hp']
    headerData = headerData.concat(if @state.colExpanded
       ['F', 'A', 'B', 'DF', 'DS']
    else
       ['F', 'A', 'S', 'B'])
    headerData.push 'Bu'

    <Table bordered condensed hover id='main-table'>
      <thead>
        <tr>
          <th style={width: "#{widths[colNo]}"}>{headerData[colNo]}</th>{colNo++;null}
          <th style={width: "#{widths[colNo]}"}>{headerData[colNo]}</th>{colNo++;null}
          <th style={width: "#{widths[colNo]}"}>{headerData[colNo]}</th>{colNo++;null}
          <th style={width: "#{widths[colNo]}"}>{headerData[colNo]}</th>{colNo++;null}
          <th style={width: "#{widths[colNo]}"}>{headerData[colNo]}</th>{colNo++;null}
          <th style={width: "#{widths[colNo]}"}>{headerData[colNo]}</th>{colNo++;null}
          <th style={width: "#{widths[colNo]}"}>{headerData[colNo]}</th>{colNo++;null}
          <th id='extraColHeader' style={width: extraColWidth, paddingLeft: 0, paddingRight: 0} 
            className='extra-col' ref='extraColHeader'>
            <div style={width: extraColWidth}>
              {if @state.colExpanded then headerData[colNo] else ''}
            </div>
          </th>
          {(if @state.colExpanded then colNo++);null}
          <th style={width: "#{widths[colNo]}"} onClick={@handleSetColExpanded}>
            {headerData[colNo]}
          </th>
          {colNo++;null}
          <th style={width: "#{widths[widths.length-1]}"}>
            {headerData[colNo]}
          </th>
        </tr>
      </thead>
      <tbody>
       {
        _.flatten(for record, i in @state.data
          [
            <DataRow 
              key={"data-#{record.time}"}
              record={record}
              setRowExpanded={@handleSetRowExpanded.bind(this, record.time)}
              colExpanded={@state.colExpanded}
              id={i+1} />,
            <InfoRow 
              key={"info-#{record.time}"}
              record={record}
              rowExpanded={@state.rowsExpanded[record.time] || false}
              colExpanded={@state.colExpanded}
              />
          ])
       }
      </tbody>
    </Table>

ReactDOM.render <PluginMain />, $('main')
