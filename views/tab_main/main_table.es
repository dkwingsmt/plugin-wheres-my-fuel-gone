import React, { Component } from 'react'
import { Collapse, Button, Table, OverlayTrigger, Tooltip } from 'react-bootstrap'
import path from 'path-extra'
import classNames from 'classnames'
import { connect } from 'react-redux'
import { zip, range, sum } from 'lodash'

import { arraySum } from 'views/utils/tools'
import {HeaderRow} from './header_row'
import {DataRow} from './data_row'

export class MainTable extends Component {
  constructor(props) {
    super(props)
    this.state = {
      rowsExpanded: {},
    }
  }

  handleSetRowExpanded = (time, expanded) => {
    const rowsExpanded = this.state.rowsExpanded
    rowsExpanded[time] = expanded
    this.setState({rowsExpanded})
  }

  render() {
    const {data, startNo, recordCalculator} = this.props

    return (
      <div id='main-table' className="table">
        <HeaderRow key="header" />
        {
          data.map((record, i) => {
            const rowExpanded = this.state.rowsExpanded[record.time] || false
            const displayId = startNo + i + 1
            return (
              <DataRow
                key={`data-${record.time}-${i}`}
                record={record}
                open={rowExpanded}
                setRowExpanded={this.handleSetRowExpanded.bind(this, record.time)}
                id={displayId}
                recordCalculator={recordCalculator}
              />
            )
          })
        }
      </div>
    )
  }
}
