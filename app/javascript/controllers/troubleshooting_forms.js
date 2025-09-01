document.addEventListener('turbo:load', function() {
  // Reset Sync Form
  const syncForm = document.getElementById('reset_sync_form');
  const syncStatus = document.getElementById('reset_status');
  if (syncForm) {
    syncForm.addEventListener('ajax:success', (event) => {
      const [data] = event.detail;
      syncStatus.textContent = data.message;
      syncStatus.className = data.status === "success" ? "text-green-700" : "text-red-700";
    });

    syncForm.addEventListener('ajax:error', () => {
      syncStatus.textContent = "An error occurred while updating credentials.";
      syncStatus.className = "text-red-700";
    });
  }

  // Reset Location Form
  const locationForm = document.getElementById('reset_location_form');
  const locationStatus = document.getElementById('reset_location_status');
  if (locationForm) {
    locationForm.addEventListener('ajax:success', (event) => {
      const [data] = event.detail;
      locationStatus.textContent = data.message;
      locationStatus.className = data.status === "success" ? "text-green-700" : "text-red-700";
    });

    locationForm.addEventListener('ajax:error', () => {
      locationStatus.textContent = "An error occurred while resetting location ID.";
      locationStatus.className = "text-red-700";
    });
  }
});