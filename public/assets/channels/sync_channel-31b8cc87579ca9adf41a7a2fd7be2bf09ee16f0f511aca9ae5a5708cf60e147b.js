import consumer from "./consumer"

consumer.subscriptions.create("SyncChannel", {
  connected() {
    // Called when the subscription is ready for use on the server
    console.log("✅ Connnected to SyncChannel");
  },

  disconnected() {
    // Called when the subscription has been terminated by the server
    console.log("❌ Disconnected from SyncChannel")
  },

  received(data) {
    // Called when there's incoming data on the websocket for this channel
    console.log(`[${data.timestamp}] [${data.level.toUpperCase()}] ${data.message}`)
    appendLogMessage(data)

  }
});


function appendLogMessage(data) {
  const logContainer = document.getElementById("sync-log")
  if (!logContainer) return

  const line = document.createElement("p")

  // Apply color styles based on message level
  let colorClass = "text-gray-700"
  if (data.level === "info") colorClass = "text-blue-600"
  else if (data.level === "success") colorClass = "text-green-600"
  else if (data.level === "failed" || data.level === "error") colorClass = "text-red-600"
  else if (data.level === "warning") colorClass = "text-yellow-600"

  line.className = `${colorClass} whitespace-pre-wrap`
  line.textContent = `[${data.timestamp}] (${data.level.toUpperCase()}) ${data.message}`

  logContainer.appendChild(line)
  logContainer.scrollTop = logContainer.scrollHeight
}

// Optional: Bind Synchronize button click
document.addEventListener("DOMContentLoaded", () => {
  const btn = document.getElementById("btn-test-sync")
  if (btn) {
    btn.addEventListener("click", () => {
      appendLogMessage({
        timestamp: new Date().toLocaleTimeString(),
        level: "info",
        message: "Starting synchronization..."
      })
      // Optionally, trigger your Rails job here with a fetch() or AJAX call
    })
  }
});
