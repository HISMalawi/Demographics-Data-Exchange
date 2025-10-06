// Configure your import map in config/importmap.rb. Read more: https://github.com/rails/importmap-rails
import "@hotwired/turbo-rails"

import { troubleshootError } from "./troubleshooting.js";

document.addEventListener("DOMContentLoaded", () => {
  const troubleshootBtn = document.querySelector("#troubleshoot_btn");
  const form = document.querySelector("#troubleshoot_form");

  if (troubleshootBtn && form) {
    troubleshootBtn.addEventListener("click", () => {
      const selected = form.querySelector("input[name='error_type']:checked");
      if (!selected) {
        alert("Please select an error type before starting troubleshooting.");
        return;
      }
      troubleshootError(selected.value);
    });
  }

  // Clear selection button
  const clearBtn = document.querySelector("#clear_selection");
  if (clearBtn) {
    clearBtn.addEventListener("click", () => {
      form.reset();
      document.querySelector("#troubleshoot-output").innerHTML = `
        <p class="text-gray-500 italic">No result available.</p>
      `;
    });
  }
});
