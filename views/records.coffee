Promise = require 'bluebird'
fs = Promise.promisifyAll(require 'fs-extra')
path = require 'path-extra'
_ = require 'underscore'

class TempRecord
  # An instance is created at the startup of poi, or the start of a sortie
  # this.result() is called at api_port, and then the instance is destroyed

  tempFilePath_: path.join window.PLUGIN_ROOT, 'assets', 'temp_record.json'

  constructor: (postBody, mapInfoList) ->
    @record_ = null
    if !postBody?
      @readFromJson_()
    else
      @readFromPostBody_ postBody, mapInfoList

  valid: -> @record_?

  generateResult: ->
    # Will return a result only when "valid" and "consistant" and "non-empty"
    # Side effect: will always delete temp json file (even if returns null)
    # Format: {
    #   map: {
    #     name: "2-5"
    #     rank: undefined | 1 | 2 | 3           # 1 for easy, 3 for hard
    #     hp: undefined | [<now_remaining>, <max>]  # undefined after cleared
    #   }
    #   time: <Unix Time Milliseconds>
    #   deck: [
    #     {
    #       id: 8902
    #       consumption: [<resupplyFuel>, <resupplyAmmo>, <resupplyBauxite>,
    #         <repairFuel>, <repairSteel>]
    #     }, ...   
    #   ]
    # }
    fs.remove @tempFilePath_
    if !@checkConsistant_()
      return null
    @calculateResult_() if !@result_?
    if @resultIsEmpty()
      return null
    @result_

  checkConsistant_: ->
    if !@valid()
      return false
    window._decks[@record_.deckId-1].api_ship.every (now_ship_id, index) =>
      now_ship_id == (@record_.deck[index]?.id || -1)

  resultIsEmpty: ->
    # Check if the flagship consumed fuel.
    @result_.deck[0].consumption[0] == 0

  calculateResult_: ->
    deck = (for ship in @record_.deck
      {id: ship.id, consumption: @shipConsumption_ ship})
    @result_ = 
      deck: deck
      map: @record_.map
      time: @record_.time
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
    ship = window._ships[id]
    id: id
    fuel: ship.api_fuel
    bull: ship.api_bull
    repair: ship.api_ndock_item
    onSlot: ship.api_onslot.slice()

  readFromPostBody_: (postBody, mapInfoList) ->
    deckId = postBody.api_deck_id
    deck = (@recordShip_(id) for id in window._decks[deckId-1].api_ship when id != -1)
    time = new Date().getTime()
    map = {name: "#{postBody.api_maparea_id}-#{postBody.api_mapinfo_no}"}

    # Get mapRank (if exists)
    mapId = "#{postBody.api_maparea_id}#{postBody.api_mapinfo_no}"
    if window._eventMapRanks?[mapId]?
      map.rank = window._eventMapRanks[mapId]

    # Get mapHp (if exists)
    mapInfo = mapInfoList.find((m) -> (""+m.api_id) == mapId)
    if mapInfo?
      console.log "Got!"+mapInfo
      # An event map
      if mapInfo.api_eventmap?
        if !mapInfo.api_cleared
          now = mapInfo.api_eventmap.api_now_maphp
          max = mapInfo.api_eventmap.api_max_maphp
      # A normal map
      else if window.$maps[mapId].api_required_defeat_count?
        max = window.$maps[mapId].api_required_defeat_count
        now = max - mapInfo.api_defeat_count
      if now? && now != 0
        map.hp = [now, max]
        console.log map.hp

    @record_ = {deckId, deck, map, time}
    @storeToJson_()

  readFromJson_: ->
    # This function is only used at the startup of poi
    # And the contents read are only used at api_port
    # So we don't check the completion and assume it has finished by api_port
    fs.readJsonAsync @tempFilePath_, {throws: false}
    .then (@record_) =>

  storeToJson_: ->
    # This function is only used at the start of every sortie
    # And the contents written are only used at the next startup of poi
    # So we don't check the completion and assume it has finished by poi ends
    fs.writeFile @tempFilePath_, JSON.stringify @record_


class RecordManager
  # An instance of this class is created at the startup of poi
  # And is used throughout the whole lifetime of the plugin

  sortieRecordsPath_: path.join window.PLUGIN_ROOT, 'assets', 'sortie_records.json'
  bucketRecordPath_: path.join window.PLUGIN_ROOT, 'assets', 'bucket_record.json'

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

  forEachRecordWithinRange: (start, end, fn) ->
    # Both start and end inclusive.

    len = if @records_? then @records_.length else 0
    # 0 <= start <= end <= len-1
    if start == null
      start = 0
    start = Math.min(Math.max(0, start), len-1)
    if end == null
      end = len-1
    end = Math.min(Math.max(start, end), len-1)

    (fn @records_[len-1-i] for i in [start..end])

  handleResponse_: (e) ->
    {method, path, body, postBody} = e.detail
    switch path
      when '/kcsapi/api_req_map/start'
        @tempRecord_ = new TempRecord(postBody, @mapInfoList)
      when '/kcsapi/api_port/port'
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
        console.log @mapInfoList

  handleRequest_: (e) ->
    {method, path, body} = e.detail
    switch path
      when '/kcsapi/api_req_nyukyo/speedchange'
        @processUseBucket_ window._ndocks[body.api_ndock_id-1]

  processUseBucket_: (ship_id) ->
    if !(recordId = @bucketRecord_[ship_id])?
      return
    if !(record = @records_[recordId])?
      return
    record.buckets = (record.buckets || 0) + 1
    #elete @bucketRecord_[ship_id]
    @writeToJson_()
    @onRecordUpdate_() if @onRecordUpdate_

  processNewRecord_: (record) ->
    @records_.push record
    # Update bucket rrd here instead of at api_req_map/start
    # Because a record may be empty which can only be determined at api_port
    recordId = @records_.length - 1
    for ship in record.deck
      @bucketRecord_[ship.id] = recordId
    @writeToJson_()
    @onRecordUpdate_() if @onRecordUpdate_

  writeToJson_: ->
    fs.writeFile @bucketRecordPath_, JSON.stringify @bucketRecord_
    fs.writeFile @sortieRecordsPath_, JSON.stringify @records_

  readFromJson_: ->
    # This function is only used at the startup of poi
    # And the contents read are not used until api_port
    # So we don't check the completion and assume it has finished by api_port
    fs.readJsonAsync @sortieRecordsPath_, {throws: false}
    .then (records) =>
      if records
        @records_ = records
        @onRecordUpdate_() if @onRecordUpdate_
    .catch (->)

    fs.readJsonAsync @bucketRecordPath_, {throws: false}
    .then (bucketRecord) =>
      if bucketRecord
        @bucketRecord_ = bucketRecord
    .catch (->)



module.exports = {TempRecord, RecordManager}
