// Configure your import map in config/importmap.rb. Read more: https://github.com/rails/importmap-rails
import "@hotwired/turbo-rails"
import { Application } from "@hotwired/stimulus"
import PageController from "./controllers/page_controller"

import { autoRunTroubleshooting } from "./troubleshooting";

import "./footprint_stats"

const application = Application.start()
application.register("page", PageController)


// Run on page load
document.addEventListener("DOMContentLoaded", () => {
  autoRunTroubleshooting();
});

