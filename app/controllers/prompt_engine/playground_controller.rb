module PromptEngine
  class PlaygroundController < ApplicationController
    layout "prompt_engine/admin"
    before_action :set_prompt

    def show
      @parameters = ParameterParser.new(@prompt.content).extract_parameters.map { |p| p[:name] }
      @settings = Setting.instance
    end

    def execute
      # Process uploaded files and add them to parameters
      processed_parameters = process_parameters_with_files

      # Validate API key is present and not empty
      if params[:api_key].blank?
        @error = "API key is required"
        render :result and return
      end

      executor = PlaygroundExecutor.new(
        prompt: @prompt,
        provider: params[:provider],
        api_key: params[:api_key].strip,
        parameters: processed_parameters
      )

      begin
        result = executor.execute
        @response = result[:response]
        @execution_time = result[:execution_time]
        @token_count = result[:token_count]
        @model = result[:model]
        @provider = result[:provider]

        # Store the rendered prompt for display
        parser = ParameterParser.new(@prompt.content)
        @rendered_prompt = parser.replace_parameters(params[:parameters])

        # Save the playground run result
        @prompt.current_version.playground_run_results.create!(
          provider: @provider,
          model: @model,
          rendered_prompt: @rendered_prompt,
          system_message: @prompt.system_message,
          parameters: params[:parameters],
          response: @response,
          execution_time: @execution_time,
          token_count: @token_count,
          temperature: @prompt.temperature,
          max_tokens: @prompt.max_tokens
        )
      rescue => e
        @error = e.message
      end

      render :result
    end

    private

    def set_prompt
      @prompt = Prompt.find(params[:id])
    end

    def process_parameters_with_files
      processed_params = params[:parameters]&.to_unsafe_h || {}

      # Collect all uploaded files, filtering out empty ones
      uploaded_files = []

      # Add files from the general file upload field
      if params[:files].present?
        general_files = params[:files].is_a?(Array) ? params[:files] : [ params[:files] ]
        uploaded_files.concat(general_files.compact.reject { |f| f.blank? || (f.respond_to?(:original_filename) && f.original_filename.blank?) })
      end

      # Add files to parameters if any were uploaded
      if uploaded_files.any?
        processed_params[:files] = uploaded_files
      end

      processed_params
    end
  end
end
