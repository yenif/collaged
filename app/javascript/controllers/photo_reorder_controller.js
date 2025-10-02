import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="photo-reorder"
export default class extends Controller {
  static values = {
    photoId: String,
    collageId: String,
    ordinal: Number
  }

  connect() {
    console.log("PhotoReorder controller connected", {
      photoId: this.photoIdValue,
      ordinal: this.ordinalValue
    })

    this.draggedPhotoId = null
    this.rafPending = false
  }

  disconnect() {
    // Cleanup any lingering event listeners
    this.clearDragState()
  }

  // HTML5 Drag and Drop API event handlers

  startDrag(event) {
    console.log("Drag started for photo", this.photoIdValue, "element:", this.element)

    // Store the dragged photo's ID in the dataTransfer object
    event.dataTransfer.setData('application/photo-id', this.photoIdValue)
    event.dataTransfer.setData('application/photo-ordinal', this.ordinalValue.toString())
    event.dataTransfer.effectAllowed = 'move'

    // Clone the element for drag image preview
    const clone = this.element.cloneNode(true)
    const rect = this.element.getBoundingClientRect()

    // Style the clone to match exact dimensions and position it offscreen
    clone.style.position = 'absolute'
    clone.style.width = `${rect.width}px`
    clone.style.height = `${rect.height}px`
    clone.style.left = '-9999px'
    clone.style.top = '-9999px'
    clone.style.overflow = 'hidden'
    clone.style.pointerEvents = 'none'

    // Add to DOM temporarily so browser can capture it
    document.body.appendChild(clone)

    // Use center of element as offset for better visual feedback
    const offsetX = rect.width / 2
    const offsetY = rect.height / 2

    console.log("Setting drag image with offset:", offsetX, offsetY, "rect:", rect.width, "x", rect.height)
    event.dataTransfer.setDragImage(clone, offsetX, offsetY)

    // Remove clone after a short delay (after browser captures it)
    setTimeout(() => {
      document.body.removeChild(clone)
    }, 0)

    // Add visual feedback: semi-transparent during drag
    // Use setTimeout to apply after drag image is captured
    setTimeout(() => {
      this.element.classList.add('dragging')
      console.log("Added dragging class")
    }, 0)

    this.draggedPhotoId = this.photoIdValue

    // Store reference for cleanup
    this.originalElement = this.element
  }

  handleDragOver(event) {
    // Prevent default to allow dropping
    event.preventDefault()
    event.stopPropagation()

    // Set drop effect to match effectAllowed
    event.dataTransfer.dropEffect = 'move'

    // Throttle visual updates with requestAnimationFrame for 60fps performance
    if (this.rafPending) return
    this.rafPending = true

    requestAnimationFrame(() => {
      // Add visual feedback to drop target
      if (this.element !== this.originalElement) {
        this.element.classList.add('drag-over')
      }
      this.rafPending = false
    })
  }

  handleDragLeave(event) {
    // Remove drop target highlighting when mouse leaves
    // Check if we're actually leaving the element (not just entering a child)
    const rect = this.element.getBoundingClientRect()
    const x = event.clientX
    const y = event.clientY

    // Only remove highlight if cursor is outside element bounds
    if (x < rect.left || x > rect.right || y < rect.top || y > rect.bottom) {
      this.element.classList.remove('drag-over')
    }
  }

  async handleDrop(event) {
    event.preventDefault()
    event.stopPropagation()

    // Remove visual feedback from drop target
    this.element.classList.remove('drag-over')

    // Get the dragged photo's information
    const draggedPhotoId = event.dataTransfer.getData('application/photo-id')
    const draggedOrdinal = parseInt(event.dataTransfer.getData('application/photo-ordinal'), 10)

    // Don't do anything if dropped on itself
    if (draggedPhotoId === this.photoIdValue) {
      console.log("Photo dropped on itself, no reorder needed")
      return
    }

    // Determine if dropped on left or right half of target
    const rect = this.element.getBoundingClientRect()
    const dropX = event.clientX - rect.left
    const halfWidth = rect.width / 2
    const isRightHalf = dropX > halfWidth

    console.log("Photo dropped:", {
      draggedPhotoId,
      draggedOrdinal,
      targetPhotoId: this.photoIdValue,
      targetOrdinal: this.ordinalValue,
      dropPosition: isRightHalf ? 'right (after)' : 'left (before)'
    })

    // Calculate new ordinal based on drop position
    // If dropped on left half: insert before target (use target's ordinal)
    // If dropped on right half: insert after target (use target's ordinal + 1)
    const newOrdinal = isRightHalf ? this.ordinalValue + 1 : this.ordinalValue

    // Update the dragged photo's ordinal
    try {
      await this.updatePhotoOrdinal(draggedPhotoId, newOrdinal)

      // Dispatch event to grid controller to trigger reflow
      this.dispatchReorderEvent(draggedPhotoId, draggedOrdinal, newOrdinal)
    } catch (error) {
      console.error("Failed to update photo ordinal:", error)
      alert("Failed to reorder photo. Please try again.")
    }
  }

  endDrag(event) {
    console.log("Drag ended")

    // Clear all visual feedback
    this.clearDragState()
  }

  clearDragState() {
    // Remove dragging class from the photo being dragged
    if (this.originalElement) {
      this.originalElement.classList.remove('dragging')
    }

    // Remove drag-over class from all photos
    document.querySelectorAll('.photo.drag-over').forEach(el => {
      el.classList.remove('drag-over')
    })

    this.draggedPhotoId = null
    this.originalElement = null
  }

  async updatePhotoOrdinal(photoId, newOrdinal) {
    const url = `/collages/${this.collageIdValue}/photos/${photoId}`

    console.log(`Updating photo ${photoId} to ordinal ${newOrdinal}`)

    const response = await fetch(url, {
      method: 'PATCH',
      headers: {
        'Content-Type': 'application/json',
        'X-CSRF-Token': this.csrfToken(),
        'Accept': 'application/json'
      },
      body: JSON.stringify({
        photo: {
          ordinal: newOrdinal
        }
      })
    })

    if (!response.ok) {
      const errorText = await response.text()
      throw new Error(`HTTP ${response.status}: ${errorText}`)
    }

    const data = await response.json()
    console.log("Photo ordinal updated successfully:", data)
    return data
  }

  dispatchReorderEvent(photoId, oldOrdinal, newOrdinal) {
    // Dispatch custom event that grid controller will listen for
    const event = new CustomEvent('reorder:photoMoved', {
      bubbles: true,
      detail: {
        photoId,
        oldOrdinal,
        newOrdinal
      }
    })

    this.element.dispatchEvent(event)
    console.log("Dispatched reorder:photoMoved event", event.detail)
  }

  csrfToken() {
    // Get CSRF token from meta tag
    const token = document.querySelector('meta[name="csrf-token"]')
    return token ? token.getAttribute('content') : ''
  }
}
