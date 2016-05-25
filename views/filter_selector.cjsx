{React, ReactDOM} = window
{Input, Button, Table, Panel, ListGroup, ListGroupItem, Alert} = ReactBootstrap
moment = require 'moment'
classnames = require 'classnames'

AlertDismissable = React.createClass
  getInitialState: ->
    show: false
    text: null

  componentWillReceiveProps: (nextProps) ->
    if @state.text != nextProps.text
      @setState
        show: !!nextProps.text?
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
    @props.onDismiss?()

StatefulInputText = React.createClass
  getInitialState: ->
    text: ''

  onChange: (e) ->
    @props.onChange? e.target.value
    @setState
      text: e.target.value

  render: ->
    props = @props
    <Input type='text' value={@state.text} {...props} onChange={@onChange}/>
  
timeStr = (time) ->
  moment(time).format('YYYY-M-D HH:mm')

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
      cutoff: 'month'
    when '_before'
      before: true
      local: true
    when '_after'
      after: true
      local: true
    else
      error: __('Invalid time filter category %s', path[path.length-1])
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
    now = nowFunc(value, 'YYYY-MM-DD HH:mm:ss')
    if !now.isValid()
      return {error: __('%s is not a valid time', value)}
    preOffset = 0
    postOffset = offset
    if config.cutoff?
      postOffset -= japanOffset
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


# PROTOCAL FOR MENUTREE
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
#   porting:
#       (path, pre_value) -> {path: PATH, value: VALUE} | null
#       Called after reading from file. Change the filter from older format
#       to the latest one. The bookmark record is changed accordingly afterwards.
#       Return the original {path, value} even if nothing needs porting.
#       Return null if unable to port.
#   postprocess:
#       (path, pre_value) -> post_value
#       Change the value returned by preprocess to make easier to process.
#       Will be called every time adding this rule (e.g. at start up).
#       Result does not have to be JSONisable.
#   func:
#       (path, post_value, record) -> Boolean
#       Rule filtering function. Return true if the record satisfies the rule
#   textFunc:
#       (path, post_value) -> String
#       The text interpretation to be displayed in rule list.
menuTree = 
 '_root':
   # Default
   func: -> true
   applyEnabledFunc: (path, value) ->
     value? && value.length != 0
   porting: (path, value) -> {path, value}
   sub:
     '_map': 
       title: __('World')
       sub:
         '_id':
           title: __('World number')
           func: (path, value, record) ->
             match = value.match /^\/(.+)\/([gim]*)$/
             if match?
               try
                 record.map?.id.match(new RegExp match[1], match[2])?
             else
               record.map?.id == value
           textFunc: (path, value) ->
             __('In world %s', value)
           options:
             placeholder: __('Enter the map number here (e.g. 2-3, 32-5)')
         '_rank':
           title: __('World difficulty')
           func: (path, value, record) ->
             if value == 0
               !record.map?.rank?
             else
               record.map?.rank?.toString() == value.toString()
           textFunc: (path, value) ->
             __('In %s difficulty', __(['', 'Easy', 'Medium', 'Hard'][value]))
           sub: 
             '_ez': 
               title: __('Easy')
               value: 1
             '_md':
               title: __('Medium')
               value: 2
             '_hd':
               title: __('Hard')
               value: 3
         '_hp':
           title: __('World clearance')
           func: (path, value, record) ->
             (record.map?.hp?[0] > 0) == value
           textFunc: (path, value) ->
             if value
               __('In a world not yet cleared')
             else
               __('In a cleared world')
           sub: 
             '_2':
               title: __('The map has not been cleared')
               value: true
             '_1': 
               title: __('The world has been cleared')
               value: false
     '_ship':
       title: __('Ship')
       sub:
         '_name':
           title: __('By ship name')
           postprocess: (path, value) ->
             text: value
             regex: new RegExp(value)
           func: (path, value, record) ->
             record.fleet.filter(
               (sh) -> value.regex.test $ships[sh.shipId]?.api_name)
             .length != 0
           textFunc: (path, value) ->
             __('With ship %s', value.text)
           options:
             placeholder: __('Enter the ship name here. (Javascript regex is supported.)')
         '_id':
           title: __('By ship id')
           testError: (path, value) ->
             if !_ships?[value]?
               __('You have no ship with id %s', value)
           func: (path, value, record) ->
             record.fleet.filter(
               (sh) -> sh.id?.toString() == value.toString())
             .length != 0
           textFunc: (path, value) ->
             name = _ships[value].api_name
             __('With ship %s (#%s)', name, value)
           options:
             placeholder: __('Enter the ship id here. You can find it in Ship Girls Info at the first column.')
     '_time':
       title: __('Time')
       func: (path, value, record) ->
         result = true
         if value.before?
           result = result && record.time <= value.before
         if value.after?
           result = result && record.time >= value.after
         result
       testError: (path, value) ->
         value.error
       porting: (path, value) ->
         # Format until 0.2.1 
         if value.textOptions?
           return if path[path.length-1] in ['_after', '_before']
             path: path
             # Use full format here to preserve information
             value: moment(value.after || value.before).format('YYYY-MM-DD HH:mm:ss')
           else if path[path.length-1] in ['_daily', '_weekly', '_monthly', '_eo']
             # Use full format here to preserve information
             {path: path, value: moment(value.after).format('YYYY-MM-DD')}
           else     # '_this_xxx'
             {path: path, value: 'now'}
         {path, value}
       postprocess: parseTimeMenu
       textFunc: (path, value) ->
         # '_before' and '_after' have their own textFunc overridden
         pathSplit = path[path.length-1].split('_').reverse()
         cycle = __ switch pathSplit[0]
           when 'daily'
             'daily quest'
           when 'weekly'
             'weekly quest'
           when 'monthly'
             'monthly quest'
           when 'eo'
             'Extra Operation'
         current = __ if pathSplit[1] == 'this' then 'current ' else ''
         beforeTime = if value.before then timeStr(value.before) else __ 'now'
         beforeText = __ ' to %s', beforeTime
         if value.after
           afterText = __ ' from %s', timeStr(value.after)
         else
           afterText = ''
         __('During the %(current)s%(cycle)s cycle%(afterText)s%(beforeText)s',
           {current, cycle, afterText, beforeText})
       sub:
         '_this_daily':
           title: __('During today\'s daily quest cycle')
           value: 'now'
         '_this_weekly':
           title: __('During the current weekly quest cycle')
           value: 'now'
         '_this_monthly':
           title: __('During the current monthly quest cycle')
           value: 'now'
         '_this_eo':
           title: __('During the current monthly Extra Operation cycle')
           value: 'now'
         '_daily':
           title: __('During a specified daily quest cycle')
           options:
             placeholder: __('Enter the date (Japan local time) as yyyy-mm-dd (e.g. 2016-01-31)')
         '_weekly':
           title: __('During a specified weekly quest cycle')
           options:
             placeholder: __('Enter any date during that week (Japan local time) as yyyy-mm-dd (e.g. 2016-01-31)')
         '_monthly':
           title: __('During a specified monthly quest cycle')
           options:
             placeholder: __('Enter the month as yyyy-mm (e.g. 2016-01)')
         '_eo':
           title: __('During a specified monthly Extra Operation cycle')
           options:
             placeholder: __('Enter the month as yyyy-mm (e.g. 2016-01)')
         '_before':
           title: __('Before a specified time')
           options:
             placeholder: __('Enter your local time as yyyy-mm-dd hh:mm:ss. Latter parts can be omitted.')
           textFunc: (path, value) ->
             __ 'Before %s', timeStr(value.before)
         '_after':
           title: __('After a specified time')
           options:
             placeholder: __('Enter your local time as yyyy-mm-dd hh:mm:ss. Latter parts can be omitted.')
           textFunc: (path, value) ->
             __ 'After %s', timeStr(value.after)

