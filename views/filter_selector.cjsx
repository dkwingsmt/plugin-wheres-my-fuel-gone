{React, ReactDOM} = window
{Input, Button, Table, Well, Panel, ListGroup, ListGroupItem, Alert} = ReactBootstrap

cloneByJson = (o) -> JSON.parse(JSON.stringify(o))

AlertDismissable = React.createClass
  getInitialState: ->
    show: false
    text: null

  componentWillReceiveProps: (nextProps) ->
    if @state.text != nextProps.text
      @setState
        show: true
        text: nextProps.text

  render: ->
    <div>
     {
      if @state.show
        options = @props.options
        <Alert onDismiss={@handleAlertDismiss} {...options}>
          {@state.text}
        </Alert>
     }
    </div>

  handleAlertDismiss: ->
    @setState
      show: false
      text: null

# PROTOCAL
#   All menu properties will be accumulated to its children except sub.
#   See accumulateMenu
# MENU := 
#   title:
#       The text shown in the dropdown input in its parent
#   value:
#       If exists, this item is a terminate and will return this as raw_value.
#   sub:
#       {MENU_ID: MENUITEM}
#       If exists, this item is a dropdown input.
#       Otherwise, this item is a text input.
#       Use the form of '_abcd' as MENU_ID to distinguish it from menu properties.
#   applyEnabledFunc:
#       (path, raw_value) -> Boolean
#       Return true if the "Apply" button is enabled
#   preprocess:
#       (path, raw_value) -> pre_value
#       Change the raw input to make it easier to store and process afterwards.
#       Will be called the first time adding this rule.
#       Result must be JSONisable.
#   testError:
#       (path, pre_value) -> String | undefined
#       The raw_value is valid if the input return undefined.
#       Otherwise, return the error prompt.
#       Like applyEnabledFunc, but more of runtime check.
#   postprocess:
#       (path, pre_value) -> post_value
#       Change the value returned by preprocess to make easier to process.
#       Will be called every time adding this rule (e.g. at start up).
#       Result does not have to be JSONisable.
#   func:
#       (path, post_value, record) -> Boolean
#       Filter function. Return true if the record satisfies the filter
#   textFunc:
#       (path, post_value) -> String
#       The text interpretation to be displayed in rule list.

menuTree = 
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
           textFunc: (path, value) ->
             "On a map that has #{if value then 'not ' else ''}been cleared"
           sub: 
             '_1': 
               title: 'The map has been cleared'
               value: false
             '_2':
               title: 'The map has not been cleared'
               value: true
         '_id':
           title: 'Map number'
           func: (path, value, record) ->
             record.map?.id == value
           textFunc: (path, value) ->
             "On map #{value}"
           options:
             placeholder: 'Enter the map number here (e.g. 2-3, 32-5)' 
         '_rank':
           title: 'Map rank'
           func: (path, value, record) ->
             if value == 0
               !record.map?.rank?
             else
               record.map?.rank == value
           textFunc: (path, value) ->
             if value == 0
               "On a map with no rank"
             else
               "On a map of rank "+['', 'Easy', 'Medium', 'Hard'][value]
           sub: 
             '_0': 
               title: 'No rank'
               value: 0
             '_1': 
               title: 'Easy'
               value: 1
             '_2':
               title: 'Medium'
               value: 2
             '_3':
               title: 'Hard'
               value: 3
     '_ship':
       title: 'Ship'
       sub:
         '_name':
           title: 'By ship name'
           postprocess: (path, value) ->
             text: value
             regex: new RegExp(value)
           func: (path, value, record) ->
             console.log 'shipname value', value
             record.fleet.concat(record.fleet2 || []).filter(
               (sh) -> value.regex.test $ships[sh.shipId]?.api_name)
             .length != 0
           textFunc: (path, value) ->
             "With ship #{value.text}"
           options:
             placeholder: 'Enter the ship name here. (Javascript regex is supported.)' 
         '_id':
           title: 'By ship id'
           testError: (path, value) ->
             if !_ships?[value]?
               "You have no ship with id #{value}"
           func: (path, value, record) ->
             record.fleet.concat(record.fleet2 || []).filter(
               (sh) -> sh.id?.toString() == value.toString())
             .length != 0
           textFunc: (path, value) ->
             name = _ships[value].api_name
             "With ship #{name} (##{value})"
           options:
             placeholder: 'Enter the ship id here. You can find it in Ship Girls Info at the first column.' 

