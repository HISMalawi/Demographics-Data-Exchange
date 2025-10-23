// Configure your import map in config/importmap.rb. Read more: https://github.com/rails/importmap-rails
import "@hotwired/turbo-rails"
import { Application } from "@hotwired/stimulus"
import PageController from "./controllers/page_controller"

import { fetchStats, autoRunTroubleshooting, runTestSync } from "./troubleshooting";

const application = Application.start()
application.register("page", PageController)


// Run on page load
document.addEventListener("DOMContentLoaded", () => {
  fetchStats() // Populate Sync stats
  autoRunTroubleshooting(); // Run diagonistics
});


document.getElementById("btn-test-sync").addEventListener("click", function() {
  // your code here
  runTestSync();
});

document.getElementById("rerun-diagnostics").addEventListener("click", function() {
  // your code here
  autoRunTroubleshooting();
});

