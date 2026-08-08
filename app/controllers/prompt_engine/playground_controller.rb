module PromptEngine
  class PlaygroundController < ApplicationController
    before_action :set_prompt

    def show
      @parameters = ParameterParser.new(
        @prompt.content + @prompt.system_message.to_s
      ).extract_parameters.map { |p| p[:name] }

      @settings = Setting.instance
    end

    def execute
      executor = PlaygroundExecutor.new(
        prompt: @prompt,
        provider: params[:provider],
        api_key: params[:api_key],
        parameters: params[:parameters]
      )

      begin
        result = executor.execute
        @response = result[:response]
        @execution_time = result[:execution_time]
        @token_count = result[:token_count]
        @model = result[:model]
        @provider = result[:provider]

        # Store the rendered prompt for display
        content_parser = ParameterParser.new(@prompt.content)
        system_parser = ParameterParser.new(@prompt.system_message.to_s)

        @rendered_prompt = content_parser.replace_parameters(params[:parameters])
        @rendered_system_prompt = system_parser.replace_parameters(params[:parameters])

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
  end
end
