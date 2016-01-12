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
    sum4([ship.consumption[0]+ship.consumption[3],
          ship.consumption[1],
          ship.consumption[4],
          ship.consumption[2]] for ship in deck)

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
    total = @deckSortieConsumption record.deck.concat(record.deck2 || [])
    if record.reinforcements?
      total = sum4 [total].concat(for reinforcement in record.reinforcements
        reinforcement.consumption)

    buckets = record.deck.concat(record.deck2 || []).filter((s) -> s.bucket).length
    <tr onClick=@onToggle>
      <td>{@props.id}   </td>
      <td>{timeText}    </td>
      <td>{mapText}     </td>
      <td>{mapHp}       </td>
      <td>{total[0]}    </td>
      <td>{total[1]}    </td>
      <td>{total[2]}    </td>
      <td>{total[3]}    </td>
      <td>
        <div>
          heyhey
        </div>
      </td>
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

  colWidths_: [
    30, 140, 180, 80, 50, 50, 50, 50, 50, 30
  ]

  render: ->
    colNo = 0
    extraColWidth = if @state.colExpanded 
      @colWidths_[@colWidths_.length-2]
    else
      0
    <Table bordered condensed hover id='main-table'>
      <thead>
        <tr>
          <th style={width: "#{@colWidths_[colNo++]}"}>{'#'}      </th>
          <th style={width: "#{@colWidths_[colNo++]}"}>{'Time'}   </th>
          <th style={width: "#{@colWidths_[colNo++]}"}>{'Map'}    </th>
          <th style={width: "#{@colWidths_[colNo++]}"}>{'Hp'}     </th>
          <th style={width: "#{@colWidths_[colNo++]}"}>{'Fuel'}   </th>
          <th style={width: "#{@colWidths_[colNo++]}"}>{'Ammo'}   </th>
          <th style={width: "#{@colWidths_[colNo++]}"}>{'Steel'}  </th>
          <th style={width: "#{@colWidths_[colNo++]}"} onClick={@handleSetColExpanded}>
            {'Bauxite'}
          </th>
          <th id='extraColHeader' style={width: extraColWidth, paddingLeft: 0, paddingRight: 0} 
            className='extra-col' ref='extraColHeader'>
            <div style={width: extraColWidth}>
              {'_'}
            </div>
          </th>
          <th style={width: "#{@colWidths_[@colWidths_.length-1]}"}>
            {'Buckets'}
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
