// app/javascript/controllers/page_controller.js
import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="page"
export default class extends Controller {
  static targets = ["content"]

  connect() {
    console.log("Page controller connected")
  }

  // Called when sidebar button is clicked
  load(event) {
    event.preventDefault()
    const url = event.currentTarget.dataset.pageUrl
    if (!url) return console.error("No URL found on clicked element")

    this.showLoading()

    fetch(url, {
      headers: { "Accept": "text/html" }, // normal HTML fetch
    })
      .then(response => {
        if (!response.ok) throw new Error(`HTTP ${response.status}`)
        return response.text()
      })
      .then(html => {
        // Create a temporary DOM parser
        const parser = new DOMParser()
        const doc = parser.parseFromString(html, "text/html")
        const mainContent = doc.querySelector("main")
        if (mainContent) {
          this.contentTarget.innerHTML = mainContent.innerHTML
        } else {
          console.warn("No <main> found in fetched page, inserting raw HTML")
          this.contentTarget.innerHTML = html
        }
        this.hideLoading()

        // Optional: run auto troubleshooting if loading services page
        if (url.includes("/api/v1/services")) this.autoTroubleshoot()
      })
      .catch(err => {
        console.error("Error loading page:", err)
        this.hideLoading()
        this.showError("Failed to load page.")
      })
  }

  showLoading() {
    if (!this.loadingDiv) {
      this.loadingDiv = document.createElement("div")
      this.loadingDiv.textContent = "Loading..."
      this.loadingDiv.classList.add("text-center", "py-4", "text-gray-500")
      this.contentTarget.prepend(this.loadingDiv)
    }
  }

  hideLoading() {
    if (this.loadingDiv) {
      this.loadingDiv.remove()
      this.loadingDiv = null
    }
  }

  showError(message) {
    const errorDiv = document.createElement("div")
    errorDiv.textContent = message
    errorDiv.classList.add("text-center", "py-4", "text-red-500")
    this.contentTarget.prepend(errorDiv)
    setTimeout(() => errorDiv.remove(), 5000)
  }

  autoTroubleshoot() {
    try {
      console.log("Running auto troubleshooting...")
      if (typeof window.troubleshootError === "function") {
        window.troubleshootError()
      }
    } catch (err) {
      console.error("Error running autoTroubleshoot:", err)
    }
  }
};
