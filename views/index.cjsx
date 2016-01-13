{React, ReactDOM, config} = window
{Grid, Row, Col, Input, Button, Table, Well, OverlayTrigger, Tooltip} = ReactBootstrap
path = require 'path-extra'
{TempRecord, RecordManager} = require path.join(__dirname, 'records')
_ = require 'underscore'
classnames = require 'classnames'
{MaterialIcon: RawMaterialIcon} = require path.join(ROOT, 'views', 'components', 'etc', 'icon')

colWidths = [35, 140, 180, 80, 50, 50, 50, 50, 50, 30]

resource4to5 = (res4) ->
  # From [fuel, ammo, 0, bauxite]
  # To   [fuel, ammo, bauxite, 0, 0]
  [res4[0], res4[1], res4[3], 0, 0]

resource5to4 = (res5) ->
  # From [fuel, ammo, bauxite, repairFuel, repairSteel]
  # To   [fuel, ammo, steel, bauxite]
  [res5[0]+res5[3], res5[1], res5[4], res5[2]]

insertAt = (list, data, index) ->
  list[0..index-1].concat(data).concat(list[index..])

CollapseIcon = React.createClass
  # North=angle 0, East=angle 90, South=angle 180, West=angle 270
  render: ->
    angle = if @props.open then @props.openAngle else @props.closeAngle
    rotateClass = if angle == 0 then '' else "fa-rotate-#{angle}"

    <i className={"fa fa-chevron-circle-up #{rotateClass} collapse-icon"} style=@props.style></i>

DataRow = React.createClass
  fleetSortieConsumption: (fleet) ->
    # return [fuel, ammo, steel, bauxite]
    # See format of TempRecord#generateResult
    sumArray(ship.consumption for ship in fleet)

  onToggle: ->
    @props.setRowExpanded !@props.rowExpanded

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

    # Fleet
    total5 = @fleetSortieConsumption record.fleet.concat(record.fleet2 || [])
    if record.supports?
      totalRein = sumArray [].concat(for support in record.supports
        support.consumption)
      total5 = sumArray [total5, resource4to5 totalRein]

    buckets = record.fleet.concat(record.fleet2 || []).filter((s) -> s.bucket).length

    data = [@props.id, timeText, mapText, mapHp]
    data = data.concat(if @props.colExpanded
      total5
    else
      resource5to4 total5)
    data.push buckets

    colNo = 0
    <tr onClick=@onToggle>
      <td>{[
        <CollapseIcon key='rowClosingIcon'
          open={@props.rowExpanded} closeAngle={90} openAngle={180}
          style={marginRight: '4px'} />,
        data[colNo]
      ]}
      </td>{colNo++;null}
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

CollapsibleRow = React.createClass
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
      <td colSpan=10 style={padding: 0, border: 0}>
        <div className='collapsible-wrapper' style=wrapperStyle ref='wrapper'>
          <div style={padding: 0} >
            {@props.children}
          </div>
        </div>
      </td>
    </tr>


InfoRow = React.createClass
  render: ->
    widths = colWidths.slice()
    if !@props.colExpanded
      widths[widths.length-3] = 0
    record = @props.record

    flagshipIcon = <i className="fa fa-flag" style={marginLeft: 5}></i>

    data = []
    fleet1Len = record.fleet.length
    for ship, shipSeq in record.fleet.concat(record.fleet2 || [])
      flagship = (shipSeq == 0) || (shipSeq == fleet1Len)
      rowData = ['', '', '']
      rowData.push([window.$ships?[ship.shipId]?.api_name].concat(if flagship then [flagshipIcon] else []))
      rowData = rowData.concat(if @props.colExpanded
        ship.consumption
      else
        insertAt (resource5to4 ship.consumption), '', 3)
      rowData.push (if ship.bucket then <i className="fa fa-check"></i> else null)
      data.push rowData
    for support in (record.supports || [])
      data.push(['', '', '', '(Support)'].concat(
        insertAt(support.consumption, (if @props.colExpanded then 0 else ''), 3))
        .concat(['']))

    <CollapsibleRow rowExpanded={@props.rowExpanded}>
      <Table condensed
        style={margin: -1, tableLayout: 'fixed'}>
        <tbody>
         {
          for row, rowNo in data
            <tr key={"row-#{rowNo}"}>
             {
              for col, colNo in row
                style = {width: widths[colNo], padding: 0}
                if colNo >= 3
                  style.backgroundColor = '#333'
                  style.color = '#ccc'
                <td key={"col-#{colNo}"} style={style} className='extra-col'>
                  <div style={padding: 5}>
                    {col}
                  </div>
                </td>
             }
            </tr>
         }
        </tbody>
      </Table>
    </CollapsibleRow>


