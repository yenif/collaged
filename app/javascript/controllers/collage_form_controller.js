import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="collage-form"
export default class extends Controller {
  static targets = ["title", "submit", "errors"]

  connect() {
    console.log("CollageForm controller connected")
  }

  async create(event) {
    event.preventDefault()

    const title = this.titleTarget.value.trim()

    // Client-side validation
    if (!title) {
      this.showError("Title must not be blank")
      return
    }

    // Disable submit button during request
    this.submitTarget.disabled = true

    try {
      const response = await fetch("/collages", {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "Accept": "application/json",
          "X-CSRF-Token": this.csrfToken()
        },
        body: JSON.stringify({
          collage: { title }
        })
      })

      const data = await response.json()

      if (response.ok) {
        // Redirect to collage show page
        window.location.href = `/collages/${data.id}`
      } else {
        // Display server validation errors
        this.showError(data.errors?.title?.[0] || "Failed to create collage")
      }
    } catch (error) {
      console.error("Error creating collage:", error)
      this.showError("Network error. Please try again.")
    } finally {
      this.submitTarget.disabled = false
    }
  }

  showError(message) {
    if (this.hasErrorsTarget) {
      this.errorsTarget.textContent = message
      this.errorsTarget.style.display = "block"
    } else {
      alert(message)
    }
  }

  csrfToken() {
    const meta = document.querySelector('meta[name="csrf-token"]')
    return meta ? meta.content : ""
  }
}
