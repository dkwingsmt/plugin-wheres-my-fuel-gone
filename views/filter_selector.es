import React, { Component } from 'react'
import { connect } from 'react-redux'
import { createSelector } from 'reselect'
import { FormControl, FormGroup, Button, Panel, Alert } from 'react-bootstrap'
import { get, forEach, last, size, partial, map } from 'lodash'
import classNames from 'classnames'
import menuTree from './menu'

const { __ } = window.i18n["poi-plugin-wheres-my-fuel-gone"]

class AlertDismissable extends Component {
  constructor(props) {
    super(props)
    this.state = {
      show: false,
      text: null,
    }
  }

  componentWillReceiveProps(nextProps) {
    if (this.state.text !== nextProps.text) {
      return this.setState({
        show: !(nextProps.text == null),
        text: nextProps.text,
      })
    }
  }

  handleAlertDismiss = () => {
    let base
    this.setState({
      show: false,
      text: null,
    })
    return typeof (base = this.props).onDismiss === "function" ? base.onDismiss() : void 0
  }

  render() {
    const { show, text } = this.state
    const { options } = this.props
    return show ? (
      <Alert
        onDismiss={this.handleAlertDismiss}
        style={{ border: 0, margin: '8px 0 0' }}
        {...options}
      >
        {text}
      </Alert>
    ) : null
  }
}

class StatefulInputText extends Component {
  constructor(props) {
    super(props)
    this.state = {
      text: '',
    }
  }

  onChange = (e) => {
    const { onChange } = this.props
    if (onChange) {
      onChange(e.target.value)
    }
    this.setState({
      text: e.target.value,
    })
  }

  render() {
    const { text } = this.state
    return (
      <FormControl
        type="text"
        value={text}
        {...this.props}
        onChange={this.onChange}
      />
    )
  }
}

function accumulateMenu(path) {
  const menuLevels = [{
    sub: menuTree,
  }]
  forEach(path, (id) => {
    const nowMenu = get(last(menuLevels), ['sub', id])
    if (nowMenu) {
      menuLevels.push(nowMenu)
    } else {
      return false
    }
  })
  const totalDetails = Object.assign.apply(this, [{}].concat(menuLevels))
  if (last(menuLevels).sub == null) {
    delete totalDetails.sub
  }
  return totalDetails
}

export class RuleSelectorMenu extends Component {
  constructor(props) {
    super(props)
    this.state = {
      nowMenuPath: ['_root'],
      inputText: '',
      errorText: null,
    }
  }

  handleDropdownChange = (level, e) => {
    this.clearErrorText()
    const path = this.state.nowMenuPath.slice(0, level + 1).concat([e.target.value])
    this.setState({
      nowMenuPath: path,
    })
  }

  handleTextChange = (value) => {
    this.setState({
      inputText: value,
    })
  }

  handleAddRule = () => {
    const { onAddRule } = this.props
    const { nowMenuPath, inputText } = this.state
    const path = nowMenuPath.slice()
    const menu = accumulateMenu(path)
    const preprocess = menu.preprocess || ((path, value) => value)
    const value = menu.value != null ? menu.value : inputText
    const preValue = preprocess(path, value)
    const testError = menu.testError
    const errorText = testError ? testError(path, preValue) : null
    if (errorText) {
      this.setState({
        errorText: errorText,
      })
    } else {
      onAddRule ? onAddRule(path, preValue) : undefined
    }
  }

  clearErrorText = () => {
    this.setState({
      errorText: null,
    })
  }

  renderMenuList = () => {
    const menus = []
    let nowMenu = { sub: menuTree }
    forEach(this.state.nowMenuPath, ((id, level) => {
      nowMenu = nowMenu.sub[id]
      if (!nowMenu || nowMenu.value != null) {
        return false
      }
      const options = {
        labelClassName: 'col-xs-2 col-md-1',
        wrapperClassName: 'col-xs-10 col-md-11',
        label: ([__('Category'), __('Detail')][level] || ' '),
        bsSize: 'medium',
        ...nowMenu.options,
      }
      // A selection input
      if (nowMenu.sub) {
        menus.push(
          <FormControl
            placeholder='none'
            componentClass="select"
            key={`m${level}${id}`}
            onChange={this.handleDropdownChange.bind(this, level)}
            {...options}
          >
            <option value='none'>{__('Select...')}</option>
            {map(nowMenu.sub, (subItem, subId) => (
              <option
                value={subId}
                key={`option-${level}-${subId}`}
              >
                {subItem.title}
              </option>
            ))}
          </FormControl>
        )
      }
      // A text input
      else {
        menus.push(
          <StatefulInputText
            onChange={this.handleTextChange}
            key={`text-${level}-${id}`}
            {...options}
          />
        )
      }
    }))
    return menus
  }

