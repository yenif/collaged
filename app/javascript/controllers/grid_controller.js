import { Controller } from "@hotwired/stimulus"
import { MathHelpers } from "./helpers/math_helpers"

// Connects to data-controller="grid"
export default class extends Controller {
  static targets = ["container"]
  static values = {
    collageId: String
  }

  connect() {
    console.log("Grid controller connected")
    this.padding = 10
    this.gridXInc = 100
    this.gridYInc = 100
    this.photos = []

    // Listen for photo upload events
    this.boundHandlePhotoUploaded = this.handlePhotoUploaded.bind(this)
    this.element.addEventListener('upload:photoUploaded', this.boundHandlePhotoUploaded)

    // Listen for photo dimension changes
    this.boundHandleDimensionsChanged = this.handleDimensionsChanged.bind(this)
    this.element.addEventListener('photo-resize:dimensionsChanged', this.boundHandleDimensionsChanged)

    // Load existing photos
    this.loadPhotos()
  }

  async loadPhotos() {
    try {
      const response = await fetch(`/collages/${this.collageIdValue}/photos`, {
        headers: {
          'Accept': 'application/json',
          'X-CSRF-Token': this.csrfToken()
        }
      })

      if (response.ok) {
        this.photos = await response.json()
        this.render()
      }
    } catch (error) {
      console.error('Error loading photos:', error)
    }
  }

  handlePhotoUploaded(event) {
    const photo = event.detail.photo
    this.photos.push(photo)
    this.render()
  }

  handleDimensionsChanged(event) {
    const { photoId, width, height, size, customAspect } = event.detail

    // Find and update the photo
    // Handle MongoDB ObjectId format
    const photo = this.photos.find(p => {
      const pId = typeof p.id === 'object' && p.id.$oid ? p.id.$oid : p.id
      return pId === photoId
    })

    if (photo) {
      photo.width = width
      photo.height = height
      photo.size = size
      photo.custom_aspect = customAspect

      // Re-render entire grid
      this.render()

      // Persist changes to server
      this.updatePhotoOnServer(photoId, { width, height, size, custom_aspect: customAspect })
    }
  }

  render() {
    // Calculate grid width based on container width
    const containerWidth = this.containerTarget.offsetWidth
    const gridWidth = Math.floor(containerWidth / this.gridXInc)

    // Reset grid state
    let yOffset = 0
    let x = 0
    let grid = []

    // Clear container
    this.containerTarget.innerHTML = ''
    this.containerTarget.style.position = 'relative'
    this.containerTarget.style.height = '100px'  // Initial height

    // Place each photo using greedy left-to-right algorithm
    this.photos.forEach(photo => {
      const photoView = this.addPhoto(photo, x, yOffset, grid, gridWidth)
      if (photoView) {
        // Update x and grid state based on returned values
        x = photoView.nextX
        yOffset = photoView.nextYOffset
        grid = photoView.nextGrid
      }
    })

    // Update container height
    const finalHeight = (yOffset + grid.length) * this.gridYInc
    this.containerTarget.style.height = `${finalHeight}px`
  }

  addPhoto(photo, x, yOffset, grid, gridWidth) {
    // Ensure photo has dimensions
    if (!photo.width || !photo.height) {
      // Calculate default dimensions
      const dims = MathHelpers.calculateDefaultDimensions(
        photo.size || 1,
        photo.image_width,
        photo.image_height,
        photo.custom_aspect || false,
        photo.width || 1,
        photo.height || 1
      )
      photo.width = dims.width
      photo.height = dims.height
    }

    // Find a spot for the photo
    while (true) {
      // If x exceeds grid width, wrap to next row
      if (x >= gridWidth) {
        x = 0
        grid.shift()  // Remove top row
        yOffset++
      }

      // Ensure grid[0] exists
      if (!grid[0]) {
        grid[0] = new Array(gridWidth).fill(false)
      }

      // Check for overlap
      let overlap = false
      const photoWidth = Math.min(photo.width, gridWidth)

      for (let i = 0; i < photoWidth; i++) {
        if (x + i >= gridWidth || grid[0][x + i]) {
          overlap = true
          break
        }
      }

      if (!overlap) {
        // Place photo at this position
        const photoElement = this.createPhotoElement(photo, {
          x: x * this.gridXInc + this.padding,
          y: yOffset * this.gridYInc + this.padding,
          w: photo.width * this.gridXInc,
          h: photo.height * this.gridYInc
        })

        this.containerTarget.appendChild(photoElement)

        // Mark grid cells as occupied
        for (let y = 0; y < photo.height; y++) {
          if (!grid[y]) {
            grid[y] = new Array(gridWidth).fill(false)
          }

          for (let k = 0; k < photo.width; k++) {
            if (x + k < grid[y].length) {
              grid[y][x + k] = true
            }
          }
        }

        // Return updated state
        return {
          nextX: x + photo.width,
          nextYOffset: yOffset,
          nextGrid: grid
        }
      } else {
        // Try next position
        x++
      }

      // Safety check to prevent infinite loop
      if (x > gridWidth * 2) {
        console.error('Grid placement error: infinite loop detected')
        return null
      }
    }
  }

