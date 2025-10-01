import { Controller } from "@hotwired/stimulus"
import { MathHelpers } from "./helpers/math_helpers"

// Connects to data-controller="photo-resize"
export default class extends Controller {
  static values = {
    photoId: String,
    collageId: String,
    imageWidth: Number,
    imageHeight: Number,
    size: Number,
    width: Number,
    height: Number,
    customAspect: Boolean
  }

  connect() {
    console.log("PhotoResize controller connected")
    this.resizing = false
    this.resizeEdge = null  // 'left', 'right', 'top', 'bottom', or combination
    this.gridXInc = 100
    this.gridYInc = 100
  }

  startSpatialEdit(event) {
    event.preventDefault()

    // Get mouse position relative to photo element
    const rect = this.element.getBoundingClientRect()
    const x = event.clientX - rect.left
    const y = event.clientY - rect.top

    // Edge detection: 10px threshold on all four sides
    const resizeLeft = x < 10
    const resizeRight = x > rect.width - 10
    const resizeTop = y < 10
    const resizeBottom = y > rect.height - 10

    // Determine if this is a resize or move operation
    if (resizeLeft || resizeRight || resizeTop || resizeBottom) {
      // Resize operation
      this.resizing = true
      this.resizeEdge = {
        left: resizeLeft,
        right: resizeRight,
        top: resizeTop,
        bottom: resizeBottom
      }

      // Set cursor style
      this.updateCursor()

      // Bind mousemove and mouseup to document
      this.boundHandleResize = this.handleResize.bind(this)
      this.boundEndSpatialEdit = this.endSpatialEdit.bind(this)

      document.addEventListener('mousemove', this.boundHandleResize)
      document.addEventListener('mouseup', this.boundEndSpatialEdit)
    } else {
      // Move operation (not currently implemented)
      console.log('Move operation detected but not supported')
    }
  }

  handleResize(event) {
    if (!this.resizing) return

    event.preventDefault()

    // Use requestAnimationFrame for 60fps performance
    if (this.rafId) {
      cancelAnimationFrame(this.rafId)
    }

    this.rafId = requestAnimationFrame(() => {
      const rect = this.element.getBoundingClientRect()

      // Start with current dimensions
      let newWidth = this.widthValue
      let newHeight = this.heightValue

      // Only update the dimension for the edge being dragged
      if (this.resizeEdge.right || this.resizeEdge.left) {
        // Horizontal resize: calculate grid cells based on mouse position
        const x = Math.round((event.clientX - rect.left) / this.gridXInc)
        newWidth = Math.max(1, x)
      }

      if (this.resizeEdge.bottom || this.resizeEdge.top) {
        // Vertical resize: calculate grid cells based on mouse position
        const y = Math.round((event.clientY - rect.top) / this.gridYInc)
        newHeight = Math.max(1, y)
      }

      // Only update if dimensions changed
      if (newWidth !== this.widthValue || newHeight !== this.heightValue) {
        this.widthValue = newWidth
        this.heightValue = newHeight
        this.sizeValue = newWidth * newHeight
        this.customAspectValue = true

        // Dispatch event to trigger grid reflow
        this.dispatch('dimensionsChanged', {
          detail: {
            photoId: this.photoIdValue,
            width: newWidth,
            height: newHeight,
            size: newWidth * newHeight,
            customAspect: true
          }
        })
      }

      this.rafId = null
    })
  }

  endSpatialEdit(event) {
    event.preventDefault()

    // Clean up event listeners
    if (this.boundHandleResize) {
      document.removeEventListener('mousemove', this.boundHandleResize)
    }
    if (this.boundEndSpatialEdit) {
      document.removeEventListener('mouseup', this.boundEndSpatialEdit)
    }

    // Cancel any pending animation frame
    if (this.rafId) {
      cancelAnimationFrame(this.rafId)
      this.rafId = null
    }

    // Reset cursor
    this.element.style.cursor = ''

    // Save photo dimensions to server
    if (this.resizing) {
      this.savePhoto()
    }

    this.resizing = false
    this.resizeEdge = null
  }

  updateCursor() {
    if (!this.resizeEdge) return

    const { left, right, top, bottom } = this.resizeEdge

    if ((top && left) || (bottom && right)) {
      this.element.style.cursor = 'nwse-resize'
    } else if ((top && right) || (bottom && left)) {
      this.element.style.cursor = 'nesw-resize'
    } else if (left || right) {
      this.element.style.cursor = 'ew-resize'
    } else if (top || bottom) {
      this.element.style.cursor = 'ns-resize'
    }
  }

  async savePhoto() {
    try {
      const response = await fetch(`/collages/${this.collageIdValue}/photos/${this.photoIdValue}`, {
        method: 'PATCH',
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'X-CSRF-Token': this.csrfToken()
        },
        body: JSON.stringify({
          photo: {
            width: this.widthValue,
            height: this.heightValue,
            size: this.sizeValue,
            custom_aspect: this.customAspectValue
          }
        })
      })

      if (!response.ok) {
        console.error('Failed to save photo dimensions')
      }
    } catch (error) {
      console.error('Error saving photo:', error)
    }
  }

  csrfToken() {
    const meta = document.querySelector('meta[name="csrf-token"]')
    return meta ? meta.content : ''
  }

  disconnect() {
    // Clean up if controller is removed while resizing
    if (this.boundHandleResize) {
      document.removeEventListener('mousemove', this.boundHandleResize)
    }
    if (this.boundEndSpatialEdit) {
      document.removeEventListener('mouseup', this.boundEndSpatialEdit)
    }
    if (this.rafId) {
      cancelAnimationFrame(this.rafId)
    }
  }
}
