import React, { Component } from 'react'
import { Grid, Col, Row, Alert, Panel } from 'react-bootstrap'
import InlineEdit from 'react-edit-inline'
import { join } from 'path-extra'
import classNames from 'classnames'
import { connect } from 'react-redux'
import { sortBy, toPairs, zip } from 'lodash'

import { MaterialIcon } from 'views/components/etc/icon'
import { translateRuleList } from '../filter_selector'
import { pluginDataSelector } from '../redux/selectors'
import { addFilter, removeFilter, renameFilter } from '../redux/filters'

class HalfCollapsiblePanel extends Component {
  constructor(props) {
    super(props)
    this.state = {
      showDetail: false,
    }
  }

  onSwitchDetail = () => {
    const cur = !this.state.showDetail
    this.setState({
      showDetail: cur,
    })
    if (this.props.onToggleExpanded)
      this.props.onToggleExpanded(cur)
  }

  mouseOverDetailPanel = (cur) => {
    this.setState({
      hoverDetailPanel: cur,
    })
  }

  render() {
    // Hover over 1|2 should highlight 1&2
    // Through css we can achieve 1:hover->1, 1:hover->2, 2:hover->2
    // We must use js to achieve 2:hover->1
    const wrapperClassName = classNames('hcp-wrapper', this.props.wrapperClassName)
    const panel1ClassName = classNames('hcp-panel1', {
      'hcp-hover-highlight': !this.state.hoverDetailPanel,
      'hcp-panel-highlight': this.state.hoverDetailPanel,
    }, this.props.panel1ClassName)
    const panel2ClassName = classNames('hcp-panel2 hcp-hover-highlight',
      this.props.panel2ClassName)
    return (
      <div className={wrapperClassName}>
        <div className='hcp-hover-highlight-from' onClick={this.onSwitchDetail}>
          <Panel className={panel1ClassName} header={this.props.header}>
            { this.props.panel1Body }
          </Panel>
        </div>
        {
          !!this.props.panel2Body && (
            <div className='hcp-panel2-psuedo hcp-hover-highlight-to'
              onClick={this.onSwitchDetail}>
              <div className='hcp-panel2-positioner'>
                <Panel className={panel2ClassName}
                  collapsible expanded={this.state.showDetail}
                  onMouseOver={this.mouseOverDetailPanel.bind(this, true)}
                  onMouseLeave={this.mouseOverDetailPanel.bind(this, false)}
                  >
                  { this.props.panel2Body || '' }
                </Panel>
              </div>
            </div>
          )
        }
      </div>
    )
  }
}

class BookmarkTile extends Component {
  constructor(props) {
    super(props)
    this.state = {
      showDetail: false,
    }
  }

  onSwitchDetail = (cur) => {
    this.setState({
      showDetail: cur,
    })
  }

  render() {
    const fullRecords = this.props.fullRecords || []
    const filterJson = this.props.filterJson || {}
    const filter = translateRuleList(filterJson.rules)
    let title
    let body
    let body2
    if (filter.errors) {
      title = [<i className='fa fa-exclamation-triangle icon-margin-right-5' key={1}></i>,
        <span key={2}>{__('Invalid filter')}</span>]
      body = <ul className='bookmark-ul'>
      {
        filter.errors.map((error, i) =>
          <li key={i}>{error}</li>
        )
      }
      </ul>
    } else {
      const data = fullRecords.filter(filter.func)
      const ruleTexts = filter.texts || []
      const consumption = sumUpConsumption(data)
      const consumptionData = resource5to4(consumption.slice(0, 5)).concat(consumption[5])
      title = [<InlineEdit
        key='name-text'
        validate={(text) => (text.length > 0 && text.length < 32)}
        text={filterJson.name}
        paramName='name'
        className='bookmark-name-editing'
        activeClassName='bookmark-name-editing-active'
        change={this.props.onChangeName}
        stopPropagation
        />,
        <i className='fa fa-pencil-square-o bookmark-title-icon-hover-show grey-icon icon-margin-left-5'
          key='name-edit-icon'></i> ]
      body = (
        <Row>
          {
            zip(consumptionData, [1, 2, 3, 4, 6]).map(([num, iconNo]) =>
              <Col xs={3} key={iconNo}>
                <div className='bookmark-icon-wrapper'>
                  <MaterialIcon materialId={iconNo} />
                </div>
                {num}
              </Col>
            )
          }
          <Col xs={9}>
            <div className='bookmark-icon-wrapper'>
              <i className='fa fa-paper-plane-o'></i>
            </div>
            {__("%s sorties", data.length)}
          </Col>
        </Row>
      )
      body2 = (
        <ul className='bookmark-ul'>
        {
          ruleTexts.map((ruleText, i) =>
            <li key={i}>
              {ruleText}
            </li>
          )
        }
        </ul>
      )
    }
    const removeWrapperStyle = classNames({'bookmark-hover-show': !this.state.showDetail})
    const header = (
      <div style={{position: 'relative'}}>
        { title }
        <div style={{position: 'absolute', top: 0, right: 0}}
          className={removeWrapperStyle}>
          <i className='fa fa-trash-o remove-rule-icon'
            onClick={this.props.onRemoveFilter}></i>
        </div>
      </div>
    )
    return (
      <HalfCollapsiblePanel
        wrapperClassName='col-xs-12 bookmark-width'
        panel1ClassName='bookmark-maxwidth bookmark-panel'
        panel2ClassName='bookmark-maxwidth'
        header={header}
        panel1Body={body}
        panel2Body={body2}
        onToggleExpanded={this.onSwitchDetail}
      />
    )
  }
}

export const TabBookmarks = connect(
  (state) => ({
    records: pluginDataSelector(state).records,
    filters: pluginDataSelector(state).filters,
  }), {
    addFilter,
    removeFilter,
    renameFilter,
  }
)(class TabBookmarks extends Component {
  changeName = (time, value) => {
    this.props.renameFilter(time, value.name)
  }

  removeFilter = (time) => {
    this.props.removeFilter(time)
  }

  render() {
    const fullRecords = this.props.records
    return (
      <div className='tabcontents-wrapper'>
       {
        (!this.props.filters || !Object.keys(this.props.filters).length) ? (
          <Alert bsStyle="warning" style={{maxWidth: 800}}>
            <h3>
              {__("You do not have any filters currently")}
            </h3>
            {__("Create a filter in the Table tab, and bookmark it to show it here")}
          </Alert>
        ) : (
          <div>
          {
            sortBy(toPairs(this.props.filters), 0).map(([time, filterJson]) => {
              return (
                <BookmarkTile
                  key={`bookmark-${time}`}
                  fullRecords={fullRecords}
                  filterJson={filterJson}
                  onRemoveFilter={this.removeFilter.bind(this, time)}
                  onChangeName={this.changeName.bind(this, time)}
                  />
              )
            })
          }
          </div>
        )
      }
      </div>
    )
  }
})
