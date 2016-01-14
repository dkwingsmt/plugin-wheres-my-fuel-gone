{React, ReactDOM} = window
{Button, Pagination} = ReactBootstrap
path = require 'path-extra'

{RecordManager} = require path.join(__dirname, 'records')
{MainTable} = require path.join(__dirname, 'main_table')

PluginMain = React.createClass
  getInitialState: ->
    data: []
    activePage: 1

  componentDidMount: ->
    window.addEventListener 'game.response', @handleResponse
    
  componentWillUnmount: ->
    @recordManager?.stopListening()
    window.removeEventListener 'game.response', @handleResponse

  handleResponse: (e) ->
    {method, path, body, postBody} = e.detail
    switch path
      when '/kcsapi/api_start2'
        @recordManager = new RecordManager()
        @recordManager.onRecordUpdate @handleUpdate

  handleUpdate: ->
    if !@recordManager?
      @setState
        data: []
    else
      data = @recordManager.getRecord(null, null)
      @setState {data}

  handleSelectPage: (event, selectedEvent) ->
    this.setState
      activePage: selectedEvent.eventKey

  render: ->
    startNo = (@state.activePage-1) * 10
    endNo = startNo + 9
    <div>
      <MainTable 
        data=@state.data[startNo..endNo]
        startNo=startNo />
      <div style={textAlign: 'center'}>
        <Pagination
          first
          last
          ellipsis
          items={Math.ceil((@state.data?.length || 0)/10)}
          maxButtons={5}
          activePage={@state.activePage}
          onSelect={@handleSelectPage} />
      </div>
    </div>

ReactDOM.render <PluginMain />, $('main')
