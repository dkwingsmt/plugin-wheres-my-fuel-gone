{React} = window
{Row, Col, Button, Table, OverlayTrigger, Tooltip} = ReactBootstrap
path = require 'path-extra'
classnames = require 'classnames'
{sum} = require 'lodash'

{MaterialIcon: RawMaterialIcon} = require path.join(ROOT, 'views', 'components', 'etc', 'icon')

colWidths = [45, 140, 180, 80, 50, 50, 50, 50, 30]

insertAt = (list, data, index) ->
  list[0..index-1].concat(data).concat(list[index..])

CollapseIcon = React.createClass
  # North=angle 0, East=angle 90, South=angle 180, West=angle 270
  render: ->
    angle = if @props.open then @props.openAngle else @props.closeAngle
    rotateClass = if angle == 0 then '' else "fa-rotate-#{angle}"

    <i className={"fa fa-chevron-circle-up #{rotateClass} collapse-icon"} style=@props.style></i>

SumRow = React.createClass
  render: ->
    sumData = @props.sumData
    buckets = sumData[5]
    data = resource5to4(sumData[0..4]).concat(buckets)
    <tr className='info'>
      <td>*</td>
      <td colSpan=3><em>{__ 'Sum of %s sorties', @props.sortieTimes}</em></td>
      {
        for n in data
          <td>{n}</td>
      }
    </tr>

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
      mapText += ['', __('Easy'), __('Medium'), __('Hard')][record.map.rank]

    mapHp = if record.map.hp?
      "#{record.map.hp[0]}/#{record.map.hp[1]}"
    else
      ''

    # Fleet
    total4 = resource5to4 @fleetSortieConsumption record.fleet
    if record.supports?
      totalSupport = sumArray record.supports.map((support) => support.consumption)
      total4 = sumArray [total4, totalSupport]

    buckets = record.fleet.filter((s) -> s.bucket).length
    if buckets == 0
      buckets = ''      # Do not display 0 bucket for clarity

    data = [@props.id, timeText, mapText, mapHp]
    data = data.concat total4
    data.push buckets

    <tr onClick=@onToggle>
      <td>{[
        <CollapseIcon key='rowClosingIcon'
          open={@props.rowExpanded} closeAngle={90} openAngle={180}
          style={marginRight: '4px'} />,
        data[0]
      ]}
      </td>
      {
        for i in [1...data.length]
          <td key={i}>{data[i]}</td>
      }
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
      # Check rowExpanded again in case another click happens before it 
      setTimeout (=> @setState {hidden: true} if !@props.rowExpanded), 350+100

  render: ->
    trClasses = classnames 
      hidden: @state.hidden

    wrapperStyle = if !@state.realHeight?
      {}
    else
      height: @state.height

    <tr className=trClasses style={backgroundColor: 'inherit'}>
      <td colSpan={colWidths.length} style={padding: 0, border: 0}>
        <div className='collapsible-wrapper' style=wrapperStyle ref='wrapper'>
          <div style={padding: 0} >
            {@props.children}
          </div>
        </div>
      </td>
    </tr>


DetailRow = React.createClass
  render: ->
    widths = [sum(colWidths[0..3])].concat(colWidths[4..])
    record = @props.record

    flagshipIcon = <i className='fa fa-flag inline-icon'></i>

    data = []

    fleetResources = sumArray record.fleet.map (ship) -> ship.consumption

    # Supply
    supplyResources = resource5toSupply fleetResources
    data.push [__ 'Resupply'].concat(supplyResources).concat('')

    # Repair
    repairResources = resource5toRepair fleetResources
    buckets = record.fleet.filter((s) -> s.bucket).length
    if sum(repairResources) + buckets
      data.push [__ 'Repair'].concat(repairResources).concat(buckets)

    # Support
    if record.supports
      supportResources = resource5to4 sumArray record.supports.map (s) -> s.consumption
      data.push [__ 'Support'].concat(supportResources).concat('')

    <CollapsibleRow rowExpanded={@props.rowExpanded}>
      <Table condensed
        style={tableLayout: 'fixed', margin: 0}>
        <tbody>
         {
          for row, rowNo in data
            <tr key={"row-#{rowNo}"}>
             {
              for col, colNo in row
                style = {width: widths[colNo], padding: 0, color: '#ccc'}
                if colNo == 0
                  style.textAlign = 'right'
                else
                  style.backgroundColor = '#333'
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
      <span className='fa-stack footnote-icon' style={if @props.icon? then {} else {visibility: 'hidden'}}>
        <i className='fa fa-circle fa-stack-2x footnote-icon-bg'
           style={if @props.color? then {color: @props.color} else {}} ></i>
        <i className={"fa fa-#{@props.icon || 'circle'} fa-stack-1x fa-inverse footnote-icon-core"}></i>
      </span>
    </div>

    if !@props.tooltip?
      icon
    else
      <OverlayTrigger placement='bottom'
        overlay={<Tooltip id={"#{@props.id}-tooltip"}>{@props.tooltip}</Tooltip>} >
        {icon}
      </OverlayTrigger>

MainTable = React.createClass
  getInitialState: ->
    rowsExpanded: {}

  handleSetRowExpanded: (time, expanded) ->
    rowsExpanded = @state.rowsExpanded
    rowsExpanded[time] = expanded
    @setState {rowsExpanded}

  render: ->
    data = @props.data
    startNo = @props.startNo

    headerData = ['#', __('Time'), __('World'), __('World health')]
    headerData = headerData.concat([
         <MaterialIcon materialId=1 key='icon21'/>, 
         <MaterialIcon materialId=2 key='icon22'/>, 
         <MaterialIcon materialId=3 key='icon23'/>,
         <MaterialIcon materialId=4 key='icon24'/>,
         <MaterialIcon materialId=6 key='icon25'/>
         ])

    <Table bordered condensed hover id='main-table'>
      <thead>
        <tr>
        {
          for i in [0...(colWidths.length)]
            <th key={i} style={width: colWidths[i]}>{headerData[i]}</th>
        }
        </tr>
      </thead>
      <tbody>
       {
        if @props.sumData
          <SumRow sumData={@props.sumData} sortieTimes={@props.sortieTimes} />
       }
       {
        for record, i in data
          rowExpanded = @state.rowsExpanded[record.time] || false
          displayId = startNo + i + 1
          [
            <DataRow 
              key={"data-#{record.time}-#{i}"}
              record={record}
              rowExpanded={rowExpanded}
              setRowExpanded={@handleSetRowExpanded.bind(this, record.time)}
              id={displayId} />,
            <DetailRow 
              key={"info-#{record.time}-#{i}"}
              record={record}
              rowExpanded={rowExpanded}
              />
          ]
       }
      </tbody>
    </Table>

module.exports = {MainTable}
