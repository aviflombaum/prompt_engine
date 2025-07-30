module PromptEngine
  class Parameter < ApplicationRecord
    self.table_name = "prompt_engine_parameters"

    # Parameter types that can be used
    TYPES = %w[string integer decimal boolean datetime date array json file].freeze

    belongs_to :prompt, class_name: "PromptEngine::Prompt"

    validates :name, presence: true,
              uniqueness: { scope: :prompt_id },
              format: { with: /\A[a-zA-Z_][a-zA-Z0-9_]*\z/, message: "must start with a letter or underscore and contain only letters, numbers, and underscores" }
    validates :parameter_type, presence: true, inclusion: { in: TYPES }
    validates :required, inclusion: { in: [ true, false ] }

    scope :required, -> { where(required: true) }
    scope :optional, -> { where(required: false) }
    scope :ordered, -> { order(position: :asc, created_at: :asc) }

    before_validation :set_defaults

    # Convert the parameter value based on its type
    def cast_value(value)
      return default_value if value.blank? && !required?

      case parameter_type
      when "integer"
        value.to_i
      when "decimal"
        value.to_f
      when "boolean"
        ActiveModel::Type::Boolean.new.cast(value)
      when "datetime"
        DateTime.parse(value.to_s) rescue nil
      when "date"
        Date.parse(value.to_s) rescue nil
      when "array"
        value.is_a?(Array) ? value : value.to_s.split(",").map(&:strip)
      when "json"
        value.is_a?(String) ? JSON.parse(value) : value rescue {}
      else
        value.to_s
      end
    end

    # Validate a value against this parameter's rules
    def validate_value(value)
      errors = []

      if required? && value.blank?
        errors << "#{name} is required"
      end

      if validation_rules.present?
        # Apply custom validation rules
        if validation_rules["min_length"] && value.to_s.length < validation_rules["min_length"]
          errors << "#{name} must be at least #{validation_rules['min_length']} characters"
        end

        if validation_rules["max_length"] && value.to_s.length > validation_rules["max_length"]
          errors << "#{name} must be at most #{validation_rules['max_length']} characters"
        end

        if validation_rules["pattern"] && !value.to_s.match?(Regexp.new(validation_rules["pattern"]))
          errors << "#{name} must match pattern: #{validation_rules['pattern']}"
        end

        if validation_rules["min"] && cast_value(value) < validation_rules["min"]
          errors << "#{name} must be at least #{validation_rules['min']}"
        end

        if validation_rules["max"] && cast_value(value) > validation_rules["max"]
          errors << "#{name} must be at most #{validation_rules['max']}"
        end
      end

      errors
    end

    # Generate form input attributes for this parameter
    def form_input_options
      options = {
        label: name.humanize,
        required: required?,
        placeholder: example_value,
        hint: description
      }

      case parameter_type
      when "integer", "decimal"
        options[:type] = "number"
        options[:step] = parameter_type == "decimal" ? "0.01" : "1"
        options[:min] = validation_rules["min"] if validation_rules&.dig("min")
        options[:max] = validation_rules["max"] if validation_rules&.dig("max")
      when "boolean"
        options[:type] = "checkbox"
      when "datetime"
        options[:type] = "datetime-local"
      when "date"
        options[:type] = "date"
      when "array"
        options[:type] = "text"
        options[:hint] = "#{description} (comma-separated values)"
      when "json"
        options[:type] = "textarea"
        options[:hint] = "#{description} (JSON format)"
      else
        options[:type] = "text"
        options[:minlength] = validation_rules["min_length"] if validation_rules&.dig("min_length")
        options[:maxlength] = validation_rules["max_length"] if validation_rules&.dig("max_length")
        options[:pattern] = validation_rules["pattern"] if validation_rules&.dig("pattern")
      end

      options[:value] = default_value if default_value.present?

      options
    end

    private

    def set_defaults
      self.parameter_type ||= "string"
      self.required = true if required.nil?
    end
  end
end
