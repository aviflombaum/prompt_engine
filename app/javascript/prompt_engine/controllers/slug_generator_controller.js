import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["sourceField", "slugField"]
  static values = { autoGenerate: Boolean }

  connect() {
    // Generate slug on connect if needed
    if (this.hasSourceFieldTarget && this.hasSlugFieldTarget) {
      this.generateSlug()
    }
  }

  generateSlug() {
    // Only auto-generate if slug is empty or if autoGenerate is true
    if (!this.slugFieldTarget.value || this.autoGenerateValue) {
      const slug = this.sourceFieldTarget.value
        .toLowerCase()
        .replace(/[^a-z0-9\s-]/g, '') // Remove special characters
        .replace(/\s+/g, '-') // Replace spaces with hyphens
        .replace(/-+/g, '-') // Replace multiple hyphens with single hyphen
        .replace(/^-|-$/g, ''); // Remove leading/trailing hyphens
      
      this.slugFieldTarget.value = slug;
    }
  }
}