Promise = require 'bluebird'
fs = Promise.promisifyAll(require 'fs-extra')
path = require 'path-extra'
_ = require 'lodash'
{sum} = _

class TempRecord
  # Stores the information at the start of a sortie. When given the information
  # at the end of the sortie, calculate the result.
  # An instance is created at the startup of poi, or the start of a sortie.
  # this.result() is called at api_port, and then the instance is destroyed

  tempFilePath_: ->
    path.join window.pluginRecordsPath(), 'temp_record.json'

  constructor: (postBody, mapInfoList, hasCombinedFleet) ->
    @record_ = null
    if !postBody?
      @readFromJson_()
    else
      @readFromPostBody_ postBody, mapInfoList, hasCombinedFleet

  valid: -> @record_?

  generateResult: ->
    # Will return a result only when "valid" and "consistant" and "non-empty"
    # Side effect: will always delete temp json file (even if returns null)
    # Format: {
    #   map: {
    #     name: e.g. "2-5"
    #     rank: undefined | 1 | 2 | 3           # 1 for easy, 3 for hard
    #     hp: undefined | [<now_remaining>, <max>]  # undefined after cleared
    #   }
    #   time: <Unix Time Milliseconds>
    #   fleet: [        # Include both fleets in a combined fleet
    #     {     # One ship
    #       id: <int>           # api_id as in $ships
    #       shipId: <int>       # api_ship_id as in $ships
    #       consumption: [<resupplyFuel>, <resupplyAmmo>, <resupplyBauxite>,
    #         <repairFuel>, <repairSteel>]
    #       bucket: <boolean>   # undefined at the beginning. Becomes true later.
    #     }, ...   
    #   ]
    #   fleet1Size: <int>
    #   supports: [
    #     {
    #       shipId: [<int>, ...]    # api_ship_id as in $ships
    #       consumption: [<fuel>, <ammo>, 0, <bauxite>]     # Total only
    #     }, ...
    #   ]
    # }

    return null if !@record_?
    fs.remove @tempFilePath_()

    # May inconsistant if you sortie, close poi without porting, log in from
    # another browser or device, do something else and then log back in poi
    # Do as much as we can to check if anything changed
    getShipId = (s) -> s.id
    fleet1Size = @record_.fleet1Size || @record_.fleet.length
    fleet1 = @record_.fleet[0...fleet1Size]
    fleet2 = @record_.fleet[fleet1Size...]
    return null if !@checkConsistant_(fleet1.map(getShipId), @record_.fleetId)
    return null if @record_.fleet1Size && !@checkConsistant_(fleet2.map(getShipId), '2')
    if @record_.supports?
      for support in @record_.supports
        return null if !@checkConsistant_(support.fleet, support.fleetId)
    if !@result_?
      @calculateResult_() 
    return null if @resultIsEmpty()
    @result_

  checkConsistant_: (fleet, fleetId, checkShipId=false) ->
    if !@valid()
      return false
    window._decks[fleetId-1].api_ship.every (nowId, index) =>
      if nowId == -1 && index >= fleet.length
        true
      else
        fleet[index] == (if checkShipId then window._ships[nowId].api_ship_id else nowId)

  resultIsEmpty: ->
    # If the flagship consumed no fuel, then the sortie ended before any combats. 
    # Non-empty if supports are used.
    @result_.fleet[0].consumption[0] == 0 && !@result_.supports?

  calculateResult_: ->
    @result_ = 
      fleet: @fleetConsumption_(@record_.fleet)
      map: @record_.map
      time: @record_.time
      fleet1Size: @record_.fleet1Size
    if @record_.supports?
      @result_.supports = for support in @record_.supports
        shipId: support.fleet.map((i) -> window._ships[i].api_ship_id)
        consumption: (sumArray(@shipExpeditionConsumption_ id for id in support.fleet))
    @result_

  fleetConsumption_: (fleet) ->
    (for ship in fleet
       id: ship.id
       shipId: window._ships[ship.id].api_ship_id
       consumption: @shipConsumption_ ship)

  marriageFactorFactory_: (lv) ->
    if lv >= 100
      (r) -> Math.floor(r * 0.85)
    else 
      (r) -> r

  shipConsumption_: (recordShip) ->
    nowShip = window._ships[recordShip.id]
    # Married ships has 15% off their resupply consumption
    marriageFactor = @marriageFactorFactory_ nowShip.api_lv
    resupplyFuel = marriageFactor(recordShip.fuel - nowShip.api_fuel)
    resupplyAmmo = marriageFactor(recordShip.bull - nowShip.api_bull)
    # Every slot costs 5 bauxites
    resupplyBauxite = 5 * sum(slot1-slot2 for [slot1, slot2] in _.zip(
      recordShip.onSlot, nowShip.api_onslot))
    repairFuel = nowShip.api_ndock_item[0] - recordShip.repair[0]
    repairSteel = nowShip.api_ndock_item[1] - recordShip.repair[1]
    [resupplyFuel, resupplyAmmo, resupplyBauxite, repairFuel, repairSteel]

  shipExpeditionConsumption_: (shipId) ->
    nowShip = window._ships[shipId]
    marriageFactor = @marriageFactorFactory_ nowShip.api_lv
    resupplyFuel =  marriageFactor(nowShip.api_fuel_max - nowShip.api_fuel)
    resupplyAmmo =  marriageFactor(nowShip.api_bull_max - nowShip.api_bull)
    # Every slot costs 5 bauxites
    resupplyBauxite = 5 * sum(slot1-slot2 for [slot1, slot2] in _.zip(
      nowShip.api_maxeq, nowShip.api_onslot))
    [resupplyFuel, resupplyAmmo, 0, resupplyBauxite]

  recordFleet_: (fleetId) ->
    (for id in window._decks[fleetId-1].api_ship when id != -1
      ship = window._ships[id]
      id: id
      fuel: ship.api_fuel
      bull: ship.api_bull
      repair: ship.api_ndock_item
      onSlot: ship.api_onslot.slice()
    )

  readFromPostBody_: (postBody, mapInfoList, hasCombinedFleet) ->
    fleetId = postBody.api_deck_id
    fleet = @recordFleet_ fleetId
    # It is possible to hasCombinedFleet but sortie with fleet 3/4
    if hasCombinedFleet && fleetId == "1"
      fleet1Size = fleet.length
      fleet = fleet.concat(@recordFleet_ "2")
    time = new Date().getTime()
    map = {id: "#{postBody.api_maparea_id}-#{postBody.api_mapinfo_no}"}

    # Get mapRank (if exists)
    mapId = "#{postBody.api_maparea_id}#{postBody.api_mapinfo_no}"
    if window._eventMapRanks?[mapId]?
      map.rank = window._eventMapRanks[mapId]

    # Get mapHp (if exists)
    mapInfo = mapInfoList.find((m) -> (m.api_id.toString()) == mapId)
    if mapInfo?
      map.name = window.$maps[mapId].api_name
      # An event map
      if mapInfo.api_eventmap?
        if !mapInfo.api_cleared
          now = mapInfo.api_eventmap.api_now_maphp
          max = mapInfo.api_eventmap.api_max_maphp
      # A normal map
      else if mapInfo.api_defeat_count?
        max = window.$maps[mapId].api_required_defeat_count
        now = max - mapInfo.api_defeat_count
      if now? && now != 0
        map.hp = [now, max]

    # Get support expeditions
    supports = []
    for thisFleet in window._decks
      if thisFleet.api_mission[0] == 1
        mission = window.$missions[thisFleet.api_mission[1]]
        # "mission.api_return_flag == 0" means a support expedition (?)
        if mission? && mission.api_return_flag == 0 &&
            mission.api_maparea_id.toString() == postBody.api_maparea_id
          supports.push
            fleetId: thisFleet.api_id
            fleet: thisFleet.api_ship.filter((i) -> i != -1)

    @record_ = {fleetId, fleet, map, time}
    @record_.fleet1Size = fleet1Size if fleet1Size?
    @record_.supports = supports if supports.length

    @storeToJson_()

  readFromJson_: ->
    # This function is only used at the startup of poi
    # And the contents read are only used at api_port
    # So we don't check the completion and assume it has finished by api_port
    fs.readJsonAsync @tempFilePath_(), {throws: false}
    .then (@record_) =>;
    .catch (e) ->
      if (e.code != 'ENOENT')
        throw e

  storeToJson_: ->
    # This function is only used at the start of every sortie
    # And the contents written are only used at the next startup of poi
    # So we don't check the completion and assume it has finished by poi ends
    fs.writeFile @tempFilePath_(), JSON.stringify @record_


