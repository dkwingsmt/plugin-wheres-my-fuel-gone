{React, ReactDOM} = window
{Input, Button, Table, Well, Panel, ListGroup, ListGroupItem, Alert} = ReactBootstrap

HasMapHpFilter = React.createClass
  statics:
    label: 'Map clearance'
    id: 'maphp'
    func: (value, record) -> (record.map?.hp?[0] > 0) == value
    textFunc: (value) ->
      "On a map that has #{if value then 'not ' else ''}been cleared"

  onChange: -> 
    value = @refs.input.getValue()
    result = if value == 'none'
      undefined
    else
      value == 'true'
    @props.onChange? result

  render: ->
    options = @props.options || {}
    <Input type="select" placeholder="select" ref='input' onChange={@onChange} 
      {...options} >
      <option value="none">Select...</option>
      <option value="true">A map that has not been cleared</option>
      <option value="false">A map that has been cleared</option>
    </Input>

HasShipIdFilter = React.createClass
  statics:
    label: 'Ship'
    id: 'hasship'
    func: (value, record) ->
      a = record.fleet.concat(record.fleet2 || []).filter(
        (sh) -> sh.shipId.toString() == value.toString())
      a.length != 0
    textFunc: (value) ->
      "With ship #{value}"

  onChange: -> 
    value = @refs.input.getValue()
    result = if value?.length == 0
      undefined
    else
      value
    @props.onChange? result

  render: ->
    options = @props.options || {}
    <Input type="text" ref='input' placeholder='Enter your ship id here'
      onChange={@onChange} {...options} />

FilterSelector = React.createClass
  getInitialState: ->
    activeCategory: null
    filterDetail: null
    nowFilterList: []
    categories: {}

  statics:
    categories: [
      HasMapHpFilter,
      HasShipIdFilter
    ]

  componentDidMount: ->
    categories = {}
    for filterClass in @constructor.categories
      categories[filterClass.id] = 
        label: filterClass.label
        filterClass: filterClass
    @setState {categories}

  generateFilterFunc_: (filterList) ->
    if filterList.length == 0
      return -> true
    filterList = JSON.parse(JSON.stringify(filterList))
    funcs = filterList.map ({id, value}) =>
      @state.categories[id]?.filterClass.func.bind(this, value)
    (record) ->
      funcs.every (f) -> f(record)

  handleCategory: (e) ->
    @setState
      activeCategory: e.target.value
      filterDetail: null

  handleFilterDetailChange: (value) ->
    @setState
      filterDetail: value

  handleAddFilter: ->
    nowFilterList = @state.nowFilterList
    nowFilterList.push
      id: @state.activeCategory
      value: @state.filterDetail
    @setState
      activeCategory: 'none'
      nowFilterList: nowFilterList
    @filterChangeTo(nowFilterList)

  handleRemoveFilter: (i) ->
    nowFilterList = @state.nowFilterList.slice()
    nowFilterList.splice(i, 1)
    @setState
      nowFilterList: nowFilterList
    @filterChangeTo(nowFilterList)

  filterChangeTo: (nowFilterList) ->
    if @props.onFilterChanged?
      @props.onFilterChanged @generateFilterFunc_(nowFilterList)

  render: ->
    nowCategoryId = @state.activeCategory
    nowCategoryInfo = @state.categories[nowCategoryId]
    <div>
      <Panel collapsible defaultExpanded header="Filter">
        <form className="form-horizontal">
          <ListGroup fill>
            <ListGroupItem>
              <Input type="select" value={@state.activeCategory} bsSize='medium'
                labelClassName="col-xs-1"  wrapperClassName="col-xs-11"
                label="Category" onChange=@handleCategory>
                <option value='none' key="option-none">{'Select a condition...'}</option>
                {
                  for categoryId_, categoryInfo_ of @state.categories
                    <option value={categoryId_} key="option-#{categoryId_}">{categoryInfo_.label}</option>
                }
              </Input>
            </ListGroupItem>
            {
              if nowCategoryInfo?
                valid = @state.filterDetail?
                options = 
                  label: 'Detail'
                  labelClassName: "col-xs-1"
                  wrapperClassName: "col-xs-11"
                  bsSize: 'medium'
                [
                  <ListGroupItem>
                    <nowCategoryInfo.filterClass key="filter-#{nowCategoryId}"
                      onChange={@handleFilterDetailChange} options={options} />
                  </ListGroupItem>
                  <Button key='apply-button' disabled={!valid} onClick={@handleAddFilter}>Apply</Button>
                ]
            }
          </ListGroup>
        </form>
      </Panel>
      {
        if @state.nowFilterList?.length
          <Alert bsStyle="info" style={marginLeft: 20, marginRight: 20}>
            Filters applying
            <ul>
             {
              for filter, i in @state.nowFilterList
                <li key="applied-filter-#{i}">
                  {@state.categories[filter.id].filterClass.textFunc filter.value}
                  <i className="fa fa-times remove-filter-icon"
                    onClick={@handleRemoveFilter.bind(this, i)}></i>
                </li>
             }
            </ul>
          </Alert>
      }
    </div>

module.exports = {FilterSelector}
