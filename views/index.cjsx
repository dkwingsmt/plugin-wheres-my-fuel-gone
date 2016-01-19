{React, ReactDOM} = window
path = require 'path-extra'
Promise = require 'bluebird'
fs = Promise.promisifyAll(require 'fs-extra')
{Tabs, Tab} = ReactBootstrap

{TabMain} = require path.join(__dirname, 'tab_main')
{TabBookmarks} = require path.join(__dirname, 'tab_bookmarks')
{RecordManager} = require path.join(__dirname, 'records')

PluginMain = React.createClass
  getInitialState: ->
    fullRecords: []
    filterList: {}

  filterListPath: path.join window.PLUGIN_ROOT, 'assets', 'filters.json'

  componentDidMount: ->
    @readFiltersFromJson()
    window.addEventListener 'game.response', @handleResponse
    if process.env.DEBUG
      @recordManager = new RecordManager()
      @recordManager.onRecordUpdate @handleRecordsUpdate
    
  componentWillUnmount: ->
    @recordManager?.stopListening()
    window.removeEventListener 'game.response', @handleResponse

  handleResponse: (e) ->
    {method, path, body, postBody} = e.detail
    switch path
      # Load data only after api_start2, because we need $ships
      when '/kcsapi/api_start2'
        if !process.env.DEBUG
          @recordManager = new RecordManager()
          @recordManager.onRecordUpdate @handleRecordsUpdate

  handleRecordsUpdate: ->
    @setState
      fullRecords: (@recordManager?.records() || [])

  onChangeFilterName: (time, name) ->
    {filterList} = @state
    if !filterList[time]
      return false
    filterList[time].name = name
    @setState {filterList}
    @saveFiltersToJson()

  onRemoveFilter: (time) ->
    {filterList} = @state
    delete filterList[time]
    @setState {filterList}
    @saveFiltersToJson()

  onAddFilter: (filter) ->
    {filterList} = @state
    filter = 
      rules: cloneByJson filter
      name: "New filter"
      time: Date.now()
    filterList[filter.time] = filter
    @setState {filterList}
    @saveFiltersToJson()

  readFiltersFromJson: ->
    fs.readJsonAsync @filterListPath, {throws: false}
    .then (filterList) =>
      if filterList
        @setState {filterList}
    .catch (->)

  saveFiltersToJson: ->
    fs.writeFile @filterListPath, JSON.stringify @state.filterList

  render: ->
    <Tabs defaultActiveKey={1} animation={false}>
      <Tab eventKey={1} title="Table">
        <TabMain 
          onAddFilter={@onAddFilter}
          fullRecords={@state.fullRecords} />
      </Tab>
      <Tab eventKey={2} title="Bookmarks">
        <TabBookmarks 
          filterList={@state.filterList}
          onChangeFilterName={@onChangeFilterName}
          onRemoveFilter={@onRemoveFilter}
          fullRecords={@state.fullRecords} />
      </Tab>
    </Tabs>

ReactDOM.render <PluginMain />, $('main')
