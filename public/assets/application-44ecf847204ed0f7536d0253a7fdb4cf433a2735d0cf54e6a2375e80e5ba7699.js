// Configure your import map in config/importmap.rb. Read more: https://github.com/rails/importmap-rails
import "@hotwired/turbo-rails"

import { autoRunTroubleshooting } from "./troubleshooting";

// Run automatically when the page loads
document.addEventListener("DOMContentLoaded", () => {
  autoRunTroubleshooting();
});
