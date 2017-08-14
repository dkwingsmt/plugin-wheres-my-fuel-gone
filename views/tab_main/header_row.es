/* global __ */

import React, { Component } from 'react'

import { MaterialIcon as RawMaterialIcon } from 'views/components/etc/icon'
import { RowBase } from './row_base'

function MaterialIcon(props) {
  return (
    <div className='icon-wrapper'>
      <RawMaterialIcon materialId={props.materialId} />
    </div>
  )
}

export class HeaderRow extends Component {
  render() {
    const headerData = ['#', __('Time'), __('World'), __('World health')].map((text, i) =>
      <div className='vertical-mid' key={i}>{text}</div>
    ).concat([
      <MaterialIcon materialId={1} key='icon21'/>,
      <MaterialIcon materialId={2} key='icon22'/>,
      <MaterialIcon materialId={3} key='icon23'/>,
      <MaterialIcon materialId={4} key='icon24'/>,
      <MaterialIcon materialId={6} key='icon25'/>,
    ])
    return (
      <RowBase
        className="table-row-display"
        contents={headerData}
      />
    )
  }
}
