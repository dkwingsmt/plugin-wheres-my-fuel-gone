import React, { Component } from 'react'
import {zip} from 'lodash'
import classNames from 'classnames'

const baseColWidths = [65, 150, 0, 80, 55, 55, 55, 55, 30]

export class RowBase extends Component {

  static defaultProps = {
    bordered: true,
  }

  mergedColWidths = () => {
    const {leftMergeCols} = this.props
    if (!leftMergeCols || leftMergeCols == 1) {
      return baseColWidths
    }
    let firstColWidth = 0
    for (let i = 0; i < leftMergeCols-1; i++) {
      if (baseColWidths[i] == 0) {
        firstColWidth = 0
        break
      }
      firstColWidth += baseColWidths[i]
    }
    return [firstColWidth].concat(baseColWidths.slice(leftMergeCols))
  }

  render() {
    const {contents, className, cellClassName, onClick, leftMergeCols, bordered} = this.props
    const colWidths = this.mergedColWidths()
    return (
      <div className={classNames('table-row', {
        'row-bordered': bordered,
      },className)} onClick={onClick}>
        {zip(contents, colWidths).map(([content, width], i) => {
          const style = width ? {width} : {flex: 1}
          return (
            <div
              key={i}
              className={classNames('table-cell', {
                'table-cell-merged-first': leftMergeCols && i == 0,
              }, cellClassName)}
              style={style}
            >
              {content}
            </div>
          )
        })}
      </div>
    )
  }
}
