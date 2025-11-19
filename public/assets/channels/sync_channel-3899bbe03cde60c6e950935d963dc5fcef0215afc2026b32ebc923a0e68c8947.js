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
  }
});
