{React, ReactDOM, config} = window
{Grid, Row, Col, Input, Button, Table, Well} = ReactBootstrap
path = require 'path-extra'
{TempRecord, RecordManager} = require path.join(__dirname, 'records')
_ = require 'underscore'

$('#font-awesome')?.setAttribute 'href', "#{ROOT}/components/font-awesome/css/font-awesome.min.css"

PluginMain = React.createClass
  getInitialState: ->
    tableContents: []

  componentDidMount: ->
    @recordManager = new RecordManager()
    @recordManager.onRecordUpdate @handleUpdate
  componentWillUnmount: ->
    @recordManager.stopListening()

  handleUpdate: ->
    if !@recordManager?
      @setState
        tableContents: []
    else
      tableContents = [].concat.apply @recordManager.getRecord(null, null).map @processRecord
      console.log tableContents
      @setState {tableContents}

  deckSortieConsumption: (deck) ->
    # return [fuel, ammo, steel, bauxite]
    # See format of TempRecord#generateResult
    sum4([ship.consumption[0]+ship.consumption[3],
          ship.consumption[1],
          ship.consumption[4],
          ship.consumption[2]] for ship in deck)

  processRecord: (record, i) ->
    # Date
    timeText = new Date(record.time).toLocaleString()

    # Map text
    mapText = "#{record.map.name}(#{record.map.id})"
    if record.map.rank?
      mapText += ['', 'Easy', 'Medium', 'Hard' ][record.map.rank]
    if record.map.hp?
      [now, max] = record.map.hp
      mapText += " [#{now}/#{max}]"

    # Deck
    total = @deckSortieConsumption record.deck
    if record.deck2?
      total = sum4 total, @deckSortieConsumption record.deck2
    if record.reinforcements?
      total = sum4 [total].concat(for reinforcement in record.reinforcements
        reinforcement.consumption)
      
    buckets = record.buckets || 0

    [
      <tr key={"row-#{record.time}"}>
        <td>{i+1}</td>
        <td>{timeText}</td>
        <td>{mapText}</td>
        <td>{total[0]}</td>
        <td>{total[1]}</td>
        <td>{total[2]}</td>
        <td>{total[3]}</td>
        <td>{buckets}</td>
      </tr>,
      <tr key={"row2-#{record.time}"}>
        <td colSpan="8">
            abc
        </td>
      </tr>
    ]

  render: ->
    <Grid>
      <Row>
        <Col xs={12}>
          <Table striped bordered condensed hover>
            <thead>
              <tr>
                <th>#</th>
                <th>Time</th>
                <th>Map</th>
                <th>Fuel</th>
                <th>Ammo</th>
                <th>Steel</th>
                <th>Bauxite</th>
                <th>Buckets</th>
              </tr>
            </thead>
            <tbody>
              {@state.tableContents}
            </tbody>
          </Table>
        </Col>
      </Row>
    </Grid>

ReactDOM.render <PluginMain />, $('main')
