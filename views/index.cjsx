{React, ReactDOM, config} = window
{Grid, Row, Col, Input, Button} = ReactBootstrap

$('#font-awesome')?.setAttribute 'href', "#{ROOT}/components/font-awesome/css/font-awesome.min.css"

PluginMain = React.createClass
  getInitialState: ->
    text: "TextHere"
    sortieDeckId: null

  handleResponse: (e) ->
    {method, path, body, postBody} = e.detail
    switch path
      when '/kcsapi/api_req_map/start'
        @setState
          sortieDeckId: parseInt(postBody.api_deck_id)
          text: "Sortie with fleet #{postBody.api_deck_id}"
      when '/kcsapi/api_port/port'
        if !@state.sortieDeckId?
          return
        @setState
          sortieDeckId: null
          text: "Returned with fleet #{@state.sortieDeckId}"
        
  componentDidMount: ->
    window.addEventListener 'game.response', @handleResponse
  componentWillUnmount: ->
    window.removeEventListener 'game.response', @handleResponse
  render: ->
    <Grid>
      <Row>
        <Col xs={12}>
          <span>{@state.text}</span>
        </Col>
      </Row>
    </Grid>

ReactDOM.render <PluginMain />, $('main')
