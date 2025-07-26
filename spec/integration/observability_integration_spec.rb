require "rails_helper"

RSpec.describe "Observability Integration", type: :integration do
  describe "Full observability flow" do
    let!(:prompt) { create(:prompt, name: "greeting", content: "Hello {{name}}!") }
    let!(:cost_config) { create(:cost_config, :gpt_4o) }

    context "when rendering without execution" do
      it "logs usage without execution" do
        expect {
          PromptEngine.render("greeting", name: "World", session_id: "test123")
        }.to change { PromptEngine::Usage.count }.by(1)
          .and change { PromptEngine::LlmExecution.count }.by(0)

        usage = PromptEngine::Usage.last
        expect(usage.rendered_content).to eq("Hello World!")
        expect(usage.session_id).to eq("test123")
        expect(usage.parameters_used).to eq({ "name" => "World" })
        expect(usage.llm_execution).to be_nil
      end
    end

    context "when executing with a client" do
      let(:mock_client) { double("OpenAI::Client") }
      let(:mock_response) {
        {
          "choices" => [{ "message" => { "content" => "Hello there!" } }],
          "usage" => {
            "prompt_tokens" => 10,
            "completion_tokens" => 5,
            "total_tokens" => 15
          }
        }
      }

      before do
        allow(mock_client).to receive(:class).and_return(OpenAI::Client)
        allow(mock_client).to receive(:chat).and_return(mock_response)
      end

      it "logs both usage and execution" do
        rendered = PromptEngine.render("greeting", name: "World")

        expect {
          rendered.execute_with(mock_client, session_id: "exec123", user_identifier: "user456")
        }.to change { PromptEngine::Usage.count }.by(1)
          .and change { PromptEngine::LlmExecution.count }.by(1)

        usage = PromptEngine::Usage.last
        expect(usage.session_id).to eq("exec123")
        expect(usage.user_identifier).to eq("user456")
        expect(usage.metadata).to include("from_execute_with" => true)

        execution = usage.llm_execution
        expect(execution).to be_present
        expect(execution.provider).to eq("openai")
        expect(execution.status).to eq("success")
        expect(execution.response_content).to eq("Hello there!")
        expect(execution.input_tokens).to eq(10)
        expect(execution.output_tokens).to eq(5)
        expect(execution.total_tokens).to eq(15)
        expect(execution.cost_usd).to be > 0
      end

      it "handles execution errors gracefully" do
        allow(mock_client).to receive(:chat).and_raise(StandardError, "API Error")

        rendered = PromptEngine.render("greeting", name: "World")

        expect {
          expect {
            rendered.execute_with(mock_client)
          }.to raise_error(StandardError, "API Error")
        }.to change { PromptEngine::Usage.count }.by(1)
          .and change { PromptEngine::LlmExecution.count }.by(1)

        execution = PromptEngine::LlmExecution.last
        expect(execution.status).to eq("error")
        expect(execution.error_message).to eq("StandardError: API Error")
      end
    end

    context "analytics" do
      before do
        # Create test data
        3.times do
          usage = create(:usage, prompt: prompt)
          create(:llm_execution, usage: usage, cost_usd: 0.01)
        end
        
        failed_usage = create(:usage, prompt: prompt)
        create(:llm_execution, :failed, usage: failed_usage)
      end

      it "provides accurate usage statistics" do
        stats = PromptEngine::AnalyticsService.usage_stats(prompt: prompt)

        expect(stats[:total_uses]).to eq(4)
        expect(stats[:total_executions]).to eq(4)
        expect(stats[:success_rate]).to eq(75.0)
        expect(stats[:total_cost]).to eq(0.03)
      end

      it "tracks costs correctly" do
        breakdown = PromptEngine::AnalyticsService.cost_breakdown(group_by: :model)
        expect(breakdown["gpt-4"]).to eq(0.03)
      end

      it "analyzes errors" do
        analysis = PromptEngine::AnalyticsService.error_analysis
        expect(analysis[:total_errors]).to eq(1)
        expect(analysis[:errors_by_type][:rate_limit]).to eq(1)
      end
    end
  end

  describe "Playground observability" do
    let(:prompt) { create(:prompt, content: "Test {{input}}", model: "gpt-4o") }
    let!(:cost_config) { create(:cost_config, :gpt_4o) }

    it "logs playground executions" do
      mock_response = double(
        content: "Test response",
        input_tokens: 20,
        output_tokens: 10
      )
      
      allow(RubyLLM).to receive(:chat).and_return(double(
        with_temperature: double(
          with_instructions: double(
            ask: mock_response
          )
        )
      ))
      allow(RubyLLM).to receive(:configure)

      executor = PromptEngine::PlaygroundExecutor.new(
        prompt: prompt,
        provider: "openai",
        api_key: "test-key",
        parameters: { "input" => "data" }
      )

      expect {
        result = executor.execute
        expect(result[:response]).to eq("Test response")
      }.to change { PromptEngine::Usage.count }.by(1)
        .and change { PromptEngine::LlmExecution.count }.by(1)

      usage = PromptEngine::Usage.last
      expect(usage.metadata).to include("source" => "playground")
      
      execution = usage.llm_execution
      expect(execution.status).to eq("success")
      expect(execution.response_metadata).to include("playground" => true)
    end
  end
end