module PromptEngine
  class ObservabilityService
    class << self
      def log_usage(prompt:, version:, parameters:, rendered_content:, rendered_system_message:, **options)
        Usage.create!(
          prompt: prompt,
          prompt_version: version,
          parameters_used: parameters,
          rendered_content: rendered_content,
          rendered_system_message: rendered_system_message,
          environment: detect_environment,
          session_id: options[:session_id],
          user_identifier: options[:user_identifier],
          metadata: build_metadata(options[:metadata])
        )
      end
      
      def log_execution(usage:, provider:, model:, **execution_data)
        execution = usage.build_llm_execution(
          provider: provider,
          model: model,
          temperature: execution_data[:temperature],
          max_tokens: execution_data[:max_tokens],
          messages_sent: execution_data[:messages],
          status: "pending"
        )
        
        execution.save!
        execution
      end
      
      def update_execution(execution, response_data)
        execution.update!(
          response_content: response_data[:content],
          input_tokens: response_data[:input_tokens],
          output_tokens: response_data[:output_tokens],
          total_tokens: response_data[:total_tokens],
          execution_time_ms: response_data[:execution_time_ms],
          status: "success",
          response_metadata: response_data[:metadata] || {}
        )
        
        # Cost is calculated automatically in the model's after_update callback
        execution
      end
      
      def log_execution_error(execution, error)
        execution.update!(
          status: "error",
          error_message: "#{error.class}: #{error.message}"
        )
      end
      
      def log_render_only(prompt:, parameters:, **options)
        # For cases where we only render but don't execute
        version = prompt.current_version
        rendered_data = prompt.render_with_params(parameters)
        
        log_usage(
          prompt: prompt,
          version: version,
          parameters: parameters,
          rendered_content: rendered_data[:content],
          rendered_system_message: rendered_data[:system_message],
          **options
        )
      end
      
      private
      
      def detect_environment
        Rails.env
      end
      
      def build_metadata(custom_metadata)
        base_metadata = {
          rails_version: Rails.version,
          ruby_version: RUBY_VERSION,
          timestamp: Time.current.iso8601,
          hostname: Socket.gethostname
        }
        
        base_metadata.merge(custom_metadata || {})
      end
    end
  end
end