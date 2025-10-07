export async function autoRunTroubleshooting() {
  const outputDiv = document.getElementById("output");
  const statusText = document.getElementById("status_text");
  const statusIndicator = document.getElementById("status_indicator");

  if (!outputDiv) return; // Only run if the output div exists

  // Clear old output
  outputDiv.innerHTML = `<h3 class="text-xl font-semibold text-gray-800 mb-2">Diagnostics Output</h3>`;

  const errorTypes = [
    "resolve_program_users_configs",
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
};
