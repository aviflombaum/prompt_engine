function initCheckboxLimiter(element) {
  const maxValue = parseInt(element.dataset.checkboxLimiterMaxValue || '2');
  const buttonText = element.dataset.checkboxLimiterButtonTextValue || 'Compare Selected';
  
  const checkboxes = element.querySelectorAll('[data-checkbox-limiter-target="checkbox"]');
  const submitButton = element.querySelector('[data-checkbox-limiter-target="submitButton"]');
  
  function updateButton() {
    const checkedBoxes = Array.from(checkboxes).filter(checkbox => checkbox.checked);
    const count = checkedBoxes.length;
    
    if (submitButton) {
      submitButton.disabled = count !== maxValue;
      submitButton.textContent = `${buttonText} (${count}/${maxValue})`;
    }
    
    // Disable unchecked checkboxes if max are already selected
    checkboxes.forEach(checkbox => {
      if (!checkbox.checked && count === maxValue) {
        checkbox.disabled = true;
      } else {
        checkbox.disabled = false;
      }
    });
  }
  
  // Initial state
  updateButton();
  
  // Add event listeners
  checkboxes.forEach(checkbox => {
    checkbox.addEventListener('change', updateButton);
  });
}