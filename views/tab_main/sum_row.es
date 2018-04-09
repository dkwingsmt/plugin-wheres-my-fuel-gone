import React, { Component } from 'react'
import PropTypes from 'prop-types'

import { arraySum } from 'views/utils/tools'
import { RowBase } from './row_base'

const { __ } = window.i18n["poi-plugin-wheres-my-fuel-gone"]

export class SumRow extends Component {
  static contextTypes = {
    recordCalculator: PropTypes.func.isRequired,
  }

  render() {
    const { data } = this.props
    const { recordCalculator } = this.context

    const sum = arraySum(data.map(record => {
      const recordData = recordCalculator(record)
      return recordData.sum.concat([recordData.bucketNum])
    }))
    const contents = [<em key="text">{__('Sum of %s sorties', data.length)}</em>]
      .concat(sum)

    return (
      <RowBase leftMergeCols={4} contents={contents} className='table-sum-row bg-info' />
    )
  }
}
