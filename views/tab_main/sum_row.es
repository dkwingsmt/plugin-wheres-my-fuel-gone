/* global __ */

import React, { Component } from 'react'

import { MaterialIcon } from 'views/components/etc/icon'
import { RowBase } from './row_base'

export class SumRow extends Component {
  render() {
    return (
      <RowBase
        contents={headerData}
      />
    )
  }
}
