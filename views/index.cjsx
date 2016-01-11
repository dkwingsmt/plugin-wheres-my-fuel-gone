{React, ReactDOM, config} = window
{Grid, Row, Col, Input, Button, Table} = ReactBootstrap
path = require 'path-extra'
{TempRecord, RecordManager} = require path.join(__dirname, 'records')
_ = require 'underscore'

$('#font-awesome')?.setAttribute 'href', "#{ROOT}/components/font-awesome/css/font-awesome.min.css"

sum4 = (lists) ->
  # Sum array of [fuel,ammo,steel,bauxite] into one [f,a,s,b]
  _.unzip(lists).map sum

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
      tableContents = @recordManager.forEachRecordWithinRange null, null, @processRecord
      @setState {tableContents}

  processRecord: (record) ->
    # Date
    timeText = new Date(record.time).toLocaleString()

    # Map text
    mapText = record.map.name
    if record.map.rank?
      mapText += ['', 'Easy', 'Medium', 'Hard' ][record.map.rank]
    if record.map.hp?
      [now, max] = record.map.hp
      mapText += " [#{now}/#{max}]"

    # Deck
    total = @deckSortieConsumption record.deck
    if record.deck2?
      total = sum4 total, @deckSortieConsumption record.deck2

    buckets = record.buckets || 0

    [timeText, mapText].concat(total).concat([buckets])

  deckSortieConsumption: (deck) ->
    # return [fuel, ammo, steel, bauxite]
    # See format of TempRecord#generateResult
    sum4([ship.consumption[0]+ship.consumption[3],
          ship.consumption[1],
          ship.consumption[4],
          ship.consumption[2]] for ship in deck)

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
             {
              for row, i in @state.tableContents
                <tr key={"row-#{i}"}>
                  <td key={"row-#{i}-col-0"}>{i+1}</td>
                  {
                    for data, j in row
                      <td key={"row-#{i}-col-#{j}"}>
                        {data}
                      </td>
                  }
                </tr>
             }
            </tbody>
          </Table>
        </Col>
      </Row>
    </Grid>

ReactDOM.render <PluginMain />, $('main')
