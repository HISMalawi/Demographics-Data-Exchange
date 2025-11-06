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
    updateSyncStatus(data)

  }
});


let dotInterval // keep track of the interval for animated dots

function updateSyncStatus(data) {
  const statusElement = document.getElementById("sync-status-message")
  const button = document.getElementById("btn-test-sync")
  if (!statusElement) return

  // Clear any previous dot animation if a new message comes in
  if (dotInterval) {
    clearInterval(dotInterval)
    dotInterval = null
  }

  let colorClass = "text-gray-600"
  if (data.level === "info") colorClass = "text-blue-600"
  else if (data.level === "success") colorClass = "text-green-600"
  else if (data.level === "failed" || data.level === "error") colorClass = "text-red-600"
  else if (data.level === "warning") colorClass = "text-yellow-600"

  statusElement.className = `mt-2 text-sm font-semibold text-center ${colorClass}`

  // Base message without dots
  statusElement.textContent = data.message

  // Animate dots if it’s in-progress (info or warning)
  if (data.level === "info" || data.level === "warning") {
    let dots = 0
    dotInterval = setInterval(() => {
      dots = (dots + 1) % 4 // cycle 0..3
      statusElement.textContent = data.message + ".".repeat(dots)
    }, 500)
  }

  // Success or failure stops the animation
  if (data.level === "success") {
    clearInterval(dotInterval)
    dotInterval = null
    button.classList.remove("bg-green-600")
    button.classList.add("bg-green-700")
    statusElement.textContent = data.message + " ✅"
  }

  if (data.level === "failed" || data.level === "error") {
    clearInterval(dotInterval)
    dotInterval = null
    button.classList.remove("bg-green-600")
    button.classList.add("bg-red-700")
    statusElement.textContent = data.message + " ❌"
  }
}
;
