moment = require '../../../external/moment.min.js'
  
timeStr = (time) ->
  moment(time).format('YYYY-M-D HH:mm')

# This function is written totally based on unit test. See comments after it.
parseTimeMenu = (path, value) ->
  config = switch(path[path.length-1])
    when '_this_daily'
      after: 'startOf'
      cutoff: 'day'
      offset: moment.duration(5, 'hours')
      local: true
    when '_this_weekly'
      after: 'startOf'
      cutoff: 'isoWeek'
      offset: moment.duration(5, 'hours')
      local: true
    when '_this_monthly'
      after: 'startOf'
      cutoff: 'month'
      offset: moment.duration(5, 'hours')
    when '_this_eo'
      after: 'startOf'
      cutoff: 'month'
    when '_daily'
      after: 'startOf'
      before: 'endOf'
      cutoff: 'day'
      offset: moment.duration(5, 'hours')
    when '_weekly'
      after: 'startOf'
      before: 'endOf'
      cutoff: 'isoWeek'
      offset: moment.duration(5, 'hours')
    when '_monthly'
      after: 'startOf'
      before: 'endOf'
      cutoff: 'month'
      offset: moment.duration(5, 'hours')
    when '_eo'
      after: 'startOf'
      before: 'endOf'
      cutoff: 'month'
    when '_before'
      before: true
      local: true
    when '_after'
      after: true
      local: true
    else
      error: __('Invalid time filter category %s', path[path.length-1])
  if config.error?
    return {error: config.error}

  doCutOff = (time, fnName, cutoff) ->
    if time?
      if cutoff?
        time[fnName]?(cutoff)
      else if fnName
        time

  offset = config.offset || 0
  japanOffset = moment.duration(9, 'hours')
  myOffset = moment().utcOffset()*moment.duration(1, 'minutes')
  nowFunc = if config.local then moment else moment.utc
  if value == 'now'
    now = nowFunc()
    preOffset = japanOffset - offset - myOffset
    postOffset = -japanOffset + offset
  else
    now = nowFunc(value, 'YYYY-MM-DD HH:mm:ss')
    if !now.isValid()
      return {error: __('%s is not a valid time', value)}
    preOffset = 0
    postOffset = offset
    if config.cutoff?
      postOffset -= japanOffset
  now = now.add(preOffset).utc()
  beforeTime = doCutOff(now.clone(), config.before, config.cutoff)?.add(postOffset)
  afterTime = doCutOff(now.clone(), config.after, config.cutoff)?.add(postOffset)

  result = {}
  result.before = +beforeTime if beforeTime?
  result.after = +afterTime if afterTime?
  result
#** Unit tests for parseTimeMenu
#_check = (a, b, local=false) ->
#  func = if local then 'local' else 'utc'
#  toMoment = (t) -> if t? then moment(t) else undefined
#  toMoment(a.after)?[func]().format() == b.after && toMoment(a.before)?[func]().format() == b.before
#** The following tests should yield true
#console.log _check parseTimeMenu(['_weekly'], '2016/1/17'),
#  before: '2016-01-17T19:59:59+00:00'
#  after: '2016-01-10T20:00:00+00:00'
#console.log _check parseTimeMenu(['_this_eo'], 'now'),
#  after: '2015-12-31T15:00:00+00:00'
#** The following tests are based on current time so can't yield true, 
#** You should manually check if parseTimeMenu gives reasonable results   
#console.log _check parseTimeMenu(['_this_daily'], 'now'),
#  after: '2016-01-17T20:00:00+00:00'
#console.log _check parseTimeMenu(['_this_weekly'], 'now'),
#  after: '2016-01-17T20:00:00+00:00'
#console.log _check parseTimeMenu(['_this_monthly'], 'now'),
#  after: '2015-12-31T20:00:00+00:00'
#** The following tests should vary only on time zone (-06:00 -> +08:00 or etc)
#console.log _check parseTimeMenu(['_after'], '2016/1/17 23:59:59'),
#  after: '2016-01-17T23:59:59-06:00'
#  true
#console.log _check parseTimeMenu(['_before'], '2016/1/17'),
#  before: '2016-01-17T00:00:00-06:00'
#  true

module.exports = 
  title: __('Time')
  func: (path, value, record) ->
    result = true
    if value.before?
      result = result && record.time <= value.before
    if value.after?
      result = result && record.time >= value.after
    result
  testError: (path, value) ->
    value.error
  porting: (path, value) ->
    # Format until 0.2.1 
    if value.textOptions?
      return if path[path.length-1] in ['_after', '_before']
        path: path
        # Use full format here to preserve information
        value: moment(value.after || value.before).format('YYYY-MM-DD HH:mm:ss')
      else if path[path.length-1] in ['_daily', '_weekly', '_monthly', '_eo']
        # Use full format here to preserve information
        {path: path, value: moment(value.after).format('YYYY-MM-DD')}
      else     # '_this_xxx'
        {path: path, value: 'now'}
    {path, value}
  postprocess: parseTimeMenu
  textFunc: (path, value) ->
    # '_before' and '_after' have their own textFunc overridden
    pathSplit = path[path.length-1].split('_').reverse()
    cycle = __ switch pathSplit[0]
      when 'daily'
        'daily quest'
      when 'weekly'
        'weekly quest'
      when 'monthly'
        'monthly quest'
      when 'eo'
        'Extra Operation'
    current = __ if pathSplit[1] == 'this' then 'current ' else ''
    beforeTime = if value.before then timeStr(value.before) else __ 'now'
    beforeText = __ ' to %s', beforeTime
    if value.after
      afterText = __ ' from %s', timeStr(value.after)
    else
      afterText = ''
    __('During the %(current)s%(cycle)s cycle%(afterText)s%(beforeText)s',
      {current, cycle, afterText, beforeText})
  sub:
    '_this_daily':
      title: __('During today\'s daily quest cycle')
      value: 'now'
    '_this_weekly':
      title: __('During the current weekly quest cycle')
      value: 'now'
    '_this_monthly':
      title: __('During the current monthly quest cycle')
      value: 'now'
    '_this_eo':
      title: __('During the current monthly Extra Operation cycle')
      value: 'now'
    '_daily':
      title: __('During a specified daily quest cycle')
      options:
        placeholder: __('Enter the date (Japan local time) as yyyy-mm-dd (e.g. 2016-01-31)')
    '_weekly':
      title: __('During a specified weekly quest cycle')
      options:
        placeholder: __('Enter any date during that week (Japan local time) as yyyy-mm-dd (e.g. 2016-01-31)')
    '_monthly':
      title: __('During a specified monthly quest cycle')
      options:
        placeholder: __('Enter the month as yyyy-mm (e.g. 2016-01)')
    '_eo':
      title: __('During a specified monthly Extra Operation cycle')
      options:
        placeholder: __('Enter the month as yyyy-mm (e.g. 2016-01)')
    '_before':
      title: __('Before a specified time')
      options:
        placeholder: __('Enter your local time as yyyy-mm-dd hh:mm:ss. Latter parts can be omitted.')
      textFunc: (path, value) ->
        __ 'Before %s', timeStr(value.before)
    '_after':
      title: __('After a specified time')
      options:
        placeholder: __('Enter your local time as yyyy-mm-dd hh:mm:ss. Latter parts can be omitted.')
      textFunc: (path, value) ->
        __ 'After %s', timeStr(value.after)
