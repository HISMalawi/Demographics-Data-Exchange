// Configure your import map in config/importmap.rb. Read more: https://github.com/rails/importmap-rails
import "@hotwired/turbo-rails"
import { runManage } from "services"

document.addEventListener("DOMContentLoaded", () => {
  const btn = document.getElementById("load-tasks")
  if (btn) {
    console.log("Button found, attaching event")
    btn.addEventListener("click", runManage)
  } else {
    console.log("No button found")
  }
});

console.log("Hahah Something");
