{React, ReactDOM, config} = window
{Grid, Row, Col, Input, Button} = ReactBootstrap
Promise = require 'bluebird'
fs = Promise.promisifyAll(require 'fs-extra')
path = require 'path-extra'
_ = require 'underscore'

$('#font-awesome')?.setAttribute 'href', "#{ROOT}/components/font-awesome/css/font-awesome.min.css"

sum = (l) ->
  s = 0
  for i in l
    s += i
  s

class SortieTempRecord
  # An instance is created at the startup of poi, or the start of a sortie
  # this.result() is called at api_port, and then the instance is destroyed

  tempFilePath_: path.join window.PLUGIN_ROOT, 'assets', 'temp_record.json'

  constructor: (postBody) ->
    @record_ = null
    if !postBody?
      @readFromJson_()
    else
      @readFromPostBody_ postBody

  valid: -> @record_?

  generateResult: ->
    # Will return a result only when "valid" and "consistant"
    # Side effect: will always delete temp json file (even if returns null)
    fs.remove @tempFilePath_
    if !@checkConsistant_()
      return null
    @calculateResult_() if !@result_?
    @result_

  checkConsistant_: ->
    console.log @record_
    if !@valid()
      return false
    window._decks[@record_.deckId-1].api_ship.every (now_ship_id, index) =>
      console.log now_ship_id, @record_.deck, @record_.deck[index]
      console.log "this ship consistant", now_ship_id == (@record_.deck[index]?.id || -1)
      now_ship_id == (@record_.deck[index]?.id || -1)

  calculateResult_: ->
    console.log @record_
    deck = (for ship in @record_.deck
      {id: ship.id, consumption: @shipConsumption_ ship})
    console.log deck
    @result_ = 
      deck: deck
      map: @record_.map
      time: @record_.time
    if @record_.mapRank?
      Object.assign @result_, {mapRank: @record_.mapRank}
    console.log @result_
    @result_

  shipConsumption_: (recordShip) ->
    nowShip = window._ships[recordShip.id]
    resupplyFuel =  recordShip.fuel - nowShip.api_fuel
    resupplyAmmo = recordShip.bull - nowShip.api_bull
    # Every slot costs 5 bauxites
    resupplyBauxite = 5 * sum(slot1-slot2 for [slot1, slot2] in _.zip(
      recordShip.onSlot, nowShip.api_onslot))
    repairFuel = nowShip.api_ndock_item[0] - recordShip.repair[0]
    repairSteel = nowShip.api_ndock_item[1] - recordShip.repair[1]
    [resupplyFuel, resupplyAmmo, resupplyBauxite, repairFuel, repairSteel]

  recordShip_: (id) ->
    ship = _ships[id]
    id: id
    fuel: ship.api_fuel
    bull: ship.api_bull
    repair: ship.api_ndock_item
    onSlot: ship.api_onslot.slice()

  readFromPostBody_: (postBody) ->
    deckId = postBody.api_deck_id
    map = "#{postBody.api_maparea_id}-#{postBody.api_mapinfo_no}"
    mapId = "#{postBody.api_maparea_id}#{postBody.api_mapinfo_no}"
    if window._eventMapRanks?[mapId]?
      mapRank = window._eventMapRanks[mapId]
    deck = (@recordShip_(id) for id in window._decks[deckId-1].api_ship when id != -1)
    time = new Date().getTime()
    @record_ = {deckId, deck, map, mapRank, time}
    console.log @record_
    @storeToJson_()

  readFromJson_: ->
    # This function is only used at the startup of poi
    # And the contents read are only used at api_port
    # So we don't check the completion and assume it has finished by api_port
    fs.readJsonAsync @tempFilePath_, {throws: false}
    .then (@record_) =>
      console.log @record_

  storeToJson_: ->
    # This function is only used at the start of every sortie
    # And the contents written are only used at the next startup of poi
    # So we don't check the completion and assume it has finished by poi ends
    fs.writeFile @tempFilePath_, JSON.stringify @record_


class RecordManager
  # An instance of this class is created at the startup of poi
  # And is used throughout the whole lifetime of the plugin

  recordFilePath_: path.join window.PLUGIN_ROOT, 'assets', 'records.json'

  constructor: ->
    # Read from the temp json
    @tempRecord_ = new SortieTempRecord()
    @onNewRecord_ = null
    @readFromJson_()
    window.addEventListener 'game.response', @handleResponse_.bind(this)
    console.log "CONSTRUCTOR!", @tempRecord_

  onNewRecord: (cb) ->
    @onNewRecord_ = cb

  stopListening: ->
    window.removeEventListener 'game.response', @handleResponse_.bind(this)

  handleResponse_: (e) ->
    {method, path, body, postBody} = e.detail
    switch path
      when '/kcsapi/api_req_map/start'
        @tempRecord_ = new SortieTempRecord(postBody)
        console.log "New!", @tempRecord_
      when '/kcsapi/api_port/port'
        console.log "PORT!", @tempRecord_
        if @tempRecord_? && (newRecord = @tempRecord_.generateResult())?
          @records_.push newRecord
          console.log @records_
          @writeToJson_()

  writeToJson_: ->
    fs.writeFile @recordFilePath_, JSON.stringify @records_

  readFromJson_: ->
    # This function is only used at the startup of poi
    # And the contents read are not used until api_port
    # So we don't check the completion and assume it has finished by api_port
    console.log "OnRead", @tempRecord_
    fs.readJsonAsync @recordFilePath_, {throws: false}
    .then (@records_) =>
      if !@records_?
        console.log "Invalid records file."
        @records_ = []
    .catch =>
      @records_ = []


PluginMain = React.createClass
  getInitialState: ->
    text: "TextHere"

  componentDidMount: ->
    @recordManager = new RecordManager()
  componentWillUnmount: ->
    @recordManager.stopListening()

  render: ->
    <Grid>
      <Row>
        <Col xs={12}>
          <span>{@state.text}</span>
        </Col>
      </Row>
    </Grid>

ReactDOM.render <PluginMain />, $('main')
