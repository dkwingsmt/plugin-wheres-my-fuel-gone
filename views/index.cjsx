{React, ReactDOM} = window
path = require 'path-extra'
{Tabs, Tab} = ReactBootstrap

{TabMain} = require path.join(__dirname, 'tab_main')
{RecordManager} = require path.join(__dirname, 'records')

PluginMain = React.createClass
  getInitialState: ->
    fullRecords: []

  componentDidMount: ->
    window.addEventListener 'game.response', @handleResponse
    if process.env.DEBUG
      console.log "here"
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

  render: ->
    <Tabs defaultActiveKey={1} animation={false}>
      <Tab eventKey={1} title="Table">
        <TabMain 
          fullRecords={@state.fullRecords} />
      </Tab>
      <Tab eventKey={2} title="Bookmarks">
        Tab 2 content
      </Tab>
    </Tabs>

ReactDOM.render <PluginMain />, $('main')