  renderApplyButton = () => {
    const lastMenu = accumulateMenu(this.state.nowMenuPath)
    const applyHidden = lastMenu && (lastMenu.sub || lastMenu.value == 'none')
    let style
    let valid
    if (applyHidden) {
      style = { display: 'none' }
      valid = true
    } else {
      style = {}
      if (lastMenu.value) {
        valid = true      // value=='none' is eliminated at applyHidden
      } else {
        if (lastMenu.applyEnabledFunc) {
          valid = lastMenu.applyEnabledFunc(this.state.nowMenuPath, this.state.inputText)
        }
        if (valid == null) {
          valid = true
        }
      }
    }
    return (
      <Button disabled={!valid} onClick={this.handleAddRule} style={style} className="filter-apply-button">
        {__('Apply')}
      </Button>
    )
  }

  render() {
    return (
      <Panel collapsible defaultExpanded>
        <Panel.Heading>
          {__('Filter')}
        </Panel.Heading>
        <Panel.Collapse>
          <Panel.Body>
            <form className='form-horizontal'>
              <FormGroup>
                {this.renderMenuList()}
                <AlertDismissable
                  text={this.state.errorText}
                  onDismiss={this.clearErrorText}
                  options={{ dismissAfter: 4000, bsStyle: 'warning' }}
                />
                {this.renderApplyButton()}
              </FormGroup>
            </form>
          </Panel.Body>
        </Panel.Collapse>
      </Panel>
    )
  }
}

const ruleTextsSelector = createSelector(
  (state, ownProps) => state,
  (state, ownProps) => ownProps.ruleTextsFunc,
  (state, ruleTextsFunc) => ruleTextsFunc ? ruleTextsFunc(state) : null,
)

export const RuleDisplay = connect(
  (state, ownProps) => ({
    ruleTexts: ruleTextsSelector(state, ownProps),
  })
)(class RuleDisplay extends Component {
  constructor(props) {
    super(props)
    this.state = {
      saved: false,
      saving: false,
    }
  }

  onRemove = (i) => {
    const { onRemove } = this.props
    if (onRemove) {
      onRemove(i)
    }
  }

  onSave = () => {
    const { onSave } = this.props
    this.setState({
      saved: false,
      saving: true,
    })
    setTimeout(() => {
      this.setState({
        saved: true,
        saving: false,
      })
    }, 50)
    if (onSave) {
      onSave()
    }
  }

  componentWillReceiveProps(nextProps) {
    if (this.props.ruleTextsFunc !== nextProps.ruleTextsFunc) {
      this.setState({
        saved: false,
        saving: false,
      })
    }
  }

  render() {
    const { saved, saving } = this.state
    const { ruleTexts } = this.props
    const className = classNames('fa fa-3x', {
      'save-filter-icon': !saved,
      'saved-filter-icon': saved,
      'fa-bookmark': !saving && !saved,
      'fa-check': !saving && saved,
      'fa-ellipsis-h': saving,
    })
    return (
      <div>
        {!!size(ruleTexts) && (
          <Alert bsStyle='info' style={{ marginLeft: 20, marginRight: 20 }}>
            <div style={{ position: 'relative' }}>
              <p>{__('Rules applying')}</p>
              <ul>
                {ruleTexts.map((ruleText, i) => (
                  <li key={`applied-rule-${i}`}>
                    {ruleText}
                    <i
                      className='fa fa-times remove-rule-icon'
                      onClick={partial(this.onRemove, i)}
                    />
                  </li>
                ))}
              </ul>
              <div style={{ position: 'absolute', right: 0, top: 0, height: '100%', verticalAlign: 'middle' }}>
                <i onClick={this.onSave} className={className} />
              </div>
            </div>
          </Alert>
        )}
      </div>
    )
  }
})

export function portRuleList(rules) {
  let error = false
  const results = rules.map(({ path, value }) => {
    if (error) {
      return null
    }
    const result = accumulateMenu(path).porting(path, value)
    if (result == null) {
      error = true
      return null
    } else {
      return result
    }
  }).filter(Boolean)
  if (error) {
    return null
  } else {
    return results
  }
}

export function translateRuleList(ruleList) {
  if (!size(ruleList)) {
    return {
      errors: ['Unrecognized filter'],
    }
  }
  const errors = []
  const postRules = ruleList.map(({ path, value }) => {
    const menu = accumulateMenu(path) || {}
    const {
      testError,
      postprocess = (path, value) => value,
      func,
      textFunc,
    } = menu
    const errorText = testError ? testError(path, value) : null
    if (errorText) {
      errors.push(errorText)
      return
    }
    const postValue = postprocess(path, value)
    return {
      func: (record, stateConst) => func(path, postValue, record, stateConst),
      textFunc: (state) => textFunc(path, postValue, state),
    }
  }).filter(Boolean)
  if (errors.length) {
    return {
      errors: errors,
    }
  } else {
    return {
      func: (record, stateConst) => postRules.every((r) => r.func(record, stateConst)),
      textsFunc: (state) => map(postRules, (r) => r.textFunc(state)),
    }
  }
}
