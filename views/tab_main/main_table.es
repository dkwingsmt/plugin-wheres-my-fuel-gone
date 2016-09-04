import React, { Component } from 'react'
import { Row, Col, Button, Table, OverlayTrigger, Tooltip } from 'react-bootstrap'
import path from 'path-extra'
import classNames from 'classnames'
import { range, sum } from 'lodash'

import { MaterialIcon as RawMaterialIcon } from 'views/components/etc/icon'

const colWidths = [45, 140, 180, 80, 50, 50, 50, 50, 30]

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
  const data = resource5to4(sumData.slice(0, 5)).concat(buckets)
  return (
    <tr className='info'>
      <td>*</td>
      <td colSpan={3}><em>{__('Sum of %s sorties', props.sortieTimes)}</em></td>
      {
        data.map((n) =>
          <td>{n}</td>
        )
      }
    </tr>
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

    const data = [this.props.id, timeText, mapText, mapHp].concat(total4).concat([buckets])

    return (
      <tr onClick={this.onToggle}>
        <td>{[
          <CollapseIcon key='rowClosingIcon'
            open={this.props.rowExpanded} closeAngle={90} openAngle={180}
            style={{marginRight: '4px'}} />,
          data[0],
        ]}
        </td>
        {
          range(1, data.length).map((i) =>
            <td key={i}>{data[i]}</td>
          )
        }
      </tr>
    )
  }
}

class CollapsibleRow extends Component {
  constructor(props) {
    super(props)
    this.state = {
      realHeight: null,
      height: 0,
      hidden: false,
    }
  }

  componentDidMount() {
    // Init render: Force showing, get height, and switch to normal mode
    if (this.state.realHeight == null) {
      const realHeight = this.refs.wrapper.offsetHeight
      this.setState({
        realHeight: realHeight,
        hidden: !this.props.rowExpanded,
        height: this.props.rowExpanded ? realHeight : 0,
      })
    }
  }

  componentWillReceiveProps(nextProps) {
    if (nextProps.rowExpanded == null)
      return
    if (!this.props.rowExpanded && nextProps.rowExpanded) {
      this.setState({
        hidden: false,
      })
      // A height change started at "display: none" will not trigger transition
      // Therefore we change height after a 1ms timeout of removing display-none
      setTimeout(() => this.setState({height: this.state.realHeight}), 1)
    }
    if (this.props.rowExpanded && !nextProps.rowExpanded) {
      this.setState({
        height: 0,
      })
      // Allow an extra 100ms timeout before hiding 
      // Check rowExpanded again in case another click happens before it 
      setTimeout(() => !this.props.rowExpanded && this.setState({hidden: true}), 350+100)
    }
  }

  render() {
    const trClasses = classNames({
      hidden: this.state.hidden,
    })

    const wrapperStyle = this.state.realHeight == null ?  {} : {height: this.state.height}

    return (
      <tr className={trClasses} style={{backgroundColor: 'inherit'}}>
        <td colSpan={colWidths.length} style={{padding: 0, border: 0}}>
          <div className='collapsible-wrapper' style={wrapperStyle} ref='wrapper'>
            <div style={{padding: 0}} >
              {this.props.children}
            </div>
          </div>
        </td>
      </tr>
    )
  }
}

function DetailRow(props) {
  const widths = [sum(colWidths.slice(0, 4))].concat(colWidths.slice(4))
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

  const deleteSteel = (array) => {array[2] = undefined; return array}

  // Support
  if (record.supports)
    data.push(
      [__('Support')]
      .concat(deleteSteel(sumArray(record.supports.map((s) => s.consumption))))
      .concat('')
    )

  return (
    <CollapsibleRow rowExpanded={props.rowExpanded}>
      <Table condensed
        style={{tableLayout: 'fixed', margin: 0}}>
        <tbody>
        {
          data.map((row, rowNo) =>
            <tr key={rowNo}>
            {
              row.map((col, colNo) => {
                const style = {width: widths[colNo], padding: 0, color: '#ccc'}
                if (colNo === 0)
                  style.textAlign = 'right'
                else
                  style.backgroundColor = '#333'
                return (
                  <td key={colNo} style={style} className='extra-col'>
                    <div style={{padding: 5}}>
                      {col}
                    </div>
                  </td>
                )
              })
            }
            </tr>
          )
        }
        </tbody>
      </Table>
    </CollapsibleRow>
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

    const headerData = ['#', __('Time'), __('World'), __('World health'),
      <MaterialIcon materialId={1} key='icon21'/>, 
      <MaterialIcon materialId={2} key='icon22'/>, 
      <MaterialIcon materialId={3} key='icon23'/>,
      <MaterialIcon materialId={4} key='icon24'/>,
      <MaterialIcon materialId={6} key='icon25'/>,
    ]

    return (
      <Table bordered condensed hover id='main-table'>
        <thead>
          <tr>
          {
            range(0, colWidths.length).map((i) =>
              <th key={i} style={{width: colWidths[i]}}>{headerData[i]}</th>
            )
          }
          </tr>
        </thead>
        <tbody>
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
        </tbody>
      </Table>
    )
  }
}
