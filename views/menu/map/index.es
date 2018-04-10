import { get } from 'lodash'

const { __ } = window.i18n["poi-plugin-wheres-my-fuel-gone"]

export default {
  title: __('World'),
  sub: {
    '_id': {
      title: __('World number'),
      func: function(path, value, record) {
        let ref
        return ((ref = record.map) != null ? ref.id : void 0) === value
      },
      textFunc: function(path, value) {
        return __('In world %s', value)
      },
      options: {
        placeholder: __('Enter the map number here (e.g. 2-3, 32-5)'),
      },
    },
    '_idregex': {
      title: __('World number (fuzzy matching)'),
      postprocess: (path, value) => {
        let body, flags
        if (value.startsWith('/')) {
          const tokens = value.split('/')
          body = tokens[1]
          flags = tokens[2] || ''
        } else {
          body = value
          flags = ''
        }
        return {
          body: body,
          flags: flags,
          regex: RegExp(body, flags),
        }
      },
      func: function(path, arg, record) {
        const { regex } = arg
        return regex.test((record.map || {}).id)
      },
      textFunc: function(path, arg) {
        const { body, flags } = arg
        const value = `/${body}/${flags}`
        return __('In worlds %s', value)
      },
      options: {
        placeholder: __('Enter the map number regex here (e.g. ^34- for world 34, ^(33|34)- for 33 or 34)'),
      },
    },
    '_rank': {
      title: __('World difficulty'),
      func: (path, value, record) => {
        if (value === 0) {
          return (record.map || {}).rank != null
        } else {
          return get(record, 'map.rank', '').toString() === value.toString()
        }
      },
      textFunc: (path, value) =>
        __('In %s difficulty', __(['', 'Easy', 'Medium', 'Hard'][value])),
      sub: {
        '_ez': {
          title: __('Easy'),
          value: 1,
        },
        '_md': {
          title: __('Medium'),
          value: 2,
        },
        '_hd': {
          title: __('Hard'),
          value: 3,
        },
      },
    },
    '_hp': {
      title: __('World clearance'),
      func: (path, value, record) => {
        const hp = get(record, 'map.hp.0')
        const myValue = (hp != null) && hp > 0
        return myValue === value
      },
      textFunc: (path, value) => {
        if (value) {
          return __('In a world not yet cleared')
        } else {
          return __('In a cleared world')
        }
      },
      sub: {
        '_2': {
          title: __('The map has not been cleared'),
          value: true,
        },
        '_1': {
          title: __('The world has been cleared'),
          value: false,
        },
      },
    },
  },
}
