module.exports = 
  title: __('World')
  sub:
    '_id':
      title: __('World number')
      func: (path, value, record) ->
        record.map?.id == value
      textFunc: (path, value) ->
        __('In world %s', value)
      options:
        placeholder: __('Enter the map number here (e.g. 2-3, 32-5)')
    '_idregex':
      title: __('World number (fuzzy matching)')
      postprocess: (path, value) ->
        if value.startsWith('/')
          # "/BODY/FLAG"
          [_empty, body, flags] = value.split '/'
          flags = flags || ''
        else
          # Only BODY
          body = value
          flags = ''
        {body, flags, regex: RegExp(body, flags)}
      func: (path, {body, flags, regex}, record) ->
        regex.test(record.map?.id)
      textFunc: (path, {body, flags}) ->
        value = "/#{body}/#{flags}"
        __('In worlds %s', value)
      options:
        placeholder: __('Enter the map number regex here (e.g. ^34- for world 34, ^(33|34)- for 33 or 34)')
    '_rank':
      title: __('World difficulty')
      func: (path, value, record) ->
        if value == 0
          !record.map?.rank?
        else
          record.map?.rank?.toString() == value.toString()
      textFunc: (path, value) ->
        __('In %s difficulty', __(['', 'Easy', 'Medium', 'Hard'][value]))
      sub: 
        '_ez': 
          title: __('Easy')
          value: 1
        '_md':
          title: __('Medium')
          value: 2
        '_hd':
          title: __('Hard')
          value: 3
    '_hp':
      title: __('World clearance')
      func: (path, value, record) ->
        (record.map?.hp?[0] > 0) == value
      textFunc: (path, value) ->
        if value
          __('In a world not yet cleared')
        else
          __('In a cleared world')
      sub: 
        '_2':
          title: __('The map has not been cleared')
          value: true
        '_1': 
          title: __('The world has been cleared')
          value: false
