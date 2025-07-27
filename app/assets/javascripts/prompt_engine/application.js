//= require_tree ./controllers

// Initialize all controllers when DOM is ready
document.addEventListener('DOMContentLoaded', function() {
  // Initialize API Key Switcher
  const apiKeySwitchers = document.querySelectorAll('[data-controller="api-key-switcher"]');
  apiKeySwitchers.forEach(element => {
    initApiKeySwitcher(element);
  });

  // Initialize Checkbox Limiter
  const checkboxLimiters = document.querySelectorAll('[data-controller="checkbox-limiter"]');
  checkboxLimiters.forEach(element => {
    initCheckboxLimiter(element);
  });

  // Initialize Config Toggler
  const configTogglers = document.querySelectorAll('[data-controller="config-toggler"]');
  configTogglers.forEach(element => {
    initConfigToggler(element);
  });

  // Initialize Slug Generator
  const slugGenerators = document.querySelectorAll('[data-controller="slug-generator"]');
  slugGenerators.forEach(element => {
    initSlugGenerator(element);
  });

  // Initialize Auto Refresh
  const autoRefreshes = document.querySelectorAll('[data-controller="auto-refresh"]');
  autoRefreshes.forEach(element => {
    initAutoRefresh(element);
  });
});