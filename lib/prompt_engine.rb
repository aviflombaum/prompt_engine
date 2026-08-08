require "prompt_engine/version"
require "prompt_engine/engine"
require "prompt_engine/rendered_prompt"
require "prompt_engine/errors"

module PromptEngine
  class << self
    # Render a prompt by slug with variables and options
    # @param slug [String] The slug of the prompt to render
    # @param variables [Hash] Variables to interpolate in the prompt (default: {})
    # @param options [Hash] Rendering options via keyword argument
    # @option options [String] :status The status to filter by (defaults to 'active')
    # @option options [String] :model Override the prompt's default model
    # @option options [Float] :temperature Override the prompt's default temperature
    # @option options [Integer] :max_tokens Override the prompt's default max_tokens
    # @option options [Integer] :version Render a specific version number
    def render(slug, variables = {}, options: {})
      # Set defaults for options
      options = {
        status: "active"
      }.merge(options)

      # If version is specified, we need to find the prompt without status filter
      # because we want to load any version regardless of the prompt's current status
      if options[:version]
        # Find prompt by slug only (no status filter)
        prompt = Prompt.find_by_slug!(slug)

        # Pass along the original status option for the RenderedPrompt
        render_options = options.merge(variables)
      else
        # Extract status from options for finding the prompt
        status = options.delete(:status)

        # Find the prompt with the appropriate status
        prompt = find(slug, status: status)

        # Merge options with variables (status is only for finding, not rendering)
        render_options = options.merge(variables)
      end

      prompt.render(**render_options)
    end

    # Find a prompt by slug with optional status filter
    # @param slug [String] The slug of the prompt
    # @param status [String] The status to filter by (defaults to 'active')
    def find(slug, status: "active")
      if status
        Prompt.where(slug: slug, status: status).first!
      else
        # If explicitly passed as nil, find any status
        Prompt.find_by_slug!(slug)
      end
    end

    # Alias for array-like access (defaults to active status)
    def [](slug)
      find(slug)
    end

    def configuration
      @configuration ||= Configuration.new
    end

    # Configures the PromptEngine by yielding the current configuration object.
    # If no configuration exists, a new Configuration instance is created.
    #
    # @yieldparam [Configuration] configuration The configuration object to be modified.
    # @return [void]
    def configure
      self.configuration ||= Configuration.new
      yield(configuration)
    end

    # Configuration class manages model selection options for the prompt engine.
    #
    # Attributes:
    #   options_for_model_select [Array<Array<String>>]: An array of pairs, where each pair contains
    #     the display name and the identifier for a supported AI model.
    #
    # Examples:
    #   PromptEngine.configure do |config|
    #     config.options_for_model_select << ["New Model", "new-model-id"]
    #   end
    #
    #   PromptEngine.configure do |config|
    #     config.options_for_model_select = ["New Model", "new-model-id", ...]
    #   end
    #
    # Usage:
    #   Use this class to retrieve or modify the available model options for selection in the application.
    class Configuration
      attr_accessor :options_for_model_select

      def initialize
        @options_for_model_select = [
          ["GPT-4", "gpt-4"],
          ["GPT-4 Turbo", "gpt-4-turbo-preview"],
          ["GPT-3.5 Turbo", "gpt-3.5-turbo"],
          ["Claude 3 Opus", "claude-3-opus"],
          ["Claude 3 Sonnet", "claude-3-sonnet"],
          ["Claude 3 Haiku", "claude-3-haiku"]
        ]
      end
    end
  end
end
