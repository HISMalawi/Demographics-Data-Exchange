// manage.js

function runManage(service, action) {
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

// Test call
runManage("dde4_sidekiq", "status");