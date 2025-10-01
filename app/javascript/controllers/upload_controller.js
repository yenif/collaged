import { Controller } from "@hotwired/stimulus"
import { DirectUpload } from "@rails/activestorage"

// Connects to data-controller="upload"
export default class extends Controller {
  static targets = ["fileInput", "fileList", "pickFilesButton"]
  static values = {
    url: String,  // Upload URL (e.g., /collages/:guid/photos)
    collageId: String
  }

  connect() {
    console.log("Upload controller connected")
    this.shownDuplicateHashes = new Set()  // Track duplicates shown this session

    // Set up drag and drop on the content area
    this.setupDragAndDrop()
  }

  setupDragAndDrop() {
    const contentArea = document.getElementById('content')
    if (!contentArea) return

    contentArea.addEventListener('dragover', (e) => {
      e.preventDefault()
      e.stopPropagation()
      contentArea.classList.add('drag-over')
    })

    contentArea.addEventListener('dragleave', (e) => {
      e.preventDefault()
      e.stopPropagation()
      contentArea.classList.remove('drag-over')
    })

    contentArea.addEventListener('drop', (e) => {
      e.preventDefault()
      e.stopPropagation()
      contentArea.classList.remove('drag-over')

      const files = Array.from(e.dataTransfer.files)
      this.handleFiles(files)
    })
  }

  // Triggered when user clicks "choose files" button
  pickFiles(event) {
    event.preventDefault()
    this.fileInputTarget.click()
  }

  // Triggered when files are selected via file picker
  filesSelected(event) {
    const files = Array.from(event.target.files)
    this.handleFiles(files)
    // Reset input so same file can be selected again
    event.target.value = ''
  }

  async handleFiles(files) {
    // Filter for image files only
    const imageFiles = files.filter(file => {
      return file.type.match(/^image\/(jpeg|jpg|png|gif)$/)
    })

    if (imageFiles.length === 0) {
      alert('Please select valid image files (JPG, PNG, GIF)')
      return
    }

    // Check file sizes
    for (const file of imageFiles) {
      if (file.size > 10 * 1024 * 1024) {  // 10MB
        alert(`File ${file.name} is too large. Maximum size is 10MB.`)
        return
      }
    }

    // Add files to UI and start upload
    for (const file of imageFiles) {
      await this.uploadFile(file)
    }
  }

  async uploadFile(file) {
    // Create file entry in UI
    const fileId = `file-${Date.now()}-${Math.random().toString(36).substr(2, 9)}`
    const fileDiv = document.createElement('div')
    fileDiv.id = fileId
    fileDiv.innerHTML = `
      <div>${file.name} (${this.formatSize(file.size)}) <b class="progress">0%</b></div>
    `
    this.fileListTarget.appendChild(fileDiv)

    try {
      // Calculate file hash for duplicate detection
      const fileHash = await this.calculateFileHash(file)

      // Check if duplicate has been shown this session
      if (this.shownDuplicateHashes.has(fileHash)) {
        // Silent duplicate - just upload
        await this.performUpload(file, fileId)
      } else {
        // First time seeing this hash - check server
        const isDuplicate = await this.checkDuplicate(fileHash)

        if (isDuplicate) {
          // Show alert only on first duplicate per session
          alert(`The image "${file.name}" appears to be a duplicate. Uploading anyway.`)
          this.shownDuplicateHashes.add(fileHash)
        }

        await this.performUpload(file, fileId)
      }
    } catch (error) {
      console.error(`Error uploading ${file.name}:`, error)
      const progressEl = document.querySelector(`#${fileId} .progress`)
      if (progressEl) {
        progressEl.textContent = 'Error: ' + (error.message || 'Upload failed')
        progressEl.style.color = 'red'
      }
    }
  }

  async performUpload(file, fileId) {
    const progressEl = document.querySelector(`#${fileId} .progress`)

    // Create FormData with photo[image]
    const formData = new FormData()
    formData.append('photo[image]', file)

    const response = await fetch(this.urlValue, {
      method: 'POST',
      headers: {
        'X-CSRF-Token': this.csrfToken(),
        'Accept': 'application/json'
      },
      body: formData,
      // Track upload progress (basic - not as granular as XHR but simpler)
    })

    if (!response.ok) {
      const errorData = await response.json().catch(() => ({ error: 'Upload failed' }))

      if (response.status === 409) {
        // Duplicate detected by server
        throw new Error('Duplicate image detected')
      } else {
        throw new Error(errorData.error || 'Upload failed')
      }
    }

    const photoData = await response.json()

    // Update progress to 100%
    if (progressEl) {
      progressEl.textContent = '100%'
    }

    // Dispatch event for grid controller to add photo
    this.dispatch('photoUploaded', { detail: { photo: photoData } })
  }

  async calculateFileHash(file) {
    // Read file as ArrayBuffer
    const arrayBuffer = await file.arrayBuffer()

    // Calculate SHA-1 hash
    const hashBuffer = await crypto.subtle.digest('SHA-1', arrayBuffer)

    // Convert to hex string
    const hashArray = Array.from(new Uint8Array(hashBuffer))
    const hashHex = hashArray.map(b => b.toString(16).padStart(2, '0')).join('')

    return hashHex
  }

  async checkDuplicate(fileHash) {
    try {
      // Query the server for existing photos with this hash
      const response = await fetch(`${this.urlValue}?image_hash=${fileHash}`, {
        method: 'GET',
        headers: {
          'Accept': 'application/json',
          'X-CSRF-Token': this.csrfToken()
        }
      })

      if (response.ok) {
        const photos = await response.json()
        return photos.some(photo => photo.image_hash === fileHash)
      }
    } catch (error) {
      console.error('Error checking for duplicate:', error)
    }

    return false
  }

  formatSize(bytes) {
    if (bytes < 1024) return bytes + ' B'
    if (bytes < 1024 * 1024) return (bytes / 1024).toFixed(1) + ' KB'
    return (bytes / (1024 * 1024)).toFixed(1) + ' MB'
  }

  csrfToken() {
    const meta = document.querySelector('meta[name="csrf-token"]')
    return meta ? meta.content : ''
  }
}
