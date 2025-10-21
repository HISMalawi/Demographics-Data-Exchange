// app/javascript/troubleshooting.js

// --- Footprint Stats ---
export async function fetchStats() {
  const totalEl = document.getElementById("total-footprints");
  const syncedEl = document.getElementById("synced_footprints");
  const unsyncedEl = document.getElementById("unsynced_footprints");

  // Spinners for count cards only
  const spinners = {
    total: document.getElementById("total-footprints-spinner"),
    synced: document.getElementById("synced_footprints-spinner"),
    unsynced: document.getElementById("unsynced_footprints-spinner")
  };

  try {
    const response = await fetch("/v1/sync_stats", { headers: { "Accept": "application/json" } });
    if (!response.ok) throw new Error("Failed to fetch stats");

    const data = await response.json();
    const { stats = {}, location = {} } = data;
    const { total = 0, synced = 0, unsynced = 0 } = stats;

    // Update counts
    if (totalEl) totalEl.textContent = total.toLocaleString();
    if (syncedEl) syncedEl.textContent = synced.toLocaleString();
    if (unsyncedEl) unsyncedEl.textContent = unsynced.toLocaleString();

    // Hide spinners after data loads
    Object.values(spinners).forEach(spinner => spinner?.classList.add("hidden"));

    console.log(`Location: ${location.name || "Unknown"} (${location.ip || "N/A"})`);
  } catch (error) {
    console.error("Error fetching footprint stats:", error);
  }
}


// --- Troubleshooting ---
export async function autoRunTroubleshooting() {
  const outputDiv = document.getElementById("output");
  const statusText = document.getElementById("status_text");
  const statusIndicator = document.getElementById("status_indicator");
  const progressBar = document.getElementById("troubleshoot_progress");

  if (!outputDiv) return;

  outputDiv.innerHTML = `<h3 class="text-xl font-semibold text-gray-800 mb-2">Diagnostics Output</h3>`;
  progressBar.style.width = "0%";

  const checklist = [
    { key: "unlock_sync_job", name: "Unlock Sync Job" },
    { key: "resolve_sync_configs", name: "Resolve Sync Configurations" },
    { key: "detect_footprint_conflicts", name: "Detect Footprint Conflicts" },
  ];

  let step = 0;

  for (const item of checklist) {
    step++;
    statusIndicator?.classList.replace("bg-gray-400", "bg-blue-500");
    statusText.textContent = `Running ${item.name}...`;

    try {
      const response = await fetch("/api/v1/troubleshooting/troubleshoot", {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "Accept": "application/json",
        },
        body: JSON.stringify({ error_type: item.key }),
      });

      const result = await response.json();

      const colorClass = result.status === "ok"
        ? "bg-green-50 border-green-300 text-green-700"
        : "bg-red-50 border-red-300 text-red-700";

      const section = document.createElement("div");
      section.className = `p-4 mb-4 rounded-lg border ${colorClass} shadow-sm transition-all duration-300`;
      section.innerHTML = `<strong class="block mb-1">${item.name}</strong>
                           <span class="whitespace-pre-line">${result.message || "No message"}</span>`;

      outputDiv.appendChild(section);
    } catch (error) {
      const errorDiv = document.createElement("div");
      errorDiv.className = "text-red-600 p-2 border border-red-200 rounded mb-2";
      errorDiv.textContent = `Error running ${item.name}: ${error}`;
      outputDiv.appendChild(errorDiv);
    }

    progressBar.style.width = `${Math.round((step / checklist.length) * 100)}%`;
  }

  statusIndicator?.classList.replace("bg-blue-500", "bg-gray-400");
  statusText.textContent = "Diagnostics completed";
}

export async function runTestSync(){
    const testBtn = document.getElementById("btn-test-sync");

    if (!testBtn) return;

    testBtn.disabled = true;
    const originalText = testBtn.innerHTML;
    testBtn.innerHTML = `<i class="fas fa-spinner fa-spin mr-2"></i> Syncing...`;

    try {
      const response = await fetch("/footprints/test_sync", {
        method: "POST",
        headers: {
          "X-CSRF-Token": getMetaValue("csrf-token"),
          "Accept": "application/json"
        }
      });

      if (!response.ok) throw new Error("Sync failed");

      const result = await response.json();
      alert(result.message || "Test sync completed!");
      
    } catch (error) {
      console.error("Error running test sync:", error);
      alert("Failed to run test sync.");
    } finally {
      testBtn.disabled = false;
      testBtn.innerHTML = originalText;
    }
}

// --- Helper ---
function getMetaValue(name) {
  const element = document.querySelector(`meta[name='${name}']`);
  return element && element.getAttribute("content");
};
