/* global __ */

import moment from 'moment'

function timeStr(time) {
  return moment(time).format('YYYY-M-D HH:mm')
}

function doCutOff(time, fnName, cutoff) {
  if (time != null) {
    if (cutoff != null) {
      return typeof time[fnName] === "function" ? time[fnName](cutoff) : undefined
    } else if (fnName) {
      return time
    }
  }
}

function momentAdd(momentTime, time) {
  if (momentTime == null) {
    return undefined
  }
  return momentTime.add(time)
}

function parseTimeMenu(path, value) {
  const config = (() => {
    switch (path[path.length - 1]) {
    case '_this_daily':
      return {
        after: 'startOf',
        cutoff: 'day',
        offset: moment.duration(5, 'hours'),
        local: true,
      }
    case '_this_weekly':
      return {
        after: 'startOf',
        cutoff: 'isoWeek',
        offset: moment.duration(5, 'hours'),
        local: true,
      }
    case '_this_monthly':
      return {
        after: 'startOf',
        cutoff: 'month',
        offset: moment.duration(5, 'hours'),
      }
    case '_this_eo':
      return {
        after: 'startOf',
        cutoff: 'month',
      }
    case '_daily':
      return {
        after: 'startOf',
        before: 'endOf',
        cutoff: 'day',
        offset: moment.duration(5, 'hours'),
      }
    case '_weekly':
      return {
        after: 'startOf',
        before: 'endOf',
        cutoff: 'isoWeek',
        offset: moment.duration(5, 'hours'),
      }
    case '_monthly':
      return {
        after: 'startOf',
        before: 'endOf',
        cutoff: 'month',
        offset: moment.duration(5, 'hours'),
      }
    case '_eo':
      return {
        after: 'startOf',
        before: 'endOf',
        cutoff: 'month',
      }
    case '_before':
      return {
        before: true,
        local: true,
      }
    case '_after':
      return {
        after: true,
        local: true,
      }
    default:
      return {
        error: __('Invalid time filter category %s', path[path.length - 1]),
      }
    }
  })()
  if (config.error != null) {
    return {
      error: config.error,
    }
  }

  const offset = config.offset || 0
  const japanOffset = moment.duration(9, 'hours')
  const myOffset = moment().utcOffset() * moment.duration(1, 'minutes')
  const nowFunc = config.local ? moment : moment.utc
  let now
  let preOffset
  let postOffset
  if (value === 'now') {
    now = nowFunc()
    preOffset = japanOffset - offset - myOffset
    postOffset = -japanOffset + offset
  } else {
    now = nowFunc(value, 'YYYY-MM-DD HH:mm:ss')
    if (!now.isValid()) {
      return {
        error: __('%s is not a valid time', value),
      }
    }
    preOffset = 0
    postOffset = offset
    if (config.cutoff != null) {
      postOffset -= japanOffset
    }
  }
  now = now.add(preOffset).utc()
  const beforeTime = momentAdd(doCutOff(now.clone(), config.before, config.cutoff), postOffset)
  const afterTime = momentAdd(doCutOff(now.clone(), config.after, config.cutoff), postOffset)
  const result = {}
  if (beforeTime != null) {
    result.before = +beforeTime
  }
  if (afterTime != null) {
    result.after = +afterTime
  }
  return result
}
// ** Unit tests for parseTimeMenu
// _check = (a, b, local=false) ->
//   func = if local then 'local' else 'utc'
//   toMoment = (t) -> if t? then moment(t) else undefined
//   toMoment(a.after)?[func]().format() == b.after && toMoment(a.before)?[func]().format() == b.before
// ** The following tests should yield true
// console.log _check parseTimeMenu(['_weekly'], '2016/1/17'),
//   before: '2016-01-17T19:59:59+00:00'
//   after: '2016-01-10T20:00:00+00:00'
// console.log _check parseTimeMenu(['_this_eo'], 'now'),
//   after: '2015-12-31T15:00:00+00:00'
// ** The following tests are based on current time so can't yield true,
// ** You should manually check if parseTimeMenu gives reasonable results
// console.log _check parseTimeMenu(['_this_daily'], 'now'),
//   after: '2016-01-17T20:00:00+00:00'
// console.log _check parseTimeMenu(['_this_weekly'], 'now'),
//   after: '2016-01-17T20:00:00+00:00'
// console.log _check parseTimeMenu(['_this_monthly'], 'now'),
//   after: '2015-12-31T20:00:00+00:00'
// ** The following tests should vary only on time zone (-06:00 -> +08:00 or etc)
// console.log _check parseTimeMenu(['_after'], '2016/1/17 23:59:59'),
//   after: '2016-01-17T23:59:59-06:00'
//   true
// console.log _check parseTimeMenu(['_before'], '2016/1/17'),
//   before: '2016-01-17T00:00:00-06:00'
//   true

