{React, ReactDOM, config} = window
{Grid, Row, Col, Input, Button, Table, Well} = ReactBootstrap
path = require 'path-extra'
{TempRecord, RecordManager} = require path.join(__dirname, 'records')
_ = require 'underscore'

$('#font-awesome')?.setAttribute 'href', "#{ROOT}/components/font-awesome/css/font-awesome.min.css"

structureRow = (dataList, rowOptions) ->
  i = 0

  <Row id='main-table-row' {...rowOptions} >
    <Col xs={3}>
      <Row>
        <Col xs={2}><div className='contents'>{dataList[i++]}</div></Col>
        <Col xs={10}><div className='contents'>{dataList[i++]}</div></Col>
      </Row>
    </Col>
    <Col xs={4}>
      <Row>
        <Col xs={9}><div className='contents'>{dataList[i++]}</div></Col>
        <Col xs={3}><div className='contents'>{dataList[i++]}</div></Col>
      </Row>
    </Col>
    <Col xs={4}>
      <Row>
        <Col xs={2}><div className='contents'>{dataList[i++]}</div></Col>
        <Col xs={2}><div className='contents'>{dataList[i++]}</div></Col>
        <Col xs={2}><div className='contents'>{dataList[i++]}</div></Col>
        <Col xs={2}><div className='contents'>{dataList[i++]}</div></Col>
        <Col xs={2}><div className='contents'>{dataList[i++]}</div></Col>
      </Row>
    </Col>
  </Row>

RenderRow = React.createClass
  getInitialState: ->
    show: true
  
  deckSortieConsumption: (deck) ->
    # return [fuel, ammo, steel, bauxite]
    # See format of TempRecord#generateResult
    sum4([ship.consumption[0]+ship.consumption[3],
          ship.consumption[1],
          ship.consumption[4],
          ship.consumption[2]] for ship in deck)

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

    structureRow [
        @props.id,
        timeText,
        mapText,
        mapHp,
        total[0],
        total[1],
        total[2],
        total[3],
        buckets
      ],
      id: 'main-table-row'

PluginMain = React.createClass
  getInitialState: ->
    data: []

  componentDidMount: ->
    @recordManager = new RecordManager()
    @recordManager.onRecordUpdate @handleUpdate
  componentWillUnmount: ->
    @recordManager.stopListening()

  handleUpdate: ->
    if !@recordManager?
      @setState
        data: []
    else
      data = @recordManager.getRecord(null, null)
      @setState {data}

  render: ->
    gridSeq = 0
    <Grid fluid=true className='main-table'>
      <Row>
        <Col xs={12}>
         {
          structureRow [
              '#',
              'Time',
              'Map',
              'Hp',
              'Fuel',
              'Ammo',
              'Steel',
              'Bauxite',
              'Buckets'
            ],
            id='main-table-header'
         }
         {
          for record, i in @state.data
            <RenderRow 
              record=record
              key={"row-#{record.time}"}
              id={i+1}
            /> 
         }
        </Col>
      </Row>
    </Grid>

ReactDOM.render <PluginMain />, $('main-table')
