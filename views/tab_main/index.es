import React, { Component } from 'react'
import { Pagination } from 'react-bootstrap'
import { connect } from 'react-redux'
import { defaultMemoize, createSelector } from 'reselect'
import { get } from 'lodash'

import { pluginDataSelector } from '../redux/selectors'
import { addFilter } from '../redux/filters'
import { RuleSelectorMenu, RuleDisplay, translateRuleList } from '../filter_selector'
import { MainTable } from './main_table'

const CONFIG_PREFIX = 'poi-plugin-wheres-my-fuel-gone'

export default connect(
  (state) => ({
    records: pluginDataSelector(state).records,
    pageSize: parseInt(get(state.config, `${CONFIG_PREFIX}.pageSize`)) || 20,
    admiralId: get(state, 'info.basic.api_member_id'),
    stateConst: state.const,
  }), {
    addFilter,
  }
)(class TabMain extends Component {
  constructor(props) {
    super(props)
    this.state = {
      ruleList: [],
      ruleTexts: [],
      activePage: 1,
    }
  }

  handleSelectPage = (eventKey) => {
    this.setState({
      activePage: eventKey,
    })
  }

  addRule = (path, value) => {
    const ruleList = this.state.ruleList.concat([{ path, value }])
    this.setState({
      ruleList: ruleList,
    })
    this.filterChangeTo(ruleList)
  }

  removeRule = (i) => {
    let ruleList
    if (i == null) {
      ruleList = []
    } else {
      ruleList = this.state.ruleList
      ruleList.splice(i, 1)
    }
    this.setState({
      ruleList: ruleList,
    })
    this.filterChangeTo(ruleList)
  }

  saveFilter = () => {
    this.props.addFilter(this.state.ruleList)
  }

  filterChangeTo = (nowRuleList) => {
    // testError has been done at RuleSelectorMenu
    const { func, textsFunc/*, errors*/ } = translateRuleList(nowRuleList)
    this.setState({
      ruleTextsFunc: textsFunc,
      filter: func,
      activePage: 1,
    })
  }

  getFilteredData = defaultMemoize((fullRecords, filterFunc, stateConst) =>
    (fullRecords || []).filter((data) =>
      (filterFunc || (() => true))(data, stateConst)
    ).reverse()
  )

  render() {
    const { records, pageSize, stateConst } = this.props
    const data = this.getFilteredData(records, this.state.filter, stateConst)
    const dataLen = data.length
    const startNo = Math.min((this.state.activePage-1)*pageSize, dataLen)
    const maxPages = Math.max(Math.ceil((data.length)/pageSize), 1)
    const displaySumRow = this.state.ruleList.length != 0

    return (
      <div className='tabcontents-wrapper'>
        <RuleSelectorMenu
          onAddRule={this.addRule}
        />
        <RuleDisplay
          ruleTextsFunc={this.state.ruleTextsFunc}
          onSave={this.saveFilter}
          onRemove={this.removeRule}
        />
        <MainTable
          data={data}
          startNo={startNo}
          pageSize={pageSize}
          displaySumRow={displaySumRow}
        />
        <div style={{ textAlign: 'center' }}>
          <Pagination
            first
            last
            ellipsis
            items={maxPages}
            maxButtons={5}
            activePage={this.state.activePage}
            onSelect={this.handleSelectPage}
          />
        </div>
      </div>
    )
  }
})
