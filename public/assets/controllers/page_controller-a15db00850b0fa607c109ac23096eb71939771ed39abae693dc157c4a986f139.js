import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { url: String }

  connect() {
    // optional: console.log("Page controller connected")
  }

  load(event) {
    event.preventDefault()
    const url = event.currentTarget.dataset.pageUrl

    fetch(url, {
      headers: { "Accept": "text/vnd.turbo-stream.html" } // optional if using Turbo Streams
    })
      .then(response => response.text())
      .then(html => {
        const container = document.querySelector("#mainContent > div > section > div")
        container.innerHTML = html

        // optional: rerun diagnostics if this is services page
        const pageContainer = document.getElementById("page_container")
        if (pageContainer?.dataset.page === "services_index") {
          runTroubleshooting()
        }
      })
      .catch(err => console.error("Error loading page:", err))
  }
};
