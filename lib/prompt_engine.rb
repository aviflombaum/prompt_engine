require "prompt_engine/version"
require "prompt_engine/engine"
require "prompt_engine/rendered_prompt"
require "prompt_engine/errors"
require "prompt_engine/authentication"

module PromptEngine
  # Configuration for authentication
  mattr_accessor :authentication_enabled, default: true
  mattr_accessor :http_basic_auth_enabled, default: false
  mattr_accessor :http_basic_auth_name, default: nil
  mattr_accessor :http_basic_auth_password, default: nil

  class << self
    def configure
      yield self if block_given?
    end
    # Render a prompt by slug with variables and options
    def render(slug, **options)
      # Extract tracking options
      tracking_options = options.slice(:session_id, :user_identifier, :tracking_metadata)
      skip_tracking = options.delete(:skip_tracking)
      
      prompt = find(slug)
      rendered = prompt.render(**options)
      
      # Log usage if tracking is enabled and not skipped
      if tracking_enabled? && !skip_tracking && !tracking_options[:metadata]&.[](:from_execute_with)
        version = prompt.version_at(rendered.version_number)
        ObservabilityService.log_usage(
          prompt: prompt,
          version: version,
          parameters: rendered.parameters,
          rendered_content: rendered.content,
          rendered_system_message: rendered.system_message,
          **tracking_options
        )
      end
      
      rendered
    end

    # Find a prompt by slug
    def find(slug)
      Prompt.find_by_slug!(slug)
    end

    # Alias for array-like access
    def [](slug)
      find(slug)
    end

    # Check if HTTP Basic Auth should be used
    def use_http_basic_auth?
      http_basic_auth_enabled && http_basic_auth_name.present? && http_basic_auth_password.present?
    end
    
    # Check if usage tracking is enabled
    def tracking_enabled?
      # Can be configured later, default to true
      true
    end
  end
end
