/*export function loadTasks() {
  fetch("/services.json")
    .then(response => response.json())
    .then(data => {
      const list = document.getElementById("tasks-list")
      list.innerHTML = "" // clear old
      data.forEach(task => {
        const li = document.createElement("li")
        li.textContent = `${task.name} - ${task.done ? "✅" : "❌"}`
        console.log(`${task.name} - ${task.done ? "✅" : "❌"}`)
        list.appendChild(li)
      })
    })
    .catch(error => console.error("Error loading tasks:", error))
}*

/*console.log("Loaded services file");*/ 

export function runManage(service, action) {
  fetch(`/api/v1/services/manage_services`, {
    method: "POST",
    headers: {
      "Accept": "application/json",
      "Content-Type": "application/json",
      "X-CSRF-Token": document.querySelector('meta[name="csrf-token"]').getAttribute('content')
    },
    body: JSON.stringify({ service: service, action_name: action, context: "services" })
  })
  .then(res => {
    if (!res.ok) throw new Error(`HTTP error! status: ${res.status}`);
    return res.json();
  })
  .then(data => {
    console.log("Controller response test:");
    console.log("Output:", data.output);
    console.log("Status:", data.status);
    console.log("Status value:", data.status_value);
  })
  .catch(err => console.error("Error:", err));
}

document.addEventListener("DOMContentLoaded", () => {
  const serviceLoader = document.getElementById("service-loader");
  const serviceResultContainer = document.getElementById("service-result-container");

  document.querySelectorAll(".service-form").forEach(form => {
    form.addEventListener("submit", () => {
      serviceLoader.classList.remove("hidden");
      serviceResultContainer.innerHTML = ""; // Clear previous result
    });

    // Success event from Rails UJS
    form.addEventListener("ajax:success", (event) => {
      const [data] = event.detail;
      const service = form.querySelector('input[name="service"]').value;
      const action = form.querySelector('input[name="action_name"]').value;

      // Update the result container
      if (data && data.result) {
        const isError = data.status === "error";
        serviceResultContainer.innerHTML = `
          <div class="p-4 rounded-lg border ${isError ? "bg-red-50 border-red-300 text-red-700" : "bg-green-50 border-green-300 text-green-700"} shadow-sm">
            <strong>Result:</strong> <span class="whitespace-pre-line">${data.result}</span>
          </div>
        `;
      }

      // Update the status cell for this row
      const row = document.querySelector(`tr[data-service="${service}"]`);
      if (row) {
        const statusCell = row.querySelector(".status-cell");
        let statusHtml = `<span class="flex items-center gap-2 text-gray-500 font-medium"><span class="w-2 h-2 rounded-full bg-gray-400"></span> Unknown</span>`;
        
        if (data.status_value) {
          let textColor = "text-gray-500";
          let dotColor = "bg-gray-400";
          let text = "Unknown";

          if (data.status_value === "running") {
            textColor = "text-green-600";
            dotColor = "bg-green-500";
            text = "Running";
          } else if (data.status_value === "stopped") {
            textColor = "text-red-600";
            dotColor = "bg-red-500";
            text = "Not Running";
          }

          statusHtml = `<span class="flex items-center gap-2 ${textColor} font-medium">
                          <span class="w-2 h-2 rounded-full ${dotColor}"></span> ${text}
                        </span>`;
        }

        statusCell.innerHTML = statusHtml;
      }

      serviceLoader.classList.add("hidden");
    });

    // Error event
    form.addEventListener("ajax:error", (event) => {
      serviceResultContainer.innerHTML = `
        <div class="p-4 rounded-lg border bg-red-50 border-red-300 text-red-700 shadow-sm">
          <strong>Error:</strong> Could not process the request.
        </div>
      `;
      serviceLoader.classList.add("hidden");
    });
  });
});


