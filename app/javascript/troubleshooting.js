// app/javascript/troubleshooting.js

// --- Footprint Stats ---
export async function fetchStats() {
  const totalEl = document.getElementById("total-footprints");
  const syncedEl = document.getElementById("synced_footprints");
  const unsyncedEl = document.getElementById("unsynced_footprints");
  const lastSyncedEl = document.getElementById("last-synced-date");

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
    const { total = 0, synced = 0, unsynced = 0, last_updated = "" } = stats;


    // Update counts
    if (totalEl) totalEl.textContent = total.toLocaleString();
    if (syncedEl) syncedEl.textContent = synced.toLocaleString();
    if (unsyncedEl) unsyncedEl.textContent = unsynced.toLocaleString();
    if (lastSyncedEl) lastSyncedEl.textContent = last_updated.toLocaleString();

    // Hide spinners after data loads
    Object.values(spinners).forEach(spinner => spinner?.classList.add("hidden"));

    document.getElementById("facility-name").textContent = `${location.name || "Unknown"} (${location.ip || "N/A"})`

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

  outputDiv.innerHTML = "";
  outputDiv.innerHTML = `<h3 class="text-xl font-semibold text-gray-800 mb-2">Diagnostics Output</h3>`;
  progressBar.style.width = "0%";

  const checklist = [
    { key: "unlock_sync_job", name: "Unlock Sync Job" },
    { key: "resolve_sync_configs", name: "Resolve Sync Configurations" },
    { key: "detect_footprint_conflicts", name: "Detect Footprint Conflicts" },
    { key: "resolve_program_credentials", name: "Resolve Program Users Configs" }
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

      if (item.key === "resolve_program_credentials") {
        const section = document.createElement("div");
        section.className = `p-4 mb-4 rounded-lg border border-gray-300 bg-white shadow-sm transition-all duration-300`;
        
        let tableHTML = `<strong class="block mb-3">${item.name}</strong>
                         <table class="w-full text-sm border-collapse">
                           <thead>
                             <tr class="border-b-2 border-gray-300">
                               <th class="text-left p-2 font-semibold">Program</th>
                               <th class="text-left p-2 font-semibold">Username</th>
                               <th class="text-center p-2 font-semibold">Authentication Status</th>
                               <th class="text-center p-2 font-semibold">Action</th>
                             </tr>
                           </thead>
                           <tbody>`;
        
        if (result.message && Array.isArray(result.message)) {
          result.message.forEach(cred => {
            const statusBg = cred.authentication_status === "passed" ? "bg-green-100 text-green-800" : "bg-red-100 text-red-800";
            const isFailedBtn = cred.authentication_status === "failed" 
              ? `<button class="px-3 py-1 rounded bg-blue-500 hover:bg-blue-600 text-white text-s font-medium reset-cred-btn" data-program="${cred.program}">Reset</button>`
              : `<span class="text-gray-400 text-xs">N/A</span>`;
            
            tableHTML += `<tr class="border-b border-gray-200 hover:bg-gray-50">
                            <td class="p-2">${cred.program || "N/A"}</td>
                            <td class="p-2">${cred.username || "N/A"}</td>
                            <td class="p-2 text-center"><span class="px-3 py-1 rounded ${statusBg} font-medium">${cred.authentication_status || "N/A"}</span></td>
                            <td class="p-2 text-center">${isFailedBtn}</td>
                          </tr>`;
          });
        }
        
        tableHTML += `</tbody>
                     </table>`;
        
        section.innerHTML = tableHTML;
        outputDiv.appendChild(section);
      } else {
        const section = document.createElement("div");
        section.className = `p-4 mb-4 rounded-lg border ${colorClass} shadow-sm transition-all duration-300`;
        section.innerHTML = `<strong class="block mb-1">${item.name}</strong>
                           <span class="whitespace-pre-line">${result.message || "No message"}</span>`;
        outputDiv.appendChild(section);
      }
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

export async function runTestSync() {
  const testBtn = document.getElementById("btn-test-sync");

  if (!testBtn) return;

  testBtn.disabled = true;
  const originalText = testBtn.innerHTML;
  testBtn.innerHTML = `<i class="fas fa-spinner fa-spin mr-2"></i> Syncing...`;

  try {
    const response = await fetch("/api/v1/troubleshooting/test_sync", {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "Accept": "application/json",
      }
    });


  } catch (error) {
    console.error("Error running test sync:", error);
    showAlert("Sync Test ", error.message || "Failed to run test sync.", "error");
  } finally {
    testBtn.disabled = false;
    testBtn.innerHTML = originalText;
  }
}

// --- Helper ---
function getMetaValue(name) {
  const element = document.querySelector(`meta[name='${name}']`);
  return element && element.getAttribute("content");
}

function showAlert(title, message, type = "info", duration = 5000) {
  const alertEl = document.getElementById("sync-alert");
  const titleEl = document.getElementById("sync-alert-title");
  const messageEl = document.getElementById("sync-alert-message");

  // Set text
  titleEl.innerText = title;
  messageEl.innerText = message;

  // Set color based on type
  let bgColor = "bg-white";
  let titleColor = "text-gray-900";
  switch (type) {
    case "success":
      bgColor = "bg-green-100";
      titleColor = "text-green-800";
      break;
    case "error":
      bgColor = "bg-red-100";
      titleColor = "text-red-800";
      break;
    case "warning":
      bgColor = "bg-yellow-100";
      titleColor = "text-yellow-800";
      break;
    case "info":
    default:
      bgColor = "bg-blue-100";
      titleColor = "text-blue-800";
  }

  alertEl.className = `fixed top-5 right-5 hidden w-80 p-4 rounded-lg shadow-lg ${bgColor} backdrop-blur transform transition-all duration-300 z-50 flex justify-between items-start`;
  titleEl.className = `text-lg font-semibold ${titleColor}`;

  // Show alert
  alertEl.classList.remove("hidden");
  alertEl.classList.add("opacity-100", "translate-x-0");

  // Auto-hide
  if (duration > 0) {
    setTimeout(() => closeAlert(), duration);
  }
}

function closeAlert() {
  const alertEl = document.getElementById("sync-alert");
  alertEl.classList.add("opacity-0", "translate-x-10");
  setTimeout(() => alertEl.classList.add("hidden"), 300);
}

// Close button
document.getElementById("sync-alert-close").addEventListener("click", closeAlert);