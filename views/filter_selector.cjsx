{React, ReactDOM} = window
{Input, Button, Table, Well, Panel, ListGroup, ListGroupItem, Alert} = ReactBootstrap
moment = require 'moment'

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

# This function is written totally based on unit test. See comments after it.
parseTimeMenu = (path, value) ->
  config = switch(path[path.length-1])
    when '_this_daily'
      after: 'startOf'
      cutoff: 'day'
      offset: moment.duration(5, 'hours')
      local: true
    when '_this_weekly'
      after: 'startOf'
      cutoff: 'isoWeek'
      offset: moment.duration(5, 'hours')
      local: true
    when '_this_monthly'
      after: 'startOf'
      cutoff: 'month'
      offset: moment.duration(5, 'hours')
    when '_this_eo'
      after: 'startOf'
      cutoff: 'month'
    when '_daily'
      after: 'startOf'
      before: 'endOf'
      cutoff: 'day'
      offset: moment.duration(5, 'hours')
    when '_weekly'
      after: 'startOf'
      before: 'endOf'
      cutoff: 'isoWeek'
      offset: moment.duration(5, 'hours')
    when '_monthly'
      after: 'startOf'
      before: 'endOf'
      cutoff: 'month'
      offset: moment.duration(5, 'hours')
    when '_eo'
      after: 'startOf'
      before: 'endOf'
      cutoff: 'monthly'
    when '_before'
      before: true
      local: true
    when '_after'
      after: true
      local: true
    else
      error: 'Invalid key'
  if config.error?
    return {error: config.error}

  doCutOff = (time, fnName, cutoff) ->
    if time?
      if cutoff?
        time[fnName]?(cutoff)
      else if fnName
        time

  offset = config.offset || 0
  japanOffset = moment.duration(9, 'hours')
  myOffset = moment().utcOffset()*moment.duration(1, 'minutes')
  nowFunc = if config.local then moment else moment.utc
  if value == 'now'
    now = nowFunc()
    preOffset = japanOffset - offset - myOffset
    postOffset = -japanOffset + offset
  else
    now = nowFunc(value, "YYYY-MM-DD HH:mm:ss")
    preOffset = 0
    postOffset = offset
    if config.cutoff?
      postOffset -= japanOffset
  if !now.isValid()
    return {error: 'Invalid time'}
  now = now.add(preOffset).utc()
  beforeTime = doCutOff(now.clone(), config.before, config.cutoff)?.add(postOffset)
  afterTime = doCutOff(now.clone(), config.after, config.cutoff)?.add(postOffset)

  result = {}
  result.before = +beforeTime if beforeTime?
  result.after = +afterTime if afterTime?
  result
