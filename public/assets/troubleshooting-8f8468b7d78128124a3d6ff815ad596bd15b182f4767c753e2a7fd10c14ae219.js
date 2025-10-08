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
      section.className = `p-4 mb-4 rounded-lg border ${colorClass} shadow-sm transition-all duration-500 hover:shadow-md`;
      section.innerHTML = `
        <strong class="block mb-1 capitalize">${type.replaceAll("_", " ")}</strong>
        <span class="whitespace-pre-line">${result.message || "No message"}</span>
      `;

      // ✅ If authentication failed, show Reset Sync User button
      if (result.status === "auth_failed") {
        const resetButton = document.createElement("button");
        resetButton.textContent = "Reset Sync User";
        resetButton.className =
          "mt-3 inline-flex items-center gap-2 bg-red-600 hover:bg-red-700 text-white text-sm font-medium px-4 py-2 rounded-lg shadow transition-all duration-300 hover:scale-105 active:scale-95";
        resetButton.onclick = async () => {
          resetButton.disabled = true;
          resetButton.textContent = "Resetting...";
          try {
            const resetResponse = await fetch("/api/v1/troubleshooting/reset_sync_user", {
              method: "POST",
              headers: { "Accept": "application/json" },
            });
            const resetResult = await resetResponse.json();
            alert(resetResult.message || "Sync user has been reset successfully!");
          } catch (err) {
            alert("Failed to reset sync user: " + err);
          } finally {
            resetButton.disabled = false;
            resetButton.textContent = "Reset Sync User";
          }
        };
        section.appendChild(resetButton);
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
};
