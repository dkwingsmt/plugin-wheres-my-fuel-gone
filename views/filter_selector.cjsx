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

menuTree = require './menu'

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
    return {errors: ['Unrecognized filter']}
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
