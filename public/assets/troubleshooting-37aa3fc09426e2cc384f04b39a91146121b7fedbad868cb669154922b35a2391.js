export async function troubleshootError(errorType) {
  const outputDiv = document.querySelector("#troubleshoot-output");
  const statusIndicator = document.querySelector("#status_indicator");
  const statusText = document.querySelector("#status_text");

  outputDiv.innerHTML = `
    <div class="text-gray-500 italic">Running diagnostics...</div>
  `;
  statusIndicator.classList.replace("bg-gray-400", "bg-blue-500");
  statusText.textContent = "Troubleshooting in progress...";

  try {
    const response = await fetch("/api/v1/troubleshooting/troubleshoot", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ error_type: errorType }),
    });

    const data = await response.json();
    console.log("Troubleshooting result:", data);

    // Handle result display dynamically
    let bgClass, borderClass, textClass, extraContent = "";

    if (data.status === "error" || data.status === "auth_failed") {
      bgClass = "bg-red-50"; borderClass = "border-red-300"; textClass = "text-red-700";
    } else {
      bgClass = "bg-green-50"; borderClass = "border-green-300"; textClass = "text-green-700";
    }

    // Conditional extra render logic
    if (data.status === "auth_failed") {
      extraContent = `
        <div class="mt-4 p-3 border border-yellow-300 bg-yellow-50 text-yellow-700 rounded-lg">
          Authentication failed. Please reset sync credentials.
          <button id="resetSyncBtn" class="ml-2 px-3 py-1 bg-yellow-600 text-white rounded-lg">Reset Sync</button>
        </div>
      `;
    } else if (data.message.includes("foot_prints belonging to more than")) {
      extraContent = `
        <div class="mt-4 p-3 border border-orange-300 bg-orange-50 text-orange-700 rounded-lg">
          ${data.message} — consider resetting location configuration.
          <button id="resetLocationBtn" class="ml-2 px-3 py-1 bg-orange-600 text-white rounded-lg">Reset Location</button>
        </div>
      `;
    }

    outputDiv.innerHTML = `
      <div class="p-4 rounded-lg border ${bgClass} ${borderClass} ${textClass} shadow-sm">
        <strong class="block mb-1">Result:</strong>
        <span class="whitespace-pre-line">${data.message}</span>
        ${extraContent}
      </div>
    `;

    // Update indicator
    statusIndicator.classList.replace("bg-blue-500", "bg-green-500");
    statusText.textContent = "Troubleshooting complete";

  } catch (error) {
    console.error("Error:", error);
    outputDiv.innerHTML = `
      <div class="p-4 rounded-lg border bg-red-50 border-red-300 text-red-700 shadow-sm">
        <strong class="block mb-1">Error:</strong>
        <span>${error.message}</span>
      </div>
    `;
    statusIndicator.classList.replace("bg-blue-500", "bg-red-500");
    statusText.textContent = "Troubleshooting failed";
  }
};
