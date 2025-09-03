document.addEventListener("DOMContentLoaded", () => {
  // Service Loader
  const serviceLoader = document.getElementById("service-loader");
  const serviceResultContainer = document.getElementById("service-result-container");

  document.querySelectorAll(".service-form").forEach(form => {
    form.addEventListener("submit", () => {
      serviceLoader.classList.remove("hidden");
      serviceResultContainer.innerHTML = "";
    });
  });

  document.addEventListener("ajax:success", (event) => {
    const [data] = event.detail;
    if (data && data.result) {
      const isError = data.status === "error";
      serviceResultContainer.innerHTML = `
        <div class="p-4 rounded-lg border ${isError ? "bg-red-50 border-red-300 text-red-700" : "bg-green-50 border-green-300 text-green-700"} shadow-sm">
          <strong>Result:</strong> <span class="whitespace-pre-line">${data.result}</span>
        </div>
      `;
    }
    serviceLoader.classList.add("hidden");
  });

  // Diagnostics, Stats, etc...
});