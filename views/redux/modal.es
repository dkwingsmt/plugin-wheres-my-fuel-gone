const defaultState = {
  show: false,
  contents: '',
  title: '',
  buttons: [],
}

export default function reducer(state=defaultState, action) {
  const { type, contents, title, buttons } = action
  switch (type) {
  case '@@poi-plugin-wheres-my-fuel-gone/displayModal':
    return {
      show: true,
      title,
      contents,
      buttons,
    }
  case '@@poi-plugin-wheres-my-fuel-gone/dismissModal':
    return {
      show: false,
    }
  }
  return state
}

export function displayModal(title, contents, buttons=[]) {
  return {
    type: '@@poi-plugin-wheres-my-fuel-gone/displayModal',
    title,
    contents,
    buttons,
  }
}

export function dismissModal() {
  return {
    type: '@@poi-plugin-wheres-my-fuel-gone/dismissModal',
  }
}
