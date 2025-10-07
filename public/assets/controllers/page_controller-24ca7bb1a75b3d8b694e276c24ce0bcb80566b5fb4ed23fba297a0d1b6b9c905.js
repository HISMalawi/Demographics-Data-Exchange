// app/javascript/controllers/page_controller.js
import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="page"
export default class extends Controller {
  static targets = ["content"]

  connect() {
    console.log("Page controller connected")
  }

  load(event) {
    event.preventDefault()
    const url = event.currentTarget.dataset.pageUrl
    if (!url) return console.error("No URL found on clicked element")

    this.showLoading()

    fetch(url, { headers: { "Accept": "text/html" } })
      .then(response => {
        if (!response.ok) throw new Error(`HTTP ${response.status}`)
        return response.text()
      })
      .then(html => {
        const parser = new DOMParser()
        const doc = parser.parseFromString(html, "text/html")
        const mainContent = doc.querySelector("main")

        // Animate content out
        this.contentTarget.classList.add("opacity-0", "transition-opacity", "duration-300")

        setTimeout(() => {
          // Replace content
          if (mainContent) {
            this.contentTarget.innerHTML = mainContent.innerHTML
          } else {
            this.contentTarget.innerHTML = html
          }

          // Animate content in
          this.contentTarget.classList.remove("opacity-0")
          this.contentTarget.classList.add("opacity-100")

          this.hideLoading()

          if (url.includes("/api/v1/services")) this.autoTroubleshoot()
        }, 150)
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