accumulateMenu = (path) ->
  # Accumulate all properties during the menu path
  nowMenu = {sub: menuTree}
  menuLevels = ((nowMenu=nowMenu?.sub?[id]) for id in path).filter((o)->o?)
  totalDetails = Object.assign.apply this, [{}].concat(menuLevels)
  if !menuLevels[menuLevels.length-1].sub?
    delete totalDetails.sub
  totalDetails

RuleSelectorMenu = React.createClass
  getInitialState: ->
    nowMenuPath: ['_root']
    inputText: ''
    errorText: null

  handleDropdownChange: (level, e) ->
    @clearErrorText()
    path = @state.nowMenuPath[0..level]
    path.push e.target.value
    @setState
      nowMenuPath: path

  handleTextChange: (value) ->
    @setState
      inputText: value

  handleAddRule: ->
    path = @state.nowMenuPath.slice()
    menu = accumulateMenu path
    preprocess = menu.preprocess || ((path, value) -> value)
    value = if menu.value? then menu.value else @state.inputText
    preValue = preprocess path, value
    if menu.testError? && (errorText = menu.testError path, preValue)?
      @setState {errorText}
    else
      @props.onAddRule? path, preValue

  clearErrorText: ->
    @setState
      errorText: null

  render: ->
    applyEnable = false
    lastMenu = accumulateMenu @state.nowMenuPath
    <Panel collapsible defaultExpanded header={__ 'Filter'}>
      <form className='form-horizontal'>
        <ListGroup fill>
         {
          nowMenu = {sub: menuTree}
          for id, level in @state.nowMenuPath
            nowMenu = nowMenu.sub[id]
            if nowMenu? && !nowMenu.value?
              options = Object.assign 
                labelClassName: 'col-xs-2 col-md-1'
                wrapperClassName: 'col-xs-10 col-md-11'
                label: ([__('Category'), __('Detail')][level] || ' ')
                bsSize: 'medium'
                nowMenu.options
              # A selection input
              if nowMenu.sub?
                <Input type='select' key={"m#{level}#{id}"}
                  onChange={@handleDropdownChange.bind(this, level)}
                  {...options} >
                  <option value='none'>{__ 'Select...'}</option>
                  {
                    for subId, subItem of nowMenu.sub
                      <option value={subId} key={"option-#{level}-#{subId}"}>
                        {subItem.title}
                      </option>
                  }
                </Input>

              # A text input
              else
                <StatefulInputText onChange={@handleTextChange}
                  key={"text-#{level}-#{id}"}
                  {...options} />
         }
        </ListGroup>
        {
          <AlertDismissable text={@state.errorText}
            onDismiss={@clearErrorText}
            options={{dismissAfter: 4000, bsStyle: 'warning'}}
            />
        }
        {
          applyHidden = lastMenu? && (lastMenu.sub? || lastMenu.value == 'none')
          if applyHidden
            style = {display: 'none'}
            valid = true
          else
            style = {}
            if lastMenu.value?
              valid = true      # value=='none' is eliminated at applyHidden
            else
              valid = lastMenu.applyEnabledFunc? @state.nowMenuPath, @state.inputText
              valid ?= true
          <Button disabled={!valid} onClick={@handleAddRule} style={style}>
            {__ 'Apply'}
          </Button>
        }
      </form>
    </Panel>

