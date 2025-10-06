export async function troubleshootError(errorType) {
  const outputDiv = document.querySelector("#troubleshoot-output");
  if (!outputDiv) {
    console.error("⚠️ troubleshoot-output element not found.");
    return;
  }

  const statusText = document.querySelector("#status_text");
  const statusIndicator = document.querySelector("#status_indicator");

  statusIndicator.classList.remove("bg-green-500", "bg-red-500");
  statusIndicator.classList.add("bg-yellow-400");
  statusText.textContent = "Troubleshooting...";

  try {
    const response = await fetch("/api/v1/troubleshooting/troubleshoot", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ error_type: errorType }),
    });

    const result = await response.json();
    console.log("Troubleshooting result:", result);

    let html = `
      <div class="p-4 rounded-lg border ${
        result.status === "error" || result.status === "auth_failed"
          ? "bg-red-50 border-red-300 text-red-700"
          : "bg-green-50 border-green-300 text-green-700"
      }">
        <strong class="block mb-1">Result:</strong>
        <span class="whitespace-pre-line">${result.message || "No message"}</span>
      </div>
    `;

    //
    // ✅ Handle AUTH FAILED (Reset Sync Configs)
    //
    if (result.status === "auth_failed") {
      html += `
        <div class="mt-4 border-t border-gray-200 pt-4">
          <h4 class="text-gray-800 font-medium mb-2">Reset Sync Configs</h4>
          <div class="space-y-3">
            <input 
              type="text" 
              id="sync_username" 
              placeholder="Username" 
              class="border border-gray-300 rounded-lg px-3 py-2 w-full focus:ring focus:ring-blue-200 focus:border-blue-500"
            />
            <input 
              type="password" 
              id="sync_password" 
              placeholder="Password" 
              class="border border-gray-300 rounded-lg px-3 py-2 w-full focus:ring focus:ring-blue-200 focus:border-blue-500"
            />
            <button 
              id="reset_sync_btn"
              class="bg-blue-600 hover:bg-blue-700 text-white px-4 py-2 rounded-lg font-medium"
            >
              Reset Sync Configs
            </button>
            <div id="reset_sync_status" class="text-sm text-gray-500 mt-2"></div>
          </div>
        </div>
      `;
    }

    //
    // ✅ Handle FOOTPRINT CONFLICTS (Reset Location)
    //
    if (result.message?.includes("foot_prints belonging to more than")) {
      html += `
        <div class="mt-4 border-t border-gray-200 pt-4">
          <h4 class="text-gray-800 font-medium mb-2">Reset Footprint Location</h4>
          <div class="flex items-center gap-3">
            <input 
              type="text" 
              id="location_id_input" 
              placeholder="Enter location_id" 
              class="border border-gray-300 rounded-lg px-3 py-2 flex-grow focus:ring focus:ring-blue-200 focus:border-blue-500"
            />
            <button 
              id="reset_location_btn"
              class="bg-blue-600 hover:bg-blue-700 text-white px-4 py-2 rounded-lg font-medium"
            >
              Reset Location
            </button>
          </div>
          <div id="reset_status" class="text-sm text-gray-500 mt-2"></div>
        </div>
      `;
    }

    outputDiv.innerHTML = html;

    //
    // ✅ Hook up Reset Sync Configs button
    //
    const resetSyncBtn = document.querySelector("#reset_sync_btn");
    if (resetSyncBtn) {
      resetSyncBtn.addEventListener("click", async () => {
        const username = document.querySelector("#sync_username").value.trim();
        const password = document.querySelector("#sync_password").value.trim();
        const resetStatus = document.querySelector("#reset_sync_status");

        if (!username || !password) {
          resetStatus.textContent = "Please enter both username and password.";
          resetStatus.className = "text-red-600 text-sm mt-1";
          return;
        }

        resetStatus.textContent = "Resetting sync configs...";
        resetStatus.className = "text-gray-600 text-sm mt-1";

        try {
          const resetResponse = await fetch("/api/v1/troubleshooting/reset_sync_credentials", {
            method: "POST",
            headers: { "Content-Type": "application/json" },
            body: JSON.stringify({ username, password }),
          });

          const resetResult = await resetResponse.json();
          resetStatus.textContent = resetResult.message || "Sync reset complete.";
          resetStatus.className = "text-green-700 text-sm mt-1";
        } catch (e) {
          resetStatus.textContent = "Error resetting sync configs.";
          resetStatus.className = "text-red-600 text-sm mt-1";
        }
      });
    }

    //
    // ✅ Hook up Reset Location button
    //
    const resetBtn = document.querySelector("#reset_location_btn");
    if (resetBtn) {
      resetBtn.addEventListener("click", async () => {
        const locationId = document.querySelector("#location_id_input").value.trim();
        const resetStatus = document.querySelector("#reset_status");

        if (!locationId) {
          resetStatus.textContent = "Please enter a location ID.";
          resetStatus.className = "text-red-600 text-sm mt-1";
          return;
        }

        resetStatus.textContent = "Resetting location...";
        resetStatus.className = "text-gray-600 text-sm mt-1";

        try {
          const resetResponse = await fetch("/api/v1/troubleshooting/reset_foot_prints_location_id", {
            method: "POST",
            headers: { "Content-Type": "application/json" },
            body: JSON.stringify({ location_id: locationId }),
          });

          const resetResult = await resetResponse.json();
          resetStatus.textContent = resetResult.message || "Location reset complete.";
          resetStatus.className = "text-green-700 text-sm mt-1";
        } catch (e) {
          resetStatus.textContent = "Error resetting location.";
          resetStatus.className = "text-red-600 text-sm mt-1";
        }
      });
    }

    //
    // ✅ Update status indicator
    //
    if (result.status === "ok") {
      statusIndicator.classList.remove("bg-yellow-400");
      statusIndicator.classList.add("bg-green-500");
      statusText.textContent = "Troubleshooting completed successfully.";
    } else {
      statusIndicator.classList.remove("bg-yellow-400");
      statusIndicator.classList.add("bg-red-500");
      statusText.textContent = `Issue detected: ${result.status}`;
    }
  } catch (error) {
    console.error("Troubleshooting failed:", error);
    outputDiv.innerHTML = `
      <div class="p-4 rounded-lg border bg-red-50 border-red-300 text-red-700">
        <strong>Error:</strong> ${error.message}
      </div>`;
    statusIndicator.classList.remove("bg-yellow-400");
    statusIndicator.classList.add("bg-red-500");
    statusText.textContent = "Troubleshooting failed.";
  }
}