class RecordManager
  # Stores and manages all raw data of records
  # An instance of this class is created at the startup of poi,
  # and is used throughout the whole lifetime of the plugin

  sortieRecordsPath_: ->
    path.join window.pluginRecordsPath(), 'sortie_records.json'

  bucketRecordPath_: ->
    path.join window.pluginRecordsPath(), 'bucket_record.json'

  constructor: ->
    @records_ = []
    @bucketRecord_ = {}
    # Read from the temp json
    @tempRecord_ = new TempRecord()
    @onRecordUpdate_ = null
    @readFromJson_()
    window.addEventListener 'game.request', @handleRequest_.bind(this)
    window.addEventListener 'game.response', @handleResponse_.bind(this)

  onRecordUpdate: (cb) ->
    @onRecordUpdate_ = cb

  stopListening: ->
    window.removeEventListener 'game.request', @handleRequest_.bind(this)
    window.removeEventListener 'game.response', @handleResponse_.bind(this)

  records: ->
    @records_

  handleResponse_: (e) ->
    {method, path: path_, body, postBody} = e.detail
    switch path_
      when '/kcsapi/api_req_map/start'
        @tempRecord_ = new TempRecord(postBody, @mapInfoList, @combinedFlag_? && @combinedFlag_ > 0)
      when '/kcsapi/api_port/port'
        @combinedFlag_ = body.api_combined_flag
        if @tempRecord_? && (newRecord = @tempRecord_.generateResult())?
          @processNewRecord_ newRecord
        @tempRecord_ = null
        # Filter out ships that no longer exist
        oldBucketRecord = @bucketRecord_
        @bucketRecord_ = {}
        for k, v of oldBucketRecord
          if window._ships[k]
            @bucketRecord_[k] = v
      when '/kcsapi/api_req_nyukyo/start'
        if postBody.api_highspeed == '1'
          @processUseBucket_ postBody.api_ship_id
      when '/kcsapi/api_get_member/mapinfo'
        @mapInfoList = body

  handleRequest_: (e) ->
    {method, path: path_, body} = e.detail
    switch path_
      when '/kcsapi/api_req_nyukyo/speedchange'
        @processUseBucket_ window._ndocks[body.api_ndock_id-1]

  processUseBucket_: (id) ->
    # id: api_id of your _ships.
    if !(recordId = @bucketRecord_[id])? || !(record = @records_[recordId])?
      return
    shipRecord = record.fleet.find (ship) -> 
      ship.id.toString() == id.toString()
    shipRecord?.bucket = true
    delete @bucketRecord_[id]
    @writeToJson_()
    @onRecordUpdate_() if @onRecordUpdate_

  processNewRecord_: (record) ->
    @records_.push record
    # Update bucket rrd here instead of at api_req_map/start
    # Because a record may be empty which can only be determined at api_port
    recordId = @records_.length - 1
    for ship in record.fleet
      @bucketRecord_[ship.id] = recordId
    @writeToJson_()
    @onRecordUpdate_() if @onRecordUpdate_

  writeToJson_: ->
    fs.writeFile @bucketRecordPath_(), JSON.stringify @bucketRecord_
    fs.writeFile @sortieRecordsPath_(), JSON.stringify @records_

  readFromJson_: ->
    # This function is only used at the startup of poi
    # And the contents read are not used until api_port
    # So we don't check the completion and assume it has finished by api_port
    fs.readJsonAsync @sortieRecordsPath_(), {throws: false}
    .then (records) =>
      if records
        # Remove duplicate records that may appear somehow 
        lastRecordTime = undefined
        @records_ = for record in records when record.time != lastRecordTime
          lastRecordTime = record.time
          # Fix NaN caused by a bug from poi
          for ship in record.fleet
            for n, i in ship.consumption
              if typeof n != 'number' || !n
                ship.consumption[i] = 0
          record
        @onRecordUpdate_() if @onRecordUpdate_
    .catch (->)

    fs.readJsonAsync @bucketRecordPath_(), {throws: false}
    .then (bucketRecord) =>
      if bucketRecord
        @bucketRecord_ = bucketRecord
    .catch (->)



module.exports = {TempRecord, RecordManager}
