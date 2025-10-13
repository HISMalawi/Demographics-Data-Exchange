// app/javascript/troubleshooting.js

export async function autoRunTroubleshooting() {
  const outputDiv = document.getElementById("output");
  const statusText = document.getElementById("status_text");
  const statusIndicator = document.getElementById("status_indicator");

  if (!outputDiv) return;

  outputDiv.innerHTML = `<h3 class="text-xl font-semibold text-gray-800 mb-2">Diagnostics Output</h3>`;

  const checklist = [
    { name: "Unlock Sync Job", key: "unlock_sync_job" },
    { name: "Resolve Sync Configurations", key: "resolve_sync_configs" },
    { name: "Detect Footprint Conflicts", key: "detect_footprint_conflicts" },
  ];

  for (const item of checklist) {
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

      const colorClass =
        result.status === "ok"
          ? "bg-green-50 border-green-300 text-green-700"
          : "bg-red-50 border-red-300 text-red-700";

      const section = document.createElement("div");
      section.className = `p-4 mb-4 rounded-lg border ${colorClass} shadow-sm transition-all duration-300`;
      section.innerHTML = `
        <strong class="block mb-1">${item.name}</strong>
        <span class="whitespace-pre-line">${result.message || "No message"}</span>
      `;

      outputDiv.appendChild(section);
    } catch (error) {
      const errorDiv = document.createElement("div");
      errorDiv.className = "text-red-600 p-2 border border-red-200 rounded mb-2";
      errorDiv.textContent = `Error running ${item.name}: ${error}`;
      outputDiv.appendChild(errorDiv);
    }
  }

  statusIndicator?.classList.replace("bg-blue-500", "bg-gray-400");
  statusText.textContent = "All diagnostics completed";
}