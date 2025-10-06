// Configure your import map in config/importmap.rb. Read more: https://github.com/rails/importmap-rails
import "@hotwired/turbo-rails"
import { runTroubleshooting } from "./troubleshooting";

document.addEventListener("DOMContentLoaded", () => {
  const troubleshootBtn = document.getElementById("troubleshoot_btn");
  if (troubleshootBtn) {
    troubleshootBtn.addEventListener("click", runTroubleshooting);
  }
});

