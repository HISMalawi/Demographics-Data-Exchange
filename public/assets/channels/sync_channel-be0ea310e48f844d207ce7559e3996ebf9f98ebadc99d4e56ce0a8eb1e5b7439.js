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


function updateSyncStatus(data) {
  const statusElement = document.getElementById("sync-status-message")
  const button = document.getElementById("btn-test-sync")
  if (!statusElement) return

  let colorClass = "text-gray-600"
  if (data.level === "info") colorClass = "text-blue-600"
  else if (data.level === "success") colorClass = "text-green-600"
  else if (data.level === "failed" || data.level === "error") colorClass = "text-red-600"
  else if (data.level === "warning") colorClass = "text-yellow-600"

  statusElement.className = `mt-2 text-sm font-semibold text-center ${colorClass}`
  statusElement.textContent = data.message

  // If process finished successfully
  if (data.level === "success") {
    button.classList.remove("bg-green-600")
    button.classList.add("bg-green-700")
    setTimeout(() => {
      statusElement.textContent = "Synchronization complete ✅"
    }, 1000)
  }

  // If process failed
  if (data.level === "failed" || data.level === "error") {
    button.classList.remove("bg-green-600")
    button.classList.add("bg-red-700")
    setTimeout(() => {
      statusElement.textContent = "Synchronization failed ❌"
    }, 1000)
  }
}
;
