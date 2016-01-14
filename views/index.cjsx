{React, ReactDOM} = window
{Input, Button, Pagination} = ReactBootstrap
path = require 'path-extra'

{RecordManager} = require path.join(__dirname, 'records')
{MainTable} = require path.join(__dirname, 'main_table')

filterHasHp = (record) ->
  record.map.hp?[0] > 0

PluginMain = React.createClass
  getInitialState: ->
    data: []
    fullRecords: []
    activePage: 1

  componentDidMount: ->
    window.addEventListener 'game.response', @handleResponse
    
  componentWillUnmount: ->
    @recordManager?.stopListening()
    window.removeEventListener 'game.response', @handleResponse

  handleResponse: (e) ->
    {method, path, body, postBody} = e.detail
    switch path
      # Load data only after api_start2, because we need $ships
      when '/kcsapi/api_start2'
        @recordManager = new RecordManager()
        @recordManager.onRecordUpdate @handleRecordsUpdate

  handleRecordsUpdate: ->
    @setState
      fullRecords: (@recordManager?.records() || [])
    @applyFilter()

  handleSelectPage: (event, selectedEvent) ->
    @setState
      activePage: selectedEvent.eventKey

  handleCheckbox: (event) ->
    @applyFilter(if event.target.checked then filterHasHp else null)

  applyFilter: (filter) ->
    # filter == null means no filtering
    # filter == undefined means filter unchanged
    # Otherwise, filter is a function(record) => bool
    if typeof filter != 'undefined' && filter != @filter
      # Filter is changed. 
      @filter = filter
      @setState
        activePage: 1
    data = (@state.fullRecords.filter(@filter || (-> true))).reverse()
    @setState {data}

  render: ->
    dataLen = @state.data.length
    startNo = Math.min (@state.activePage-1)*10, dataLen
    endNo = Math.min (startNo+9), dataLen
    maxPages = Math.max Math.ceil((@state.data?.length || 0)/10), 1

    <div>
      <Input type="checkbox" label="With HP" onClick={@handleCheckbox}/>
      <MainTable 
        data=@state.data[startNo..endNo]
        startNo=startNo />
      <div style={textAlign: 'center'}>
        <Pagination
          first
          last
          ellipsis
          items={maxPages}
          maxButtons={5}
          activePage={@state.activePage}
          onSelect={@handleSelectPage} />
      </div>
    </div>

ReactDOM.render <PluginMain />, $('main')
