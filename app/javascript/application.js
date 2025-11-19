// Configure your import map in config/importmap.rb. Read more: https://github.com/rails/importmap-rails
import "channels"
import "@hotwired/turbo-rails"
import { Application } from "@hotwired/stimulus"
import PageController from "./controllers/page_controller"

import { fetchStats, autoRunTroubleshooting, runTestSync } from "./troubleshooting";

const application = Application.start()
application.register("page", PageController)


// Run on page load
document.addEventListener("DOMContentLoaded", () => {
   if (!window.IS_MASTER) {
    fetchStats(); // Populate Sync stats
    autoRunTroubleshooting(); // Run diagnostics
  }
});


document.getElementById("btn-test-sync").addEventListener("click", function() {
  // your code here
  runTestSync();
});

document.getElementById("rerun-diagnostics").addEventListener("click", function() {
  // your code here
  autoRunTroubleshooting();
});

