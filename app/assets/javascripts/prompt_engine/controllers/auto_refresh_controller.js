function initAutoRefresh(element) {
  const interval = parseInt(element.dataset.autoRefreshIntervalValue || '5000');
  
  const refreshTimer = setTimeout(() => {
    location.reload();
  }, interval);
  
  // Store timer reference on element for potential cleanup
  element._refreshTimer = refreshTimer;
}