  createPhotoElement(photo, position) {
    const div = document.createElement('div')
    div.className = 'photo'
    div.style.position = 'absolute'
    div.style.overflow = 'hidden'
    div.style.left = `${position.x + 1}px`
    div.style.top = `${position.y + 1}px`
    div.style.width = `${position.w - 2}px`  // Subtract 2px for border
    div.style.height = `${position.h - 2}px`

    // Add photo-resize controller
    div.dataset.controller = 'photo-resize'
    // Handle MongoDB ObjectId format {$oid: "..."} or plain string
    const photoId = typeof photo.id === 'object' && photo.id.$oid ? photo.id.$oid : photo.id
    div.dataset.photoResizePhotoIdValue = photoId
    div.dataset.photoResizeCollageIdValue = this.collageIdValue
    div.dataset.photoResizeImageWidthValue = photo.image_width
    div.dataset.photoResizeImageHeightValue = photo.image_height
    div.dataset.photoResizeSizeValue = photo.size
    div.dataset.photoResizeWidthValue = photo.width
    div.dataset.photoResizeHeightValue = photo.height
    div.dataset.photoResizeCustomAspectValue = photo.custom_aspect || false
    div.dataset.action = 'mousedown->photo-resize#startSpatialEdit'

    // Calculate image dimensions for cover-fit with center crop
    const containerAspect = position.h / position.w
    const imageAspect = photo.image_height / photo.image_width

    let imgStyle = {
      position: 'relative'
    }

    if (containerAspect > imageAspect) {
      // Container is taller than image - fit height, center horizontally
      imgStyle.height = `${position.h - 2}px`
      imgStyle.width = 'auto'
      imgStyle.top = '0px'
      imgStyle.left = `${Math.floor((((position.w - 2) / photo.image_width) * photo.image_height) - (position.h - 2)) / 2}px`
    } else {
      // Container is wider than image - fit width, center vertically
      imgStyle.height = 'auto'
      imgStyle.width = `${position.w - 2}px`
      imgStyle.top = `${Math.floor((((position.h - 2) / photo.image_height) * photo.image_width) - (position.w - 2)) / 2}px`
      imgStyle.left = '0px'
    }

    const img = document.createElement('img')
    img.src = photo.image_url
    img.style.position = imgStyle.position
    img.style.width = imgStyle.width
    img.style.height = imgStyle.height
    img.style.top = imgStyle.top
    img.style.left = imgStyle.left

    div.appendChild(img)

    return div
  }

  async updatePhotoOnServer(photoId, attrs) {
    try {
      const response = await fetch(`/collages/${this.collageIdValue}/photos/${photoId}`, {
        method: 'PATCH',
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'X-CSRF-Token': this.csrfToken()
        },
        body: JSON.stringify({ photo: attrs })
      })

      if (!response.ok) {
        console.error('Failed to update photo on server')
      }
    } catch (error) {
      console.error('Error updating photo:', error)
    }
  }

  csrfToken() {
    const meta = document.querySelector('meta[name="csrf-token"]')
    return meta ? meta.content : ''
  }

  disconnect() {
    if (this.boundHandlePhotoUploaded) {
      this.element.removeEventListener('upload:photoUploaded', this.boundHandlePhotoUploaded)
    }
    if (this.boundHandleDimensionsChanged) {
      this.element.removeEventListener('photo-resize:dimensionsChanged', this.boundHandleDimensionsChanged)
    }
  }
}
