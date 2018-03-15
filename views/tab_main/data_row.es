/* global __ */

import React, { Component } from 'react'
import PropTypes from 'prop-types'
import { connect } from 'react-redux'

import { RowBase } from './row_base'
import { DataRowDetail } from './data_row_detail'

function CollapseIcon(props) {
  // North=angle 0, East=angle 90, South=angle 180, West=angle 270
  const angle = props.open ? props.openAngle : props.closeAngle
  const rotateClass = angle == 0 ? '' : `fa-rotate-${angle}`
  return (
    <i className={`fa fa-chevron-circle-up ${rotateClass} collapse-icon`} style={props.style}></i>
  )
}

export const DataRow = connect(
  (state) => ({
    $ships: state.const.$ships,
  })
)(class DataRow extends Component {
  static contextTypes = {
    recordCalculator: PropTypes.func.isRequired,
  }

  constructor(props) {
    super(props)
    this.state = {
      subopen: {
      },
    }
  }

  onToggle = () => {
    this.props.setRowExpanded(!this.props.open)
  }

  sumRow = (recordData) => {
    const { id, record, open } = this.props
    // ID
    const idNode = (
      <div>
        <CollapseIcon
          key='rowClosingIcon'
          open={open}
          closeAngle={90}
          openAngle={180}
          style={{ marginRight: '4px' }} />
        {id}
      </div>
    )

    // Date
    const timeText = new Date(record.time).toLocaleString(window.language, {
      hour12: false,
    })

    // Map text
    let mapText = `${record.map.name}(${record.map.id})`
    if (record.map.rank != null)
      mapText += ['', __('Extremely Easy'), __('Easy'), __('Medium'), __('Hard')][record.map.rank]

    const mapHp = record.map.hp ? `${record.map.hp[0]}/${record.map.hp[1]}` : ''

    // Bucket
    const bucketText = recordData.bucketNum || ''

    // Sum data
    const sumData = recordData.sum.concat([bucketText])

    const contents = [idNode, timeText, mapText, mapHp].concat(sumData)

    return (
      <RowBase className="data-row-sum-row" contents={contents} onClick={this.onToggle} />
    )

  }

  render() {
    const { record, open } = this.props
    const { recordCalculator } = this.context
    const recordData = recordCalculator(record)
    return (
      <div
        className="table-row-display"
      >
        {this.sumRow(recordData)}
        <DataRowDetail
          open={open}
          record={record}
          recordData={recordData}
        />
      </div>
    )
  }
})
