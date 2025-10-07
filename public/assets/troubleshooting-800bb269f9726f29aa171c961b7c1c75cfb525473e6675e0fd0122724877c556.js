function runTroubleshooting() {
  // pick a default error type, e.g., first option
  const defaultErrorType = "resolve_sync_configs";

  fetch("/api/v1/troubleshooting/troubleshoot", {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      "X-CSRF-Token": document.querySelector("meta[name='csrf-token']").content
    },
    body: JSON.stringify({ error_type: defaultErrorType, context: "diagnostics" })
  })
  .then(response => response.json())
  .then(data => {
    const outputDiv = document.getElementById("troubleshoot_output");
    if (!outputDiv) return;
    
    // simple result rendering
    let resultClass = data.status === "error" ? "bg-red-50 border-red-300 text-red-700" : "bg-green-50 border-green-300 text-green-700";

    outputDiv.innerHTML = `
      <div class="p-4 rounded-lg border ${resultClass} shadow-sm">
        <strong class="block mb-1">Result:</strong>
        <span class="whitespace-pre-line">${data.message || data.status}</span>
      </div>
    `;

    // extra forms for auth_failed or footprint conflicts
    if (data.status === "auth_failed") {
      const formDiv = document.createElement("div");
      formDiv.innerHTML = document.getElementById("reset_sync_form_template").innerHTML;
      outputDiv.appendChild(formDiv);
    } else if (data.message?.includes("foot_prints belonging to more than")) {
      const formDiv = document.createElement("div");
      formDiv.innerHTML = document.getElementById("reset_location_form_template").innerHTML;
      outputDiv.appendChild(formDiv);
    }
  });
};
