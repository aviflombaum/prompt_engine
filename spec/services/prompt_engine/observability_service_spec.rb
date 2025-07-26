require "rails_helper"

RSpec.describe PromptEngine::ObservabilityService do
  describe ".log_usage" do
    let(:prompt) { create(:prompt) }
    let(:version) { prompt.current_version }

    it "creates a usage record with all attributes" do
      usage = described_class.log_usage(
        prompt: prompt,
        version: version,
        parameters: { name: "John" },
        rendered_content: "Hello John",
        rendered_system_message: "Be helpful",
        session_id: "session123",
        user_identifier: "user456",
        metadata: { custom: "data" }
      )

      expect(usage).to be_persisted
      expect(usage.prompt).to eq(prompt)
      expect(usage.prompt_version).to eq(version)
      expect(usage.parameters_used).to eq({ "name" => "John" })
      expect(usage.rendered_content).to eq("Hello John")
      expect(usage.rendered_system_message).to eq("Be helpful")
      expect(usage.session_id).to eq("session123")
      expect(usage.user_identifier).to eq("user456")
      expect(usage.environment).to eq(Rails.env)
      expect(usage.metadata).to include("custom" => "data")
    end

    it "includes default metadata" do
      usage = described_class.log_usage(
        prompt: prompt,
        version: version,
        parameters: {},
        rendered_content: "Hello",
        rendered_system_message: nil
      )

      expect(usage.metadata).to include(
        "rails_version" => Rails.version,
        "ruby_version" => RUBY_VERSION,
        "timestamp" => anything,
        "hostname" => Socket.gethostname
      )
    end
  end

  describe ".log_execution" do
    let(:usage) { create(:usage) }

    it "creates a pending execution record" do
      execution = described_class.log_execution(
        usage: usage,
        provider: "openai",
        model: "gpt-4",
        temperature: 0.7,
        max_tokens: 500,
        messages: [{ role: "user", content: "Hello" }]
      )

      expect(execution).to be_persisted
      expect(execution.usage).to eq(usage)
      expect(execution.provider).to eq("openai")
      expect(execution.model).to eq("gpt-4")
      expect(execution.temperature).to eq(0.7)
      expect(execution.max_tokens).to eq(500)
      expect(execution.messages_sent).to eq([{ "role" => "user", "content" => "Hello" }])
      expect(execution.status).to eq("pending")
    end
  end

  describe ".update_execution" do
    let(:execution) { create(:llm_execution, status: "pending") }

    it "updates execution with response data" do
      described_class.update_execution(execution, {
        content: "Response content",
        input_tokens: 100,
        output_tokens: 200,
        total_tokens: 300,
        execution_time_ms: 1500,
        metadata: { custom: "response_data" }
      })

      execution.reload
      expect(execution.response_content).to eq("Response content")
      expect(execution.input_tokens).to eq(100)
      expect(execution.output_tokens).to eq(200)
      expect(execution.total_tokens).to eq(300)
      expect(execution.execution_time_ms).to eq(1500)
      expect(execution.status).to eq("success")
      expect(execution.response_metadata).to eq({ "custom" => "response_data" })
    end
  end

  describe ".log_execution_error" do
    let(:execution) { create(:llm_execution, status: "pending") }
    let(:error) { StandardError.new("API Error") }

    it "updates execution with error information" do
      described_class.log_execution_error(execution, error)

      execution.reload
      expect(execution.status).to eq("error")
      expect(execution.error_message).to eq("StandardError: API Error")
    end
  end

  describe ".log_render_only" do
    let(:prompt) { create(:prompt, content: "Hello {{name}}") }

    it "creates usage record for render-only operations" do
      usage = described_class.log_render_only(
        prompt: prompt,
        parameters: { name: "World" },
        session_id: "render123"
      )

      expect(usage).to be_persisted
      expect(usage.prompt).to eq(prompt)
      expect(usage.rendered_content).to eq("Hello World")
      expect(usage.session_id).to eq("render123")
    end
  end
end