#** Unit tests for parseTimeMenu
#_check = (a, b, local=false) ->
#  func = if local then 'local' else 'utc'
#  toMoment = (t) -> if t? then moment(t) else undefined
#  toMoment(a.after)?[func]().format() == b.after && toMoment(a.before)?[func]().format() == b.before
#** The following tests should yield true
#console.log _check parseTimeMenu(['_weekly'], '2016/1/17'),
#  before: '2016-01-17T19:59:59+00:00'
#  after: '2016-01-10T20:00:00+00:00'
#console.log _check parseTimeMenu(['_this_eo'], 'now'),
#  after: '2015-12-31T15:00:00+00:00'
#** The following tests are based on current time so can't yield true, 
#** You should manually check if parseTimeMenu gives reasonable results   
#console.log _check parseTimeMenu(['_this_daily'], 'now'),
#  after: '2016-01-17T20:00:00+00:00'
#console.log _check parseTimeMenu(['_this_weekly'], 'now'),
#  after: '2016-01-17T20:00:00+00:00'
#console.log _check parseTimeMenu(['_this_monthly'], 'now'),
#  after: '2015-12-31T20:00:00+00:00'
#** The following tests should vary only on time zone (-06:00 -> +08:00 or etc)
#console.log _check parseTimeMenu(['_after'], '2016/1/17 23:59:59'),
#  after: '2016-01-17T23:59:59-06:00'
#  true
#console.log _check parseTimeMenu(['_before'], '2016/1/17'),
#  before: '2016-01-17T00:00:00-06:00'
#  true


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
     '_time':
       title: 'Time'
       func: (path, value, record) ->
         result = true
         if value.before?
           result = result && record.time <= value.before
         if value.after?
           result = result && record.time >= value.after
         result
       preprocess: parseTimeMenu
       postprocess: (path, value) ->
         before: value.before
         beforeText: if value.before then moment(value.before).local().format()
         after: value.after
         afterText: if value.after then moment(value.after).local().format()
       sub:
         '_this_daily':
           title: 'During this daily quest cycle'
           value: 'now'
           textFunc: (path, value) ->
             "During the daily quest cycle from #{value.afterText} to now"
         '_this_weekly':
           title: 'During this weekly quest cycle'
           value: 'now'
           textFunc: (path, value) ->
             "During the weekly quest cycle from #{value.afterText} to now"
         '_this_monthly':
           title: 'During this monthly quest cycle'
           value: 'now'
           textFunc: (path, value) ->
             "During the monthly quest cycle from #{value.afterText} to now"
         '_this_eo':
           title: 'During this monthly Extra Operation cycle'
           value: 'now'
           textFunc: (path, value) ->
             "During the Extra Operation cycle from #{value.afterText} to now"
         '_daily':
           title: 'During a specified daily quest cycle'
           options:
             placeholder: 'Enter the date (Japan local time) as yyyy-mm-dd (e.g. 2016-01-31)' 
           textFunc: (path, value) ->
             "During the daily quest cycle from #{value.afterText} to #{value.beforeText}"
         '_weekly':
           title: 'During a specified weekly quest cycle'
           options:
             placeholder: 'Enter any date during that week (Japan local time) as yyyy-mm-dd (e.g. 2016-01-31)' 
           textFunc: (path, value) ->
             "During the weekly quest cycle from #{value.afterText} to #{value.beforeText}"
         '_monthly':
           title: 'During a specified monthly quest cycle'
           options:
             placeholder: 'Enter the month as yyyy-mm (e.g. 2016-01)' 
           textFunc: (path, value) ->
             "During the monthly quest cycle from #{value.afterText} to #{value.beforeText}"
         '_eo':
           title: 'During a specified monthly Extra Operation cycle'
           options:
             placeholder: 'Enter the month as yyyy-mm (e.g. 2016-01)' 
           textFunc: (path, value) ->
             "During the Extra Operation cycle from #{value.beforeText} to #{value.afterText}"
         '_before':
           title: 'Before specified time'
           options:
             placeholder: 'Enter your local time as yyyy-mm-dd hh:mm:ss. Latter parts can be omitted.' 
           textFunc: (path, value) ->
             "Before #{value.beforeText}"
         '_after':
           title: 'After specified time'
           options:
             placeholder: 'Enter your local time as yyyy-mm-dd hh:mm:ss. Latter parts can be omitted.' 
           textFunc: (path, value) ->
             "After #{value.afterText}"

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
    path = @state.nowMenuPath.slice()
    menu = @state.nowLastMenu
    preprocess = menu.preprocess || ((path, value) -> value)
    value = cloneByJson(preprocess(path, @state.filterValue))
    if menu.testError? && (errorText = menu.testError path, value)?
      @setState {errorText}
    else
      @props.onAddFilter? path, value

  render: ->
    <Panel collapsible defaultExpanded header="Filter">
      <form className="form-horizontal">
        <ListGroup fill>
         {
          nowMenu = {sub: menuTree}
          for id, level in @state.nowMenuPath
            nowMenu = nowMenu.sub[id]
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
    nowFilterList.push
      path: path
      value: postprocess(path, value)
      menu: menu
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
