{React, ReactDOM} = window
{Input, Button, Table, Well, Panel, ListGroup, ListGroupItem, Alert} = ReactBootstrap


FilterSelector = React.createClass
  getInitialState: ->
    filterValue: null
    nowFilterList: []
    nowMenuPath: ['_root']
    nowLastMenu: @constructor.menuTree['_root']
    applyEnabled: false

  statics:
    menuTree:
      '_root':
        # Default
        func: -> true
        applyEnabledFunc: (path, value) ->
          value? && value.length != 0
        sub:
          '_map': 
            title: 'Map'
            sub:
              '_hp':
                title: 'Map clearance'
                func: (path, value, record) ->
                  (record.map?.hp?[0] > 0) == value
                textFunc: (value) ->
                  "On a map that has #{if value then 'not ' else ''}been cleared"
                sub: 
                  '_1': 
                    title: 'The map has been cleared'
                    value: false
                  '_2':
                    title: 'The map has not been cleared'
                    value: true
              '_id':
                func: (path, value, record) ->
                  record.map?.id == value
                title: 'Map number'
                textFunc: (value) ->
                  "On map #{value}"
                options:
                  placeholder: 'Enter the map number here (e.g. 2-3, 32-5)' 
          '_ship':
            title: 'Ship'
            preprocess: (path, value) ->
              isWith: path[path.length-1] == '_with'
              shipId: value
            func: (path, value, record) ->
              (record.fleet.concat(record.fleet2 || []).filter(
                (sh) -> sh.shipId.toString() == value.shipId.toString())
              .length != 0) == value.isWith
            textFunc: (value) ->
              _out = if value.isWith then '' else 'out'
              "With#{_out} ship #{value.shipId}"
            sub:
              '_with':
                title: 'With ship'
                options:
                  placeholder: 'Enter the ship id here' 
              '_without':
                title: 'Without ship'
                options:
                  placeholder: 'Enter the ship id here' 

  generateFilterFunc_: (filterList) ->
    if filterList.length == 0
      return -> true
    filterList = JSON.parse(JSON.stringify(filterList))
    funcs = filterList.map ({path, value}) =>
      @accumulateMenu(path)?.func.bind(this, path, value)
    (record) ->
      funcs.every (f) -> f(record)

  accumulateMenu: (path) ->
    # Accumulate all properties during the menu path
    nowMenu = {sub: @constructor.menuTree}
    console.log path
    menuLevels = ((nowMenu=nowMenu?.sub?[id]) for id in path).filter((o)->o?)
    console.log menuLevels
    totalDetails = Object.assign.apply this, [{}].concat(menuLevels)
    if !menuLevels[menuLevels.length-1].sub?
      delete totalDetails.sub
    totalDetails

  handleInputSelectChange: (level, e) ->
    path = @state.nowMenuPath[0..level]
    path.push e.target.value
    totalDetails = @accumulateMenu path
    @setState
      nowMenuPath: path
      nowLastMenu: totalDetails
      applyEnabled: totalDetails.value?
      filterValue: totalDetails.value

  handleInputTextChange: (e) ->
    path = @state.nowMenuPath
    nowMenu = @state.nowLastMenu
    value = e.target.value
    @setState
      applyEnabled: !nowMenu.applyEnabledFunc? || nowMenu.applyEnabledFunc path, value
      filterValue: value

  handleAddFilter: ->
    lastMenu = @state.nowLastMenu
    func = lastMenu.func || (-> true)
    preprocess = lastMenu.preprocess || ((path, value) -> value)
    console.log 'pre', preprocess
    nowFilterList = @state.nowFilterList
    path = @state.nowMenuPath.slice()
    console.log 'prevalue', @state.filterValue
    nowFilterList.push
      path: path
      value: preprocess(path, @state.filterValue)
      menu: @accumulateMenu(path)
    console.log 'nfl', nowFilterList
    @setState
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
    <div>
      <Panel collapsible defaultExpanded header="Filter">
        <form className="form-horizontal">
          <ListGroup fill>
           {
            nowMenu = {sub: @constructor.menuTree}
            console.log nowMenu
            for id, level in @state.nowMenuPath
              nowMenu = nowMenu.sub[id]
              console.log id, level, nowMenu
              if nowMenu? && !nowMenu.value?
                options = Object.assign 
                  labelClassName: 'col-xs-1'
                  wrapperClassName: 'col-xs-11'
                  label: (['Category', 'Detail'][level] || ' ')
                  bsSize: 'medium'
                  nowMenu.options
                # A selection input
                if nowMenu.sub?
                  <Input type='select'
                    onChange={@handleInputSelectChange.bind(this, level)}
                    {...options} >
                    <option value='none'>Select...</option>
                    {
                      for subId, subItem of nowMenu.sub
                        <option value={subId} key={"option-#{level}-#{subId}"}>
                          {subItem.title}
                        </option>
                    }
                  </Input>

                # A text input
                else
                  <Input type="text" onChange={@handleInputTextChange}
                    {...options} />
           }
          </ListGroup>
          {
            lastMenu = @state.nowLastMenu
            console.log 'last', lastMenu
            if !lastMenu? || !lastMenu.sub?
              valid = @state.applyEnabled
              <Button disabled={!valid} onClick={@handleAddFilter}>Apply</Button>
          }
        </form>
      </Panel>
      {
        if @state.nowFilterList?.length
          <Alert bsStyle="info" style={marginLeft: 20, marginRight: 20}>
            Filters applying
            <ul>
             {
              for {value, menu}, i in @state.nowFilterList
                <li key="applied-filter-#{i}">
                  {menu.textFunc? value}
                  <i className="fa fa-times remove-filter-icon"
                    onClick={@handleRemoveFilter.bind(this, i)}></i>
                </li>
             }
            </ul>
          </Alert>
      }
    </div>

module.exports = {FilterSelector}
