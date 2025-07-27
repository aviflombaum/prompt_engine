function initApiKeySwitcher(element) {
  const anthropicKey = element.dataset.apiKeySwitcherAnthropicKeyValue;
  const openaiKey = element.dataset.apiKeySwitcherOpenaiKeyValue;
  const editSettingsPath = element.dataset.apiKeySwitcherEditSettingsPathValue;
  
  const selector = element.querySelector('[data-action*="api-key-switcher#updateApiKey"]');
  const apiKeyField = element.querySelector('[data-api-key-switcher-target="apiKeyField"]');
  const helpText = element.querySelector('[data-api-key-switcher-target="helpText"]');
  
  if (!selector || !apiKeyField || !helpText) return;
  
  function updateApiKey() {
    const selectedProvider = selector.value;
    
    if (selectedProvider === 'anthropic' && anthropicKey) {
      apiKeyField.value = anthropicKey;
      apiKeyField.placeholder = 'Using saved API key';
      helpText.innerHTML = `Using saved API key from settings. <a href="${editSettingsPath}" class="link">Change in settings</a>`;
    } else if (selectedProvider === 'openai' && openaiKey) {
      apiKeyField.value = openaiKey;
      apiKeyField.placeholder = 'Using saved API key';
      helpText.innerHTML = `Using saved API key from settings. <a href="${editSettingsPath}" class="link">Change in settings</a>`;
    } else {
      apiKeyField.value = '';
      apiKeyField.placeholder = 'Enter your API key';
      helpText.innerHTML = `Your API key will not be stored. <a href="${editSettingsPath}" class="link">Save in settings</a>`;
    }
  }
  
  // Initial update
  updateApiKey();
  
  // Listen for changes
  selector.addEventListener('change', updateApiKey);
}