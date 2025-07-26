module PromptEngine
  class Prompt < ApplicationRecord
    self.table_name = "prompt_engine_prompts"

    has_many :versions, -> { order(version_number: :desc) },
             class_name: "PromptEngine::PromptVersion",
             dependent: :destroy
    has_many :parameters, -> { ordered },
             class_name: "PromptEngine::Parameter",
             dependent: :destroy
    has_many :eval_sets,
             class_name: "PromptEngine::EvalSet",
             dependent: :destroy
    has_many :usages,
             class_name: "PromptEngine::Usage",
             dependent: :destroy

    attr_accessor :change_summary

    validates :name, presence: true, uniqueness: { scope: :status }
    validates :content, presence: true
    validates :slug, presence: true, uniqueness: true, format: { with: /\A[a-z0-9-]+\z/ }

    accepts_nested_attributes_for :parameters, allow_destroy: true

    enum :status, {
      draft: "draft",
      active: "active",
      archived: "archived"
    }, default: "draft"

    scope :active, -> { where(status: "active") }
    scope :by_name, -> { order(:name) }

    before_validation :generate_slug_from_name, on: :create
    after_create :create_initial_version
    after_create :sync_parameters!
    after_update :create_version_if_changed
    after_update :sync_parameters!, if: :saved_change_to_content?
    before_save :clean_orphaned_parameters

    VERSIONED_ATTRIBUTES = %w[content system_message model temperature max_tokens metadata].freeze
    OVERRIDE_KEYS = %i[model temperature max_tokens version].freeze

    def current_version
      versions.first
    end

    def version_count
      versions_count
    end

    def restore_version!(version_number)
      version = versions.find_by!(version_number: version_number)
      version.restore!
    end

    def version_at(version_number)
      versions.find_by(version_number: version_number)
    end

    def versioned_attributes_changed?
      # This method is for checking if versioned attributes have changed before save
      (changed & VERSIONED_ATTRIBUTES).any?
    end

    # Parameter management methods
    def detect_variables
      # Don't cache the detector as content can change
      PromptEngine::VariableDetector.new(content).variable_names
    end

    def sync_parameters!
      detected_vars = detect_variables
      existing_names = parameters.pluck(:name)

      # Add new parameters
      new_vars = detected_vars - existing_names
      if new_vars.any?
        # Get max position once, before the loop
        max_position = parameters.maximum(:position) || 0
        detector = PromptEngine::VariableDetector.new(content)

        new_vars.each_with_index do |var_name, index|
          var_info = detector.extract_variables.find { |v| v[:name] == var_name }

          # Skip if parameter already exists (race condition protection)
          next if parameters.exists?(name: var_name)

          parameters.create!(
            name: var_name,
            parameter_type: var_info[:type],
            required: var_info[:required],
            position: max_position + index + 1
          )
        end
      end

      # Remove parameters that no longer exist
      removed_vars = existing_names - detected_vars
      parameters.where(name: removed_vars).destroy_all if removed_vars.any?

      true
    end

    def render_with_params(provided_params = {})
              detector = PromptEngine::VariableDetector.new(content)

      # Validate all required parameters are provided
      validation = validate_parameters(provided_params)
      return { error: validation[:errors].join(", ") } unless validation[:valid]

      # Cast parameters to their correct types, including defaults
      casted_params = {}
      parameters.each do |param|
        value = provided_params[param.name] || provided_params[param.name.to_sym]
        # Let cast_value handle the default value logic
        casted_params[param.name] = param.cast_value(value)
      end

      # Also include any parameters not defined in the database but present in the template
      detected_vars = detect_variables
      detected_vars.each do |var_name|
        unless casted_params.key?(var_name)
          value = provided_params[var_name] || provided_params[var_name.to_sym]
          casted_params[var_name] = value.to_s if value.present?
        end
      end

      {
        content: detector.render(casted_params),
        system_message: system_message,
        model: model,
        temperature: temperature,
        max_tokens: max_tokens,
        parameters_used: casted_params
      }
    end

    def validate_parameters(provided_params = {})
      errors = []

      parameters.each do |param|
        value = provided_params[param.name] || provided_params[param.name.to_sym]
        # Use default value if not provided and parameter is optional
        if value.blank? && !param.required? && param.default_value.present?
          value = param.default_value
        end
        param_errors = param.validate_value(value)
        errors.concat(param_errors)
      end

      {
        valid: errors.empty?,
        errors: errors
      }
    end

    # New render method that returns RenderedPrompt
    def render(**options)
      # Separate variables from overrides
      overrides = options.slice(*OVERRIDE_KEYS)
      variables = options.except(*OVERRIDE_KEYS)

      # Handle version specification
      if overrides[:version]
        version_number = overrides.delete(:version)
        return render_version(version_number, variables: variables, overrides: overrides)
      end

      rendered_data = render_with_params(variables)

      # Handle errors
      if rendered_data[:error]
        raise PromptEngine::RenderError, rendered_data[:error]
      end

      # Add current version number
      rendered_data[:version_number] = current_version&.version_number

      PromptEngine::RenderedPrompt.new(self, rendered_data, overrides)
    end

    # Render a specific version
    def render_version(version_number, variables: {}, overrides: {})
      version = versions.find_by!(version_number: version_number)

      # Use version's content and settings
      detector = PromptEngine::VariableDetector.new(version.content)
      rendered_content = detector.render(variables)

      rendered_data = {
        content: rendered_content,
        system_message: version.system_message,
        model: version.model,
        temperature: version.temperature,
        max_tokens: version.max_tokens,
        parameters_used: variables,
        version_number: version.version_number
      }

      PromptEngine::RenderedPrompt.new(self, rendered_data, overrides)
    end

    # Class method for finding by slug
    def self.find_by_slug!(slug)
      find_by!(slug: slug, status: "active")
    end

    private

    def create_initial_version
      versions.create!(
        content: content,
        system_message: system_message,
        model: model,
        temperature: temperature,
        max_tokens: max_tokens,
        metadata: metadata,
        change_description: "Initial version"
      )
    end

    def create_version_if_changed
      # Check saved_changes in the after_update callback
      return unless (saved_changes.keys & VERSIONED_ATTRIBUTES).any?

      versions.create!(
        content: content,
        system_message: system_message,
        model: model,
        temperature: temperature,
        max_tokens: max_tokens,
        metadata: metadata,
        change_description: "Updated: #{(saved_changes.keys & VERSIONED_ATTRIBUTES).join(', ')}"
      )
    end

    def clean_orphaned_parameters
      return unless content_changed?

      # Mark parameters for destruction if their names are not in the content
      detected_vars = detect_variables
      parameters.each do |param|
        param.mark_for_destruction unless detected_vars.include?(param.name)
      end
    end

    def generate_slug_from_name
      self.slug ||= name&.parameterize
    end
  end
end
