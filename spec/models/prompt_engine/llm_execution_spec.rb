require "rails_helper"

RSpec.describe PromptEngine::LlmExecution, type: :model do
  describe "associations" do
    it { should belong_to(:usage) }
    it { should have_one(:prompt).through(:usage) }
    it { should have_one(:prompt_version).through(:usage) }
  end

  describe "validations" do
    it { should validate_presence_of(:provider) }
    it { should validate_presence_of(:model) }
    it { should validate_presence_of(:status) }
    it { should validate_inclusion_of(:status).in_array(%w[pending success error timeout]) }
  end

  describe "scopes" do
    let!(:successful_execution) { create(:llm_execution, status: "success") }
    let!(:failed_execution) { create(:llm_execution, status: "error") }
    let!(:timeout_execution) { create(:llm_execution, status: "timeout") }
    let!(:openai_execution) { create(:llm_execution, provider: "openai") }
    let!(:anthropic_execution) { create(:llm_execution, provider: "anthropic") }

    describe ".successful" do
      it "returns only successful executions" do
        expect(described_class.successful).to include(successful_execution)
        expect(described_class.successful).not_to include(failed_execution, timeout_execution)
      end
    end

    describe ".failed" do
      it "returns error and timeout executions" do
        expect(described_class.failed).to include(failed_execution, timeout_execution)
        expect(described_class.failed).not_to include(successful_execution)
      end
    end

    describe ".by_provider" do
      it "filters by provider" do
        expect(described_class.by_provider("openai")).to include(openai_execution)
        expect(described_class.by_provider("openai")).not_to include(anthropic_execution)
      end
    end
  end

  describe "callbacks" do
    describe "before_save :calculate_total_tokens" do
      it "calculates total tokens from input and output" do
        execution = build(:llm_execution, input_tokens: 100, output_tokens: 200, total_tokens: nil)
        execution.save!
        expect(execution.total_tokens).to eq(300)
      end
    end

    describe "after_update :calculate_cost_if_needed" do
      let(:cost_config) { create(:cost_config, provider: "openai", model: "gpt-4") }
      let(:execution) { create(:llm_execution, provider: "openai", model: "gpt-4", input_tokens: nil, output_tokens: nil) }

      before { cost_config }

      it "updates cost when tokens change" do
        execution.update!(input_tokens: 1000, output_tokens: 500)
        expect(execution.reload.cost_usd).to eq(0.0375) # (1000/1000 * 0.03) + (500/1000 * 0.015)
      end
    end
  end

  describe "#calculate_cost" do
    let(:execution) { create(:llm_execution, provider: "openai", model: "gpt-4", input_tokens: 1000, output_tokens: 500) }

    context "with cost config available" do
      let!(:cost_config) { create(:cost_config, provider: "openai", model: "gpt-4", input_token_cost: 0.03, output_token_cost: 0.015) }

      it "calculates cost correctly" do
        expect(execution.calculate_cost).to eq(0.0375)
      end
    end

    context "without cost config" do
      it "returns 0" do
        expect(execution.calculate_cost).to eq(0)
      end
    end

    context "without token counts" do
      let(:execution) { create(:llm_execution, input_tokens: nil, output_tokens: nil) }

      it "returns 0" do
        expect(execution.calculate_cost).to eq(0)
      end
    end
  end

  describe "#successful?" do
    it "returns true for success status" do
      execution = build(:llm_execution, status: "success")
      expect(execution.successful?).to be true
    end

    it "returns false for other statuses" do
      expect(build(:llm_execution, status: "error").successful?).to be false
      expect(build(:llm_execution, status: "pending").successful?).to be false
    end
  end

  describe "#failed?" do
    it "returns true for error and timeout statuses" do
      expect(build(:llm_execution, status: "error").failed?).to be true
      expect(build(:llm_execution, status: "timeout").failed?).to be true
    end

    it "returns false for success and pending" do
      expect(build(:llm_execution, status: "success").failed?).to be false
      expect(build(:llm_execution, status: "pending").failed?).to be false
    end
  end
end