export default {
  title: __('Time'),
  func: (path, value, record) => {
    let result
    result = true
    if (value.before != null) {
      result = result && record.time <= value.before
    }
    if (value.after != null) {
      result = result && record.time >= value.after
    }
    return result
  },
  testError: (path, value) => value.error,
  porting: (path, value) => {
    let ref, ref1
    if (value.textOptions != null) {
      if ((ref = path[path.length - 1]) === '_after' || ref === '_before') {
        return {
          path: path,
          value: moment(value.after || value.before).format('YYYY-MM-DD HH:mm:ss'),
        }
      } else if ((ref1 = path[path.length - 1]) === '_daily' || ref1 === '_weekly' || ref1 === '_monthly' || ref1 === '_eo') {
        return {
          path: path,
          value: moment(value.after).format('YYYY-MM-DD'),
        }
      } else {
        return {
          path: path,
          value: 'now',
        }
      }
    }
    return {
      path: path,
      value: value,
    }
  },
  postprocess: parseTimeMenu,
  textFunc: (path, value) => {
    const pathSplit = path[path.length - 1].split('_').reverse()
    const cycle = __((() => {
      switch (pathSplit[0]) {
      case 'daily':
        return 'daily quest'
      case 'weekly':
        return 'weekly quest'
      case 'monthly':
        return 'monthly quest'
      case 'eo':
        return 'Extra Operation'
      }
    })())
    const current = __(pathSplit[1] === 'this' ? 'current ' : '')
    const beforeTime = value.before ? timeStr(value.before) : __('now')
    const beforeText = __(' to %s', beforeTime)
    const afterText = value.after ? __(' from %s', timeStr(value.after)) : ''
    return __('During the %(current)s%(cycle)s cycle%(afterText)s%(beforeText)s', {
      current: current,
      cycle: cycle,
      afterText: afterText,
      beforeText: beforeText,
    })
  },
  sub: {
    '_this_daily': {
      title: __('During today\'s daily quest cycle'),
      value: 'now',
    },
    '_this_weekly': {
      title: __('During the current weekly quest cycle'),
      value: 'now',
    },
    '_this_monthly': {
      title: __('During the current monthly quest cycle'),
      value: 'now',
    },
    '_this_eo': {
      title: __('During the current monthly Extra Operation cycle'),
      value: 'now',
    },
    '_daily': {
      title: __('During a specified daily quest cycle'),
      options: {
        placeholder: __('Enter the date (Japan local time) as yyyy-mm-dd (e.g. 2016-01-31)'),
      },
    },
    '_weekly': {
      title: __('During a specified weekly quest cycle'),
      options: {
        placeholder: __('Enter any date during that week (Japan local time) as yyyy-mm-dd (e.g. 2016-01-31)'),
      },
    },
    '_monthly': {
      title: __('During a specified monthly quest cycle'),
      options: {
        placeholder: __('Enter the month as yyyy-mm (e.g. 2016-01)'),
      },
    },
    '_eo': {
      title: __('During a specified monthly Extra Operation cycle'),
      options: {
        placeholder: __('Enter the month as yyyy-mm (e.g. 2016-01)'),
      },
    },
    '_before': {
      title: __('Before a specified time'),
      options: {
        placeholder: __('Enter your local time as yyyy-mm-dd hh:mm:ss. Latter parts can be omitted.'),
      },
      textFunc: function(path, value) {
        return __('Before %s', timeStr(value.before))
      },
    },
    '_after': {
      title: __('After a specified time'),
      options: {
        placeholder: __('Enter your local time as yyyy-mm-dd hh:mm:ss. Latter parts can be omitted.'),
      },
      textFunc: function(path, value) {
        return __('After %s', timeStr(value.after))
      },
    },
  },
}
