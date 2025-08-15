document.addEventListener('turbo:load', () => {
  console.log("Troubleshooting JS loaded");

  // Elements
  const errorSearch = document.getElementById('error_search');
  const searchResults = document.getElementById('search_results');
  const selectedError = document.getElementById('selected_error_type');
  const troubleshootBtn = document.getElementById('troubleshoot_btn');
  const clearSelection = document.getElementById('clear_selection');
  const stopProcessBtn = document.getElementById('stop_process');
  const outputContainer = document.getElementById('output_container');
  const outputContent = document.getElementById('output_content');
  const scrollToggle = document.getElementById('scroll_toggle');
  const clearOutput = document.getElementById('clear_output');

  if (!errorSearch || !searchResults) return; // page may not have the search input

  let autoScroll = true;

  // ===== Search Error Types =====
  errorSearch.addEventListener('input', () => {
    const query = errorSearch.value.toLowerCase();
    searchResults.innerHTML = '';

    if (!query) {
      searchResults.classList.add('hidden');
      troubleshootBtn.disabled = true;
      selectedError.value = '';
      return;
    }

    const matches = Object.keys(window.errorTypes || {}).filter(
      key => key.toLowerCase().includes(query)
    );

    if (matches.length === 0) {
      searchResults.classList.add('hidden');
      troubleshootBtn.disabled = true;
      selectedError.value = '';
      return;
    }

    matches.forEach(match => {
      const li = document.createElement('li');
      li.textContent = window.errorTypes[match];
      li.classList.add('px-3', 'py-2', 'cursor-pointer', 'hover:bg-gray-100');
      li.addEventListener('click', () => {
        errorSearch.value = li.textContent;
        selectedError.value = li.textContent;
        searchResults.classList.add('hidden');
        troubleshootBtn.disabled = false;
      });
      searchResults.appendChild(li);
    });

    searchResults.classList.remove('hidden');
  });

  // ===== Clear Selection =====
  clearSelection.addEventListener('click', () => {
    errorSearch.value = '';
    selectedError.value = '';
    searchResults.innerHTML = '';
    searchResults.classList.add('hidden');
    troubleshootBtn.disabled = true;
  });

  // ===== Stop Process =====
  stopProcessBtn.addEventListener('click', () => {
    appendOutput('Process stopped by user.');
    stopProcessBtn.classList.add('hidden');
    troubleshootBtn.disabled = false;
  });

  // ===== Output Display =====
  function appendOutput(text) {
    const div = document.createElement('div');
    div.textContent = text;
    outputContent.appendChild(div);
    if (autoScroll) {
      outputContainer.scrollTop = outputContainer.scrollHeight;
    }
  }

  // ===== Clear Output =====
  if (clearOutput) {
    clearOutput.addEventListener('click', () => {
      outputContent.innerHTML = '';
    });
  }

  // ===== Auto-scroll Toggle =====
  if (scrollToggle) {
    scrollToggle.addEventListener('click', () => {
      autoScroll = !autoScroll;
      scrollToggle.textContent = `Auto-scroll: ${autoScroll ? 'ON' : 'OFF'}`;
    });
  }

});