RuleDisplay = React.createClass
  getInitialState: ->
    saved: false
    saving: false

  onRemove: (i) ->
    @props.onRemove? i

  onSave: ->
    @setState
      saved: false
      saving: true
    setTimeout (=> @setState {saved: true, saving: false}), 50
    @props.onSave?()

  componentWillReceiveProps: (nextProps) ->
    if @props.ruleTexts != nextProps.ruleTexts
      @setState
        saved: false
        saving: false

  render: ->
    <div>
     {
      if @props.ruleTexts?.length
        <Alert bsStyle='info' style={marginLeft: 20, marginRight: 20}>
          <div style={position: 'relative'}>
            <p>{__ 'Rules applying'}</p>
            <ul>
             {
              for ruleText, i in @props.ruleTexts
                <li key="applied-rule-#{i}">
                  {ruleText}
                  <i className='fa fa-times remove-rule-icon'
                    onClick={_.partial @onRemove, i}></i>
                </li>
             }
            </ul>
            <div style={position: 'absolute', right: 0, top: 0, height: '100%', verticalAlign: 'middle'}>
             {
              {saved, saving} = @state
              className = classnames 'fa fa-3x',
                'save-filter-icon': !saved
                'saved-filter-icon': saved
                'fa-bookmark': !saving && !saved
                'fa-check': !saving && saved
                'fa-ellipsis-h': saving
              <i onClick={@onSave} className=className></i>
             }
            </div>
          </div>
        </Alert>
     }
    </div>

portRuleList = (rules) ->
  # Arguments
  #   rules: [{path, value}, ...]
  # Return
  #     null                   if any rules are incompatible
  #   | [{path, value}, ...]    otherwise
  error = false
  results = for {path, value} in rules
    result = (accumulateMenu path).porting path, value
    if !result?
      error = true
      break
    else
      result
  if error then null else results

translateRuleList = (ruleList) ->
  # Return either 
  #   func: A function that returns true if the record satisfies this filter
  #     (record) -> Boolean
  #   texts: A list of description of each rule
  #     [String]
  # or
  #   errors:
  #     [String]
  if !ruleList? || ruleList.length == 0
    return -> true
  errors = []
  postRules = ruleList.map ({path, value}) ->
    menu = accumulateMenu path
    if (errorText = menu.testError? path, value)?
      errors.push errorText
      return
    postprocess = menu.postprocess || ((path, value) -> value)
    postValue = postprocess(path, value)
    func: menu.func.bind(this, path, postValue)
    text: menu.textFunc(path, postValue)
  if errors.length
    errors: errors
  else
    func: (record) -> postRules.every (r) -> r.func(record)
    texts: (r.text for r in postRules)

module.exports = {RuleSelectorMenu, RuleDisplay, translateRuleList, portRuleList}
