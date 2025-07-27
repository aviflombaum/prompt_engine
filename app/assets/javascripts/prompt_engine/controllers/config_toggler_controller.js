function initConfigToggler(element) {
  const configMapping = JSON.parse(element.dataset.configTogglerConfigMappingValue || '{}');
  
  const selector = element.querySelector('[data-config-toggler-target="selector"]');
  const configSections = element.querySelectorAll('[data-config-toggler-target="configSection"]');
  
  if (!selector) return;
  
  function toggle() {
    const selectedValue = selector.value;
    
    // Hide all config sections first
    configSections.forEach(section => {
      section.style.display = 'none';
    });
    
    // Show the appropriate section based on the mapping
    if (configMapping[selectedValue]) {
      const targetIds = configMapping[selectedValue];
      const idsArray = Array.isArray(targetIds) ? targetIds : [targetIds];
      
      idsArray.forEach(id => {
        const section = Array.from(configSections).find(s => s.id === id);
        if (section) {
          section.style.display = 'block';
        }
      });
    }
  }
  
  // Initial state
  toggle();
  
  // Listen for changes
  selector.addEventListener('change', toggle);
}