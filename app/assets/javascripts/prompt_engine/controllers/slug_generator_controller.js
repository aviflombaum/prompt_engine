function initSlugGenerator(element) {
  const autoGenerate = element.dataset.slugGeneratorAutoGenerateValue === 'true';
  
  const sourceField = element.querySelector('[data-slug-generator-target="sourceField"]');
  const slugField = element.querySelector('[data-slug-generator-target="slugField"]');
  
  if (!sourceField || !slugField) return;
  
  function generateSlug() {
    // Only auto-generate if slug is empty or if autoGenerate is true
    if (!slugField.value || autoGenerate) {
      const slug = sourceField.value
        .toLowerCase()
        .replace(/[^a-z0-9\s-]/g, '') // Remove special characters
        .replace(/\s+/g, '-') // Replace spaces with hyphens
        .replace(/-+/g, '-') // Replace multiple hyphens with single hyphen
        .replace(/^-|-$/g, ''); // Remove leading/trailing hyphens
      
      slugField.value = slug;
    }
  }
  
  // Listen for input events
  sourceField.addEventListener('input', generateSlug);
}