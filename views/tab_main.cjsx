{React, ReactDOM} = window
{Input, Button, Pagination} = ReactBootstrap
path = require 'path-extra'

{RuleSelectorMenu, RuleDisplay, translateRuleList} = require path.join(__dirname, 'filter_selector')
{RecordManager} = require path.join(__dirname, 'records')
{MainTable} = require path.join(__dirname, 'main_table')

filterHasHp = (record) ->
  record.map.hp?[0] > 0

TabMain = React.createClass
  getInitialState: ->
    ruleList: []
    ruleTexts: []
    activePage: 1

  handleSelectPage: (event, selectedEvent) ->
    @setState
      activePage: selectedEvent.eventKey

  addRule: (path, value) ->
    ruleList = @state.ruleList
    ruleList.push {path, value}
    @setState
      ruleList: ruleList
    @filterChangeTo ruleList

  removeRule: (i) ->
    if !i?
      ruleList = []
    else
      ruleList = @state.ruleList
      ruleList.splice(i, 1)
    @setState
      ruleList: ruleList
    @filterChangeTo ruleList

  saveFilter: ->
    console.log @state.ruleList

  filterChangeTo: (nowRuleList) ->
    # testError has been done at RuleSelectorMenu
    {func, texts, errors} = translateRuleList nowRuleList
    @setState
      ruleTexts: texts
      filter: func
      activePage: 1

  sumUpConsumption: (recordList) ->
    sumArray (for record in recordList
      fleetConsumption = (for ship in record.fleet.concat(record.fleet2 || [])
        ship.consumption.concat(if ship.bucket then 1 else 0))
      supportConsumption = (for support in (record.supports || []) 
        resource4to5(support.consumption).concat(0))
      sumArray fleetConsumption.concat(supportConsumption))

  render: ->
    data = (@props.fullRecords.filter(@state.filter || (-> true))).reverse()
    dataLen = data.length
    startNo = Math.min (@state.activePage-1)*10, dataLen
    endNo = Math.min (startNo+9), dataLen
    maxPages = Math.max Math.ceil((data?.length || 0)/10), 1
    sumData = if @state.ruleList.length then @sumUpConsumption data else null

    <div id='main-wrapper'>
      <RuleSelectorMenu 
        onAddRule={@addRule} />
      <RuleDisplay
        ruleTexts={@state.ruleTexts}
        onSave={@saveFilter}
        onRemove={@removeRule} />
      <MainTable 
        data=data[startNo..endNo]
        startNo=startNo
        sumData=sumData />
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

module.exports = {TabMain}
