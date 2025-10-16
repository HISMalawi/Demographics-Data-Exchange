document.addEventListener("DOMContentLoaded", () => {
  const totalEl = document.getElementById("total-footprints");
  const syncedEl = document.getElementById("synced_footprints");
  const unsyncedEl = document.getElementById("unsynced_footprints");
  const testBtn = document.getElementById("btn-test-sync");

  // --- 1. Fetch stats and populate UI ---
  async function fetchStats() {
    try {
      const response = await fetch("/footprints/stats", {
        headers: { "Accept": "application/json" }
      });

      if (!response.ok) throw new Error("Failed to fetch stats");

      const data = await response.json();
      totalEl.textContent = data.total_footprints || 0;
      syncedEl.textContent = data.synced_footprints || 0;
      unsyncedEl.textContent = data.unsynced_footprints || 0;
    } catch (error) {
      console.error("Error fetching footprint stats:", error);
    }
  }

  // --- 2. Trigger test sync ---
  async function runTestSync() {
    if (!testBtn) return;

    testBtn.disabled = true;
    const originalText = testBtn.innerHTML;
    testBtn.innerHTML = `<i class="fas fa-spinner fa-spin mr-2"></i> Syncing...`;

    try {
      const response = await fetch("/footprints/test_sync", {
        method: "POST",
        headers: { "X-CSRF-Token": getMetaValue("csrf-token"), "Accept": "application/json" }
      });

      if (!response.ok) throw new Error("Sync failed");

      const result = await response.json();
      alert(result.message || "Test sync completed!");
      fetchStats(); // Refresh counts after sync
    } catch (error) {
      console.error("Error running test sync:", error);
      alert("Failed to run test sync.");
    } finally {
      testBtn.disabled = false;
      testBtn.innerHTML = originalText;
    }
  }

  // --- Helper to grab CSRF token ---
  function getMetaValue(name) {
    const element = document.querySelector(`meta[name='${name}']`);
    return element && element.getAttribute("content");
  }

  // --- Initialize ---
  fetchStats();

  // Refresh every 30 seconds (optional)
  setInterval(fetchStats, 30000);

  // Bind button
  if (testBtn) {
    testBtn.addEventListener("click", runTestSync);
  }
});