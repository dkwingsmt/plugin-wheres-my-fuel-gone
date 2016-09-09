import React, { Component } from 'react'
import { Button, Table, OverlayTrigger, Tooltip } from 'react-bootstrap'
import path from 'path-extra'
import classNames from 'classnames'
import { zip, range, sum } from 'lodash'
import Collapse from 'react-collapse'

import { MaterialIcon as RawMaterialIcon } from 'views/components/etc/icon'

const colWidths = [65, 150, 0, 80, 55, 55, 55, 55, 30]

function CollapseIcon(props) {
  // North=angle 0, East=angle 90, South=angle 180, West=angle 270
  const angle = props.open ? props.openAngle : props.closeAngle
  const rotateClass = angle == 0 ? '' : `fa-rotate-${angle}`
  return (
    <i className={`fa fa-chevron-circle-up ${rotateClass} collapse-icon`} style={props.style}></i>
  )
}

function SumRow(props) {
  const sumData = props.sumData
  const buckets = sumData[5]
  const data = ['*', <em>{__('Sum of %s sorties', props.sortieTimes)}</em>].concat(
    resource5to4(sumData.slice(0, 5)).concat(buckets))
  const widths = [colWidths[0], 0].concat(colWidths.slice(4))
  return (
    <Row widths={widths} flexCol={1} data={data} className='info table-row' />
  )
    //<tr className='info'>
    //  <td>*</td>
    //  <td colSpan={3}><em>{__('Sum of %s sorties', props.sortieTimes)}</em></td>
    //  {
    //    data.map((n) =>
    //      <td>{n}</td>
    //    )
    //  }
    //</tr>
}

function Row(props) {
  // Meant to use const {data, widths, ...rowProps} = props but babel doesnt work
  const rowProps = props
  const {data, widths, flexCol, cellClassName='table-cell table-cell-hover'} = props
  const cellClassNameFunc = typeof cellClassName === 'string' ?
    () => cellClassName
    : cellClassName
  return (
    <div className='table-row' {...rowProps}>
    {
      zip(data, widths).map(([d, w], idx) => {
        const style = {}
        if (idx == flexCol)
          style.flex = 1
        else if (w > 0)
          style.width = `${w}px`
        return (
          <div key={idx} className={cellClassNameFunc(idx)} style={style}>
            {d}
          </div>
        )
      })
    }
    </div>
  )
}

class DataRow extends Component {
  fleetSortieConsumption = (fleet) => {
    // return [fuel, ammo, steel, bauxite]
    // See format of TempRecord#generateResult
    return sumArray(fleet.map((ship) => ship.consumption))
  }

  onToggle = () => {
    this.props.setRowExpanded(!this.props.rowExpanded)
  }

  render() {
    const record = this.props.record
    // Date
    const timeText = new Date(record.time).toLocaleString(window.language, {
      hour12: false,
    })

    // Map text
    let mapText = `${record.map.name}(${record.map.id})`
    if (record.map.rank != null)
      mapText += ['', __('Easy'), __('Medium'), __('Hard')][record.map.rank]

    const mapHp = record.map.hp ? `${record.map.hp[0]}/${record.map.hp[1]}` : ''

    // Fleet
    const totalSupport = sumArray((record.supports || []).map((support) => support.consumption))
    const total4 = sumArray([resource5to4(this.fleetSortieConsumption(record.fleet)), totalSupport])

    const buckets = record.fleet.filter((s) => s.bucket).length || ''

    const data = [[
      <CollapseIcon key='rowClosingIcon'
        open={this.props.rowExpanded} closeAngle={90} openAngle={180}
        style={{marginRight: '4px'}} />,
      this.props.id,
    ], timeText, mapText, mapHp].concat(total4).concat([buckets])

    return (
      <Row data={data} widths={colWidths} flexCol={2} onClick={this.onToggle} />
    )
  }
}

function DetailRow(props) {
  const record = props.record

  //const flagshipIcon = <i className='fa fa-flag inline-icon'></i>

  const data = []

  const fleetResources = sumArray(record.fleet.map((ship) => ship.consumption))

  // Supply
  const supplyResources = resource5toSupply(fleetResources)
  data.push([__('Resupply')].concat(supplyResources).concat(''))

  // Repair
  const repairResources = resource5toRepair(fleetResources)
  const buckets = record.fleet.filter((s) => s.bucket).length
  if (sum(repairResources) + buckets)
    data.push([__('Repair')].concat(repairResources).concat(buckets))

  const deleteSteel = (array) => {array[2] = 0; return array}

  // Support
  if (record.supports)
    data.push(
      [__('Support')]
      .concat(deleteSteel(sumArray(record.supports.map((s) => s.consumption))))
      .concat('')
    )

  const widths = [0].concat(colWidths.slice(4))

  return (
    <Collapse isOpened={props.rowExpanded}>
    {
      data.map((rowData) => {
        const cellClassName = 'table-cell-detail'
        return (
          <Row data={rowData}
            cellClassName={cellClassName}
            widths={widths}
            flexCol={0}
            />
        )
      })
    }
    </Collapse>
  )
}


function MaterialIcon(props) {
  const icon = (
    <div className='icon-wrapper'>
      <RawMaterialIcon materialId={props.materialId} />
      <span className='fa-stack footnote-icon' style={props.icon != null ? {} : {visibility: 'hidden'}}>
        <i className='fa fa-circle fa-stack-2x footnote-icon-bg'
           style={props.color != null ? {color: props.color} : {}} ></i>
        <i className={`fa fa-${props.icon || 'circle'} fa-stack-1x fa-inverse footnote-icon-core`}></i>
      </span>
    </div>
  )

  return props.tooltip == null ?
    icon
  : (
    <OverlayTrigger placement='bottom'
      overlay={<Tooltip id={`${props.id}-tooltip`}>{props.tooltip}</Tooltip>} >
      {icon}
    </OverlayTrigger>
  )
}

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
    const {data, startNo} = this.props

    const headerData = ['#', __('Time'), __('World'), __('World health')].map((text) =>
      <div className='vertical-mid'>{text}</div>
    ).concat([
      <MaterialIcon materialId={1} key='icon21'/>, 
      <MaterialIcon materialId={2} key='icon22'/>, 
      <MaterialIcon materialId={3} key='icon23'/>,
      <MaterialIcon materialId={4} key='icon24'/>,
      <MaterialIcon materialId={6} key='icon25'/>,
    ])

    return (
      <div id='main-table'>
        <Row widths={colWidths} flexCol={2} data={headerData} />
        {
          !!this.props.sumData &&
            <SumRow sumData={this.props.sumData} sortieTimes={this.props.sortieTimes} />
        }
        {
          data.map((record, i) => {
            const rowExpanded = this.state.rowsExpanded[record.time] || false
            const displayId = startNo + i + 1
            return [
              <DataRow 
                key={`data-${record.time}-${i}`}
                record={record}
                rowExpanded={rowExpanded}
                setRowExpanded={this.handleSetRowExpanded.bind(this, record.time)}
                id={displayId} />,
              <DetailRow 
                key={`info-${record.time}-${i}`}
                record={record}
                rowExpanded={rowExpanded}
                />,
            ]
          })
        }
      </div>
    )
  }
}