accumulateMenu = (path) ->
  # Accumulate all properties during the menu path
  nowMenu = {sub: menuTree}
  menuLevels = ((nowMenu=nowMenu?.sub?[id]) for id in path).filter((o)->o?)
  totalDetails = Object.assign.apply this, [{}].concat(menuLevels)
  if !menuLevels[menuLevels.length-1].sub?
    delete totalDetails.sub
  totalDetails

FilterSelectorMenu = React.createClass
  getInitialState: ->
    nowMenuPath: ['_root']
    nowLastMenu: menuTree['_root']
    filterValue: null
    applyEnabled: false
    errorText: null

  handleDropdownChange: (level, e) ->
    path = @state.nowMenuPath[0..level]
    path.push e.target.value
    totalDetails = accumulateMenu path
    @setState
      nowMenuPath: path
      nowLastMenu: totalDetails
      applyEnabled: totalDetails.value?
      filterValue: totalDetails.value

  handleTextChange: (e) ->
    path = @state.nowMenuPath
    nowMenu = @state.nowLastMenu
    value = e.target.value
    @setState
      applyEnabled: !nowMenu.applyEnabledFunc? || nowMenu.applyEnabledFunc path, value
      filterValue: value

  handleAddFilter: ->
    console.log 'nmp', @state.nowMenuPath
    path = @state.nowMenuPath.slice()
    console.log path
    menu = @state.nowLastMenu
    preprocess = menu.preprocess || ((path, value) -> value)
    value = cloneByJson(preprocess(path, @state.filterValue))
    if (errorText = menu.testError path, value)?
      console.log errorText
      @setState {errorText}
    else
      @props.onAddFilter? path, value

  render: ->
    <Panel collapsible defaultExpanded header="Filter">
      <form className="form-horizontal">
        <ListGroup fill>
         {
          nowMenu = {sub: menuTree}
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
                  onChange={@handleDropdownChange.bind(this, level)}
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
                <Input type="text" onChange={@handleTextChange}
                  {...options} />
         }
        </ListGroup>
        {
          <AlertDismissable text={@state.errorText} options={
            dismissAfter: 4000
            bsStyle: 'warning'
          }/>
        }
        {
          lastMenu = @state.nowLastMenu
          console.log 'last', lastMenu
          if !lastMenu? || !lastMenu.sub?
            valid = @state.applyEnabled
            <Button disabled={!valid} onClick={@handleAddFilter}>Apply</Button>
        }
      </form>
    </Panel>


FilterSelector = React.createClass
  getInitialState: ->
    nowFilterList: []

  generateFilterFunc_: (filterList) ->
    if filterList.length == 0
      return -> true
    funcs = filterList.map ({path, value, menu}) =>
      menu.func.bind(this, path, value)
    (record) ->
      funcs.every (f) -> f(record)

  handleAddError: (errorText) ->
    @set

  handleAddFilter: (path, value) ->
    nowFilterList = @state.nowFilterList
    menu = accumulateMenu(path)
    postprocess = menu.postprocess || ((path, value) -> value)
    console.log path, menu, postprocess, value, postprocess(value)
    nowFilterList.push
      path: path
      value: postprocess(path, value)
      menu: menu
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
      <FilterSelectorMenu onAddFilter={@handleAddFilter} />
      {
        if @state.nowFilterList?.length
          <Alert bsStyle="info" style={marginLeft: 20, marginRight: 20}>
            Filters applying
            <ul>
             {
              for {path, value, menu}, i in @state.nowFilterList
                <li key="applied-filter-#{i}">
                  {menu.textFunc? path, value}
                  <i className="fa fa-times remove-filter-icon"
                    onClick={@handleRemoveFilter.bind(this, i)}></i>
                </li>
             }
            </ul>
          </Alert>
      }
    </div>

module.exports = {FilterSelector}
