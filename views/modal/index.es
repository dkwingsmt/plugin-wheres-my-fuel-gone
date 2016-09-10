import React from 'react'
import { Modal, Button } from 'react-bootstrap'
import { connect } from 'react-redux'

import { pluginDataSelector } from '../redux/selectors'
import { dismissModal } from '../redux/modal'

const { __ } = window

export default connect(
  (state) =>
    pluginDataSelector(state).modal,
  {
    dismissModal,
  }
)(function ModalMain(props) {
  const {show, title, contents, buttons=[]} = props
  return (
    <Modal autoFocus={true}
           animation={true}
           show={show}
           onHide={props.dismissModal}>
      <Modal.Header closeButton>
        <Modal.Title>{title}</Modal.Title>
      </Modal.Header>
      <Modal.Body>
        {contents}
      </Modal.Body>
      <Modal.Footer>
        {buttons}
        <Button onClick={props.dismissModal}>{__('Close')}</Button>
      </Modal.Footer>
    </Modal>
  )
})
