// app/javascript/troubleshooting.js

export async function autoRunTroubleshooting() {
  const outputDiv = document.getElementById("output");
  const statusText = document.getElementById("status_text");
  const statusIndicator = document.getElementById("status_indicator");

  if (!outputDiv) return;

  // Clear old output
  outputDiv.innerHTML = `<h3 class="text-xl font-semibold text-gray-800 mb-2">Diagnostics Output</h3>`;

  const errorTypes = [
    "resolve_sync_configs",
    "detect_footprint_conflicts",
  ];

  for (const type of errorTypes) {
    statusIndicator?.classList.replace("bg-gray-400", "bg-blue-500");
    statusText.textContent = `Running ${type}...`;

    try {
      const response = await fetch("/api/v1/troubleshooting/troubleshoot", {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "Accept": "application/json",
        },
        body: JSON.stringify({ error_type: type }),
      });

      const result = await response.json();

      let colorClass =
        result.status === "ok"
          ? "bg-green-50 border-green-300 text-green-700"
          : "bg-red-50 border-red-300 text-red-700";

      const section = document.createElement("div");
      section.className = `p-4 mb-4 rounded-lg border ${colorClass} shadow-sm transition-all duration-300`;
      section.innerHTML = `
        <strong class="block mb-1">${type}</strong>
        <span class="whitespace-pre-line">${result.message || "No message"}</span>
      `;

      // If auth_failed, add clickable link to reset sync credentials
      if (result.status === "auth_failed") {
        const resetLink = document.createElement("a");
        resetLink.href = "#";
        resetLink.textContent = "Reset Sync Credentials";
        resetLink.className = "text-blue-600 hover:text-blue-800 mt-2 inline-block cursor-pointer";
        resetLink.addEventListener("click", (e) => {
          e.preventDefault();
          showResetSyncForm(section);
        });
        section.appendChild(resetLink);
      }

      outputDiv.appendChild(section);
    } catch (error) {
      const errorDiv = document.createElement("div");
      errorDiv.className = "text-red-600 p-2 border border-red-200 rounded mb-2";
      errorDiv.textContent = `Error running ${type}: ${error}`;
      outputDiv.appendChild(errorDiv);
    }
  }

  statusIndicator?.classList.replace("bg-blue-500", "bg-gray-400");
  statusText.textContent = "All diagnostics completed";
}

// --- Helper functions ---

function showResetSyncForm(container) {
  if (container.querySelector(".reset-sync-form")) return;

  const formDiv = document.createElement("div");
  formDiv.className = "reset-sync-form mt-2 p-4 border border-gray-300 rounded bg-gray-50 flex flex-col gap-2 animate-slideDown";

  formDiv.innerHTML = `
    <input type="text" placeholder="New Username" id="sync_username" class="p-2 border border-gray-300 rounded" />
    <input type="password" placeholder="New Password" id="sync_password" class="p-2 border border-gray-300 rounded" />
    <div class="flex gap-2">
      <a href="#" id="save_sync_credentials" class="text-white bg-blue-600 hover:bg-blue-700 text-center py-1 px-3 rounded cursor-pointer">Save Credentials</a>
      <a href="#" id="cancel_sync_credentials" class="text-gray-700 bg-gray-200 hover:bg-gray-300 text-center py-1 px-3 rounded cursor-pointer">Cancel</a>
    </div>
    <div id="sync_alert" class="mt-2 hidden"></div>
  `;

  container.appendChild(formDiv);

  const saveLink = formDiv.querySelector("#save_sync_credentials");
  saveLink.addEventListener("click", (e) => {
    e.preventDefault();
    const newUsername = document.getElementById("sync_username").value;
    const newPassword = document.getElementById("sync_password").value;
    resetSyncUser(newUsername, newPassword, container, formDiv);
  });

  const cancelLink = formDiv.querySelector("#cancel_sync_credentials");
  cancelLink.addEventListener("click", (e) => {
    e.preventDefault();
    formDiv.remove(); // hide form but keep messages
  });
}

async function resetSyncUser(username, password, container, formDiv) {
  const alertDiv = formDiv.querySelector("#sync_alert");
  alertDiv.classList.remove("hidden");
  alertDiv.textContent = "Saving...";
  alertDiv.className = "mt-2 p-2 border border-gray-300 rounded bg-yellow-50 text-yellow-800";

  try {
    const response = await fetch("/api/v1/troubleshooting/reset_sync_credentials", {
      method: "POST",
      headers: { "Content-Type": "application/json", "Accept": "application/json" },
      body: JSON.stringify({ username, password }),
    });

    const result = await response.json();

    if (result.status === "ok") {
      alertDiv.textContent = "Sync credentials updated successfully!";
      alertDiv.className = "mt-2 p-2 border border-green-300 rounded bg-green-50 text-green-700";
      formDiv.remove(); // hide form after success
    } else {
      alertDiv.textContent = `Error: ${result.message || "Could not update credentials"}`;
      alertDiv.className = "mt-2 p-2 border border-red-300 rounded bg-red-50 text-red-700";
    }
  } catch (error) {
    alertDiv.textContent = `Error: ${error}`;
    alertDiv.className = "mt-2 p-2 border border-red-300 rounded bg-red-50 text-red-700";
  }
};
