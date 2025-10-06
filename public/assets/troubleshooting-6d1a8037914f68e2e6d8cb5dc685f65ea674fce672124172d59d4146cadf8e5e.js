// export function to fetch troubleshooting results
export function runTroubleshooting() {
  const form = document.getElementById("troubleshoot_form");
  const statusIndicator = document.getElementById("status_indicator");
  const statusText = document.getElementById("status_text");

  console.log("Someone has been clicked ")

  if (!form) return;

  const selectedError = form.querySelector('input[name="error_type"]:checked');
  if (!selectedError) {
    alert("Please select an error type first");
    return;
  }

  const errorType = selectedError.value;

  // show loading
  statusIndicator.classList.remove("bg-gray-400", "bg-red-500", "bg-green-500");
  statusIndicator.classList.add("bg-yellow-500");
  statusText.textContent = "Running troubleshooting...";

  fetch(form.action, {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      "Accept": "application/json",
      "X-CSRF-Token": document.querySelector('meta[name="csrf-token"]').getAttribute('content')
    },
    body: JSON.stringify({ error_type: errorType })
  })
    .then(response => {
      if (!response.ok) throw new Error(`HTTP error! status: ${response.status}`);
      return response.json();
    })
    .then(data => {
      console.log("Troubleshooting result:", data);

      if (data.status === "success") {
        statusIndicator.classList.remove("bg-yellow-500");
        statusIndicator.classList.add("bg-green-500");
        statusText.textContent = `Success: ${data.message}`;
      } else {
        statusIndicator.classList.remove("bg-yellow-500");
        statusIndicator.classList.add("bg-red-500");
        statusText.textContent = `Error: ${data.message}`;
      }
    })
    .catch(err => {
      console.error("Troubleshooting failed:", err);
      statusIndicator.classList.remove("bg-yellow-500");
      statusIndicator.classList.add("bg-red-500");
      statusText.textContent = "An unexpected error occurred";
    });
};
