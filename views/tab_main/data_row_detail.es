/* global __ */

import React, { Component } from 'react'
import { connect } from 'react-redux'
import { zip, get, join, sum } from 'lodash'
import classNames from 'classnames'

import { Collapse, OverlayTrigger, Tooltip } from 'react-bootstrap'
import { sortieFleetDisplayModeSelector } from '../tab_extra/utils'
import { RowBase } from './row_base'

function LeadingIcon({ className, tooltip, tooltipId }) {
  const icon = (
    <i className={classNames("table-leading-icon", className)} />
  )
  if (!tooltip) {
    return icon
  }
  return (
    <OverlayTrigger
      placement='left'
      overlay={<Tooltip id={`${tooltipId}-tooltip`}>{tooltip}</Tooltip>}
    >
      {icon}
    </OverlayTrigger>
  )
}

function SubdetailCollapseIcon({ open }) {
  return (
    <i className={`fa fa-${open ? 'minus-circle' : 'plus-circle'} table-subdetail-icon`} />
  )
}

// indication: <string> with length of 4
//   each character is either '0' or '1'
//   where '0' stands for this position needs to be empty
function mask(indication, resources) {
  const result = (resources || []).slice()
  for (let i = 0; i < 4; i++) {
    if (indication[i] == '0') {
      result[i] = ''
    }
  }
  return result
}

export const DataRowDetail = connect(
  (state) => ({
    $ships: state.const.$ships,
    displayFleetInShips: sortieFleetDisplayModeSelector(state) == 'ship',
  })
)(class DataRowDetail extends Component {
  constructor(props) {
    super(props)
    this.state = {
      subopen: {
      },
    }
  }

  shipName = (shipId) => {
    const shipNameRaw = get(this.props.$ships, [shipId, 'api_name'])
    if (!shipNameRaw) {
      return __('Ship #%d', { id: shipId })
    }
    return window.i18n.resources.__(shipNameRaw)
  }

  render() {
    const { recordData, record, open: mainOpen, displayFleetInShips } = this.props
    if (!recordData || !record) {
      return null
    }
    const { fleet: fleetData, supports: supportsData, airbase: airbaseData } = recordData
    const { fleet, fleet1Size=-1, supports } = record

    const detailData = []
    if (fleetData) {          // Don't check sum(fleetData.sum)
      const fleetDetail = {
        key: "fleet",
        sum: [__('Sortie fleet')].concat(fleetData.sum).concat([fleetData.bucketNum || '']),
      }
      if (displayFleetInShips) {
        fleetDetail.details = zip(fleetData.ships, fleet).map(([resources, { shipId, bucket }], i) => {
          const flagshipIcon = (i == 0 || i == fleet1Size) ? <LeadingIcon className="fa fa-flag" /> : null
          const shipName = this.shipName(shipId)
          const bucketIcon = bucket ? <i className="fa fa-check" /> : ''
          return [
            <div key={1}>{flagshipIcon}{shipName}</div>,
          ].concat(resources).concat([bucketIcon])
        })
      } else {
        const detailEntries = [
          [__('Resupply'), fleetData.resupply, '1101', ''],
          [__('Repair'), fleetData.repair, '0110', fleetData.bucketNum],
          [__('Jet assault'), fleetData.jetAssault, '0010', ''],
        ]
        fleetDetail.details = detailEntries.filter((entry, i) => sum(entry[1]) || i == 0)
          .map(([title, resources, thisMask, bucket]) => [
            title,
          ].concat(mask(thisMask, resources)).concat([bucket]))
      }
      detailData.push(fleetDetail)
    }

    if (supportsData && sum(supportsData.sum)) {
      const supportsDetail = {
        key: "supports",
        sum: [__('Support fleet')].concat(supportsData.sum).concat(['']),
      }
      supportsDetail.details = supports.map(({ shipId, consumption }, i) => {
        const fleetIcon = (
          <LeadingIcon
            className="fa fa-ship"
            tooltip={
              <span style={{ wordBreak: 'keep-all' }}>
                {join(shipId.map(this.shipName), __(', '))}
              </span>
            }
            tooltipId={`${record.time}-supports-${i}`}
          />
        )
        return [
          <div key={1}>{fleetIcon}{__('Fleet #%d', i+1)}</div>,
        ].concat(mask('1100', consumption)).concat([''])
      })
      detailData.push(supportsDetail)
    }

    if (airbaseData && sum(airbaseData.sum)) {
      const recordAirbase = record.airbase
      const airbaseDetail = {
        key: "airbase",
        sum: [__('Airbase')].concat(airbaseData.sum).concat(['']),
        details: [],
      }
      const detailEntries = [
        [recordAirbase.sortie, __('Sortie squadrons'), '1100'],
        [recordAirbase.destruction, __('Land base destruction'), '1001'],
        [recordAirbase.jetAssault, __('Jet assault'), '0010'],
        [recordAirbase.resupply, __('Flight resupply'), '1001'],
      ]
      detailEntries.forEach(([resources, title, thisMask]) => {
        if (resources && sum(resources)) {
          airbaseDetail.details.push([
            title,
          ].concat(mask(thisMask, resources)).concat(['']))
        }
      })
      detailData.push(airbaseDetail)
    }

    return (
      <Collapse in={mainOpen} className="detail-collapse">
        <div>
          {detailData.map(({ key, sum, details }) => {
            const hasDetails = !!details
            const open = this.state.subopen[key]
            const collapseIcon = hasDetails ? <SubdetailCollapseIcon open={open}/> : ''
            const sumRow = (
              <RowBase
                key={`${key}-sum`}
                className="subdetail-sum-row"
                leftMergeCols={4}
                bordered={false}
                contents={[
                  <div key={0}>{collapseIcon}{sum[0]}</div>,
                ].concat(sum.slice(1))}
                onClick={() => this.setState({
                  subopen: {
                    ...this.state.subopen,
                    [key]: !open,
                  },
                })}
              >
              </RowBase>
            )
            const detailRows = hasDetails ? (
              <Collapse in={open} key={`${key}-details`}>
                <div>
                  {details.map((contents, i) =>
                    <RowBase
                      bordered={false}
                      key={`${key}-sum-${i}`}
                      className="subdetail-detail-row"
                      leftMergeCols={4}
                      contents={contents}
                    />
                  )}
                </div>
              </Collapse>
            ) : null
            return [
              sumRow,
              detailRows,
            ]
          })}
        </div>
      </Collapse>
    )
  }
})
