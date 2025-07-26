module PromptEngine
  class RenderedPrompt
    attr_reader :prompt, :content, :system_message, :model,
                :temperature, :max_tokens, :overrides,
                :version_number

    def initialize(prompt, rendered_data, overrides = {})
      @prompt = prompt
      @content = rendered_data[:content]
      @system_message = rendered_data[:system_message]
      @parameters = rendered_data[:parameters_used] || {}
      @overrides = overrides
      @version_number = rendered_data[:version_number]

      # Apply overrides for model settings
      @model = overrides[:model] || rendered_data[:model]
      @temperature = overrides[:temperature] || rendered_data[:temperature]
      @max_tokens = overrides[:max_tokens] || rendered_data[:max_tokens]
    end

    # Returns messages array for chat-based models
    def messages
      msgs = []
      msgs << { role: "system", content: system_message } if system_message.present?
      msgs << { role: "user", content: content }
      msgs
    end

    # For OpenAI gem compatibility
    def to_openai_params(**additional_options)
      base_params = {
        model: model || "gpt-4",
        messages: messages,
        temperature: temperature,
        max_tokens: max_tokens
      }.compact

      # Merge with additional options (tools, functions, response_format, etc.)
      base_params.merge(additional_options)
    end

    # For RubyLLM compatibility
    def to_ruby_llm_params(**additional_options)
      base_params = {
        messages: messages,
        model: model || "gpt-4",
        temperature: temperature,
        max_tokens: max_tokens
      }.compact

      # Merge with additional options
      base_params.merge(additional_options)
    end

    # Automatic client detection and execution with observability
    def execute_with(client, **options)
      # Extract tracking options
      tracking_options = options.slice(:session_id, :user_identifier, :tracking_metadata)
      clean_options = options.except(:session_id, :user_identifier, :tracking_metadata)
      
      # Log the usage
      usage = log_usage(tracking_options)
      
      # Prepare execution logging
      provider = detect_provider(client)
      execution = log_execution_start(usage, provider, clean_options)
      
      start_time = Time.current
      
      begin
        # Execute based on client type with observability
        response = case client.class.name
        when /RubyLLM/, /Anthropic/
          execute_with_ruby_llm(client, execution, clean_options, start_time)
        when /OpenAI/
          execute_with_openai(client, execution, clean_options, start_time)
        else
          raise ArgumentError, "Unknown client type: #{client.class.name}"
        end
        
        response
      rescue => e
        ObservabilityService.log_execution_error(execution, e) if execution
        raise
      end
    end

    # Parameter access methods
    def parameters
      @parameters
    end

    def parameter(key)
      @parameters[key.to_s]
    end

    def parameter_names
      @parameters.keys
    end

    def parameter_values
      @parameters.values
    end

    # Check if a parameter exists
    def parameter?(key)
      @parameters.key?(key.to_s)
    end

    # Convenience methods
    def to_h
      {
        content: content,
        system_message: system_message,
        model: model,
        temperature: temperature,
        max_tokens: max_tokens,
        messages: messages,
        overrides: overrides,
        version_number: version_number,
        parameters: parameters
      }
    end

    def inspect
      version_info = version_number ? " version=#{version_number}" : ""
      param_info = parameter_names.any? ? " parameters=#{parameter_names}" : ""
      override_info = overrides.any? ? " overrides=#{overrides.keys}" : ""
      "#<PromptEngine::RenderedPrompt prompt=#{prompt.slug}#{version_info}#{param_info}#{override_info}>"
    end
    
    private
    
    def log_usage(tracking_options)
      # Add metadata to indicate this is from execute_with to prevent double logging
      metadata = (tracking_options[:tracking_metadata] || {}).merge(from_execute_with: true)
      
      ObservabilityService.log_usage(
        prompt: prompt,
        version: prompt.version_at(version_number),
        parameters: parameters,
        rendered_content: content,
        rendered_system_message: system_message,
        **tracking_options.merge(metadata: metadata)
      )
    end
    
    def log_execution_start(usage, provider, options)
      ObservabilityService.log_execution(
        usage: usage,
        provider: provider,
        model: model,
        temperature: temperature,
        max_tokens: max_tokens,
        messages: messages
      )
    end
    
    def detect_provider(client)
      case client.class.name
      when /OpenAI/
        "openai"
      when /Anthropic/
        "anthropic"
      when /RubyLLM/
        # Try to detect from the model name
        if model&.include?("gpt")
          "openai"
        elsif model&.include?("claude")
          "anthropic"
        else
          "unknown"
        end
      else
        "unknown"
      end
    end
    
    def execute_with_ruby_llm(client, execution, options, start_time)
      params = to_ruby_llm_params(**options)
      
      # Create chat instance
      chat = if client.respond_to?(:chat)
               client.chat(**params)
             else
               # Handle case where client is already a chat instance
               client
             end
      
      # Track response data
      response_data = {}
      
      # Add event handlers for observability
      if chat.respond_to?(:on_new_message) && chat.respond_to?(:on_end_message)
        chat.on_new_message do
          # Message generation started
        end
        
        chat.on_end_message do |message|
          if message
            execution_time_ms = (Time.current - start_time) * 1000
            
            response_data = {
              content: extract_message_content(message),
              input_tokens: message.respond_to?(:input_tokens) ? message.input_tokens : nil,
              output_tokens: message.respond_to?(:output_tokens) ? message.output_tokens : nil,
              total_tokens: nil, # Will be calculated by the model
              execution_time_ms: execution_time_ms,
              metadata: extract_metadata(message)
            }
            
            ObservabilityService.update_execution(execution, response_data)
          end
        end
      end
      
      # Execute the chat
      response = if chat.respond_to?(:ask)
                  chat.ask(content)
                else
                  chat
                end
      
      # If event handlers weren't available, update execution now
      if response_data.empty?
        execution_time_ms = (Time.current - start_time) * 1000
        response_data = {
          content: extract_message_content(response),
          input_tokens: response.respond_to?(:input_tokens) ? response.input_tokens : nil,
          output_tokens: response.respond_to?(:output_tokens) ? response.output_tokens : nil,
          execution_time_ms: execution_time_ms
        }
        ObservabilityService.update_execution(execution, response_data)
      end
      
      response
    end
    
    def execute_with_openai(client, execution, options, start_time)
      params = to_openai_params(**options)
      
      response = client.chat(parameters: params)
      
      execution_time_ms = (Time.current - start_time) * 1000
      
      # Extract token usage from OpenAI response
      usage_data = response.dig("usage") || {}
      
      response_data = {
        content: response.dig("choices", 0, "message", "content"),
        input_tokens: usage_data["prompt_tokens"],
        output_tokens: usage_data["completion_tokens"],
        total_tokens: usage_data["total_tokens"],
        execution_time_ms: execution_time_ms,
        metadata: response.except("choices", "usage")
      }
      
      ObservabilityService.update_execution(execution, response_data)
      
      response
    end
    
    def extract_message_content(message)
      if message.respond_to?(:content)
        message.content
      elsif message.is_a?(String)
        message
      elsif message.is_a?(Hash) && message["content"]
        message["content"]
      else
        message.to_s
      end
    end
    
    def extract_metadata(message)
      metadata = {}
      
      # Extract any additional fields from the message object
      if message.respond_to?(:to_h)
        metadata = message.to_h.except(:content, :input_tokens, :output_tokens)
      elsif message.is_a?(Hash)
        metadata = message.except("content", "input_tokens", "output_tokens")
      end
      
      metadata
    end
  end
end
