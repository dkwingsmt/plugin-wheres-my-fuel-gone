{React, ReactDOM, config} = window
{Grid, Row, Col, Input, Button, Table} = ReactBootstrap
path = require 'path-extra'
{TempRecord, RecordManager} = require path.join(__dirname, 'records')

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
    if @recordManager?
      tableContents = @recordManager.forEachRecordWithinRange null, null, (record) ->
        mapText = record.map.name
        if record.map.rank?
          mapText += ['', 'Easy', 'Medium', 'Hard' ][record.map.rank]
        if record.map.hp?
          [now, max] = record.map.hp
          mapText += " [#{now}/#{max}]"
        [
          # Time
          new Date(record.time).toLocaleString(),
          # Map
          mapText,
          # Fuel/Ammo/Steel/Bauxite: see format of TempRecord#generateResult
          sum(ship.consumption[0]+ship.consumption[3] for ship in record.deck),
          sum(ship.consumption[1] for ship in record.deck),
          sum(ship.consumption[4] for ship in record.deck),
          sum(ship.consumption[2] for ship in record.deck),
          record.buckets || 0]
      @setState {tableContents}
    else
      @setState
        tableContents: []

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