MaterialIcon = React.createClass
  render: ->

    icon = <div className='icon-wrapper'>
      <RawMaterialIcon materialId={@props.materialId} />
      <span className="fa-stack footnote-icon" style={if @props.icon? then {} else {visibility: 'hidden'}}>
        <i className="fa fa-circle fa-stack-2x footnote-icon-bg"
           style={if @props.color? then {color: @props.color} else {}} ></i>
        <i className={"fa fa-#{@props.icon || 'circle'} fa-stack-1x fa-inverse footnote-icon-core"}></i>
      </span>
    </div>

    if !@props.tooltip?
      icon
    else
      <OverlayTrigger placement="bottom"
        overlay={<Tooltip id={"#{@props.id}-tooltip"}>{@props.tooltip}</Tooltip>} >
        {icon}
      </OverlayTrigger>

PluginMain = React.createClass
  getInitialState: ->
    data: []
    rowsExpanded: {}
    colExpanded: false

  componentDidMount: ->
    window.addEventListener 'game.response', @handleResponse
    
  componentWillUnmount: ->
    @recordManager?.stopListening()
    window.removeEventListener 'game.response', @handleResponse

  handleResponse: (e) ->
    {method, path, body, postBody} = e.detail
    switch path
      when '/kcsapi/api_start2'
        @recordManager = new RecordManager()
        @recordManager.onRecordUpdate @handleUpdate

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
  }

  render: ->
    colNo = 0
    widths = colWidths
    extraColWidth = if @state.colExpanded then widths[widths.length-2] else 0
    headerData = ['#', 'Time', 'Map', 'Hp']
    headerData = headerData.concat(if @state.colExpanded
       [ <MaterialIcon materialId=1 icon='battery-1' color='#DDE3FB' tooltip='Resupply fuel' key="icon11"/>, 
         <MaterialIcon materialId=2 icon='battery-1' color='#DDE3FB' tooltip='Resupply ammo' key="icon12"/>, 
         <MaterialIcon materialId=4 icon='battery-1' color='#DDE3FB' tooltip='Resupply bauxite' key="icon13"/>,
         <MaterialIcon materialId=1 icon='wrench' color='#B1DE7A' tooltip='Repair fuel' key="icon14"/>,
         <MaterialIcon materialId=3 icon='wrench' color='#B1DE7A' tooltip='Repair steel' key="icon15"/>]
    else
       [ <MaterialIcon materialId=1 key="icon21"/>, 
         <MaterialIcon materialId=2 key="icon22"/>, 
         <MaterialIcon materialId=3 key="icon23"/>,
         <MaterialIcon materialId=4 key="icon24"/>])
    headerData.push <MaterialIcon materialId=6 />

    <Table bordered condensed hover id='main-table'>
      <thead>
        <tr>
          <th style={width: widths[colNo]}>{headerData[colNo]}</th>{colNo++;null}
          <th style={width: widths[colNo]}>{headerData[colNo]}</th>{colNo++;null}
          <th style={width: widths[colNo]}>{headerData[colNo]}</th>{colNo++;null}
          <th style={width: widths[colNo]}>{headerData[colNo]}</th>{colNo++;null}
          <th style={width: widths[colNo]}>{headerData[colNo]}</th>{colNo++;null}
          <th style={width: widths[colNo]}>{headerData[colNo]}</th>{colNo++;null}
          <th style={width: widths[colNo]}>{headerData[colNo]}</th>{colNo++;null}
          <th id='extraColHeader' style={width: extraColWidth, paddingLeft: 0, paddingRight: 0} 
            className='extra-col' ref='extraColHeader'>
            <div style={width: extraColWidth}>
              {if @state.colExpanded then headerData[colNo] else ''}
            </div>
          </th>
          {(if @state.colExpanded then colNo++);null}
          <th style={position: 'relative', width: widths[colNo]} onClick={@handleSetColExpanded}>
            {[
              headerData[colNo],
              <CollapseIcon key='colClosingIcon'
                open={@state.colExpanded} closeAngle={270} openAngle={180}
                style={display: 'table-cell', position: 'absolute', right: '6px', bottom: '9px'} />
            ]}
          </th>
          {colNo++;null}
          <th style={width: widths[widths.length-1]}>
            {headerData[colNo]}
          </th>
        </tr>
      </thead>
      <tbody>
       {
        _.flatten(for record, i in @state.data
          rowExpanded = @state.rowsExpanded[record.time] || false
          [
            <DataRow 
              key={"data-#{record.time}"}
              record={record}
              rowExpanded={rowExpanded}
              colExpanded={@state.colExpanded}
              setRowExpanded={@handleSetRowExpanded.bind(this, record.time)}
              id={i+1} />,
            <InfoRow 
              key={"info-#{record.time}"}
              record={record}
              rowExpanded={rowExpanded}
              colExpanded={@state.colExpanded}
              />
          ])
       }
      </tbody>
    </Table>

ReactDOM.render <PluginMain />, $('main')
