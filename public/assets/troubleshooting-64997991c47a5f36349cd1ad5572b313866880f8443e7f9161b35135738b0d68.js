// app/javascript/troubleshooting.js

export async function autoRunTroubleshooting() {
  const outputDiv = document.getElementById("output");
  const statusText = document.getElementById("status_text");
  const statusIndicator = document.getElementById("status_indicator");

  if (!outputDiv) return; // Only run if the output div exists

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
      section.className = `p-4 mb-4 rounded-lg border ${colorClass} shadow-sm`;
      section.innerHTML = `
        <strong class="block mb-1">${type}</strong>
        <span class="whitespace-pre-line">${result.message || "No message"}</span>
      `;

      // If auth failed, add a "Reset Sync User" link
      if (result.status === "auth_failed") {
        const resetLink = document.createElement("a");
        resetLink.href = "#";
        resetLink.textContent = "Reset Sync User";
        resetLink.className = "inline-block mt-2 text-blue-600 hover:text-blue-800 underline";

        resetLink.addEventListener("click", (e) => {
          e.preventDefault();
          showResetSyncForm(section);
        });

        section.appendChild(resetLink);
      }

      outputDiv.appendChild(section);
    } catch (error) {
      const errorDiv = document.createElement("div");
      errorDiv.className = "text-red-600";
      errorDiv.textContent = `Error running ${type}: ${error}`;
      outputDiv.appendChild(errorDiv);
    }
  }

  statusIndicator?.classList.replace("bg-blue-500", "bg-gray-400");
  statusText.textContent = "All diagnostics completed";
}

// Dynamically show username/password fields to reset sync credentials
function showResetSyncForm(container) {
  if (container.querySelector(".reset-sync-form")) return; // prevent duplicates

  const formDiv = document.createElement("div");
  formDiv.className = "reset-sync-form mt-2 p-4 border border-gray-300 rounded bg-gray-50 flex flex-col gap-2";

  formDiv.innerHTML = `
    <input type="text" placeholder="New Username" id="sync_username" class="p-2 border border-gray-300 rounded" />
    <input type="password" placeholder="New Password" id="sync_password" class="p-2 border border-gray-300 rounded" />
    <a href="#" id="save_sync_credentials" class="text-white bg-blue-600 hover:bg-blue-700 text-center py-1 rounded cursor-pointer">Save Credentials</a>
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
}

// Tailwind alert creator
function showTailwindAlert(container, message, type = "success") {
  const alertDiv = container.querySelector("#sync_alert");
  if (!alertDiv) return;

  let baseClasses = "p-2 rounded border text-sm";
  let typeClasses =
    type === "success"
      ? "bg-green-50 border-green-400 text-green-800"
      : "bg-red-50 border-red-400 text-red-800";

  alertDiv.className = `${baseClasses} ${typeClasses} mt-2`;
  alertDiv.textContent = message;
  alertDiv.classList.remove("hidden");
}

// Example reset function (replace with your actual Rails endpoint)
function resetSyncUser(username, password, container, formDiv) {
  if (!username || !password) {
    showTailwindAlert(container, "Please enter both username and password", "error");
    return;
  }

  fetch("/api/v1/troubleshooting/reset_sync_user", {
    method: "POST",
    headers: { "Content-Type": "application/json", "Accept": "application/json" },
    body: JSON.stringify({ username, password }),
  })
    .then((res) => res.json())
    .then((data) => {
      showTailwindAlert(container, data.message || "Sync user reset successfully", "success");
      // Optionally remove form after success
      setTimeout(() => formDiv.remove(), 2500);
    })
    .catch((err) => {
      console.error(err);
      showTailwindAlert(container, "Failed to reset sync user", "error");
    });
};
