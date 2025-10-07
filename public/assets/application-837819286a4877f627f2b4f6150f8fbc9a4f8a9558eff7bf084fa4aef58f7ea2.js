// Configure your import map in config/importmap.rb. Read more: https://github.com/rails/importmap-rails
import "@hotwired/turbo-rails"

import { runTroubleshooting } from "./troubleshooting";

// Run on page load
document.addEventListener("DOMContentLoaded", () => {
  runTroubleshooting();
});

// Re-run diagnostics when clicking the Services link
const servicesLink = document.querySelector('a[href="/api/v1/services"]');

if (servicesLink) {
  servicesLink.addEventListener("click", (e) => {
    // Wait a short delay to ensure the page content loads
    setTimeout(() => {
     runTroubleshooting();
    }, 100); 
  });
};
