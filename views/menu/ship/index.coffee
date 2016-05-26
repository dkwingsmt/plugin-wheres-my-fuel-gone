module.exports = 
  title: __('Ship')
  sub:
    '_name':
      title: __('By ship name')
      postprocess: (path, value) ->
        text: value
        regex: new RegExp(value)
      func: (path, value, record) ->
        record.fleet.filter(
          (sh) -> value.regex.test $ships[sh.shipId]?.api_name)
        .length != 0
      textFunc: (path, value) ->
        __('With ship %s', value.text)
      options:
        placeholder: __('Enter the ship name here. (Javascript regex is supported.)')
    '_id':
      title: __('By ship id')
      testError: (path, value) ->
        if !_ships?[value]?
          __('You have no ship with id %s', value)
      func: (path, value, record) ->
        record.fleet.filter(
          (sh) -> sh.id?.toString() == value.toString())
        .length != 0
      textFunc: (path, value) ->
        name = _ships[value].api_name
        __('With ship %s (#%s)', name, value)
      options:
        placeholder: __('Enter the ship id here. You can find it in Ship Girls Info at the first column.')
