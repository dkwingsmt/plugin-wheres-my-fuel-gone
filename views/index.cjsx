{React, ReactDOM, config} = window
{Grid, Row, Col, Input, Button, Table, Well} = ReactBootstrap
path = require 'path-extra'
{TempRecord, RecordManager} = require path.join(__dirname, 'records')
_ = require 'underscore'
classnames = require 'classnames'
{MaterialIcon: RawMaterialIcon} = require path.join(ROOT, 'views', 'components', 'etc', 'icon')

$('#font-awesome')?.setAttribute 'href', "#{ROOT}/components/font-awesome/css/font-awesome.min.css"

resource4to5 = (res4) ->
  # From [fuel, ammo, 0, bauxite]
  # To   [fuel, ammo, bauxite, 0, 0]
  [res4[0], res4[1], res4[3], 0, 0]

resource5to4 = (res5) ->
  # From [fuel, ammo, bauxite, repairFuel, repairSteel]
  # To   [fuel, ammo, steel, bauxite]
  [res5[0]+res5[3], res5[1], res5[4], res5[2]]

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
      total5 = sumArray [total5, resource4to5 totalRein]

    buckets = record.deck.concat(record.deck2 || []).filter((s) -> s.bucket).length

    data = [@props.id, timeText, mapText, mapHp]
    data = data.concat(if @props.colExpanded
      total5
    else
      resource5to4 total5)
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

MaterialIcon = React.createClass
  render: ->
    <div className='icon-wrapper'>
      <RawMaterialIcon materialId={@props.materialId} />
      <span className="fa-stack footnote-icon" style={if @props.icon? then {} else {visibility: 'hidden'}}>
        <i className="fa fa-circle fa-stack-2x footnote-icon-bg"
           style={if @props.color? then {color: @props.color} else {}} ></i>
        <i className={"fa fa-#{@props.icon || 'circle'} fa-stack-1x fa-inverse footnote-icon-core"}></i>
      </span>
    </div>

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
       [<MaterialIcon materialId=1 icon='battery-1' color='#DDE3FB' />, 
         <MaterialIcon materialId=2 icon='battery-1' color='#DDE3FB' />, 
         <MaterialIcon materialId=4 icon='battery-1' color='#DDE3FB' />,
         <MaterialIcon materialId=1 icon='wrench' color='#B1DE7A' />,
         <MaterialIcon materialId=3 icon='wrench' color='#B1DE7A' />]
    else
       [<MaterialIcon materialId=1 />, 
         <MaterialIcon materialId=2 />, 
         <MaterialIcon materialId=3 />,
         <MaterialIcon materialId=4 />])
    headerData.push <MaterialIcon materialId=6 />

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
