// Configure your import map in config/importmap.rb. Read more: https://github.com/rails/importmap-rails
import "channels"
import "@hotwired/turbo-rails"
import { Application } from "@hotwired/stimulus"
import PageController from "./controllers/page_controller"

import { fetchStats, autoRunTroubleshooting, runTestSync/** resetProgramCredentials**/ } from "./troubleshooting";

const application = Application.start()
application.register("page", PageController)


// Run on page load
document.addEventListener("DOMContentLoaded", () => {
  if (!window.IS_MASTER) {
    fetchStats(); // Populate Sync stats
    autoRunTroubleshooting(); // Run diagnostics
  }

  // Initialize reset modal listeners
  const resetCloseBtn = document.getElementById("reset-cred-close");
  if (resetCloseBtn) {
    resetCloseBtn.addEventListener("click", closeResetCredentialModal);
  }

  const resetForm = document.getElementById("reset-cred-form");
  if (resetForm) {
    resetForm.addEventListener("submit", async function(e) {
      e.preventDefault();
      
      const program = document.getElementById("reset-program").value;
      const username = document.getElementById("reset-username").value;
      const password = document.getElementById("reset-password").value;
      
      const resetBtn = document.getElementById("reset-save-btn");
      resetBtn.disabled = true;
      resetBtn.textContent = "Resetting...";
      
      try {
       // await resetProgramCredentials(program, username, password);
        //closeResetCredentialModal();
      } catch (error) {
        console.error("Error resetting credentials:", error);
      } finally {
        resetBtn.disabled = false;
        resetBtn.textContent = "Save & Reset";
      }
    });
  }
});


document.getElementById("btn-test-sync").addEventListener("click", function () {
  // your code here
  runTestSync();
});

document.getElementById("rerun-diagnostics").addEventListener("click", function () {
  // your code here
  autoRunTroubleshooting();
});

document.addEventListener("click", async function (e) {
  if (e.target.classList.contains("reset-cred-btn")) {
    const program = e.target.getAttribute("data-program");
    openResetCredentialModal(program);
  }
})

function openResetCredentialModal(program){
  const modal = document.getElementById("reset-cred-modal");
  const programInput = document.getElementById("reset-program");
  const usernameInput = document.getElementById("reset-username");
  const passwordInput = document.getElementById("reset-password");
  
  programInput.value = program;
  usernameInput.value = "";
  passwordInput.value = "";
  
  modal.classList.remove("hidden");
  modal.classList.add("flex");
}

function closeResetCredentialModal() {
  const modal = document.getElementById("reset-cred-modal");
  modal.classList.add("hidden");
  modal.classList.remove("flex");
}




