require "rails_helper"

RSpec.describe PromptEngine::CostConfig, type: :model do
  describe "validations" do
    it { should validate_presence_of(:provider) }
    it { should validate_presence_of(:model) }
    it { should validate_presence_of(:input_token_cost) }
    it { should validate_presence_of(:output_token_cost) }
    it { should validate_presence_of(:effective_from) }
    it { should validate_inclusion_of(:provider).in_array(%w[openai anthropic]) }
    it { should validate_numericality_of(:input_token_cost).is_greater_than_or_equal_to(0) }
    it { should validate_numericality_of(:output_token_cost).is_greater_than_or_equal_to(0) }

    describe "effective dates validation" do
      it "validates effective_until is after effective_from" do
        config = build(:cost_config, effective_from: Date.today, effective_until: Date.yesterday)
        expect(config).not_to be_valid
        expect(config.errors[:effective_until]).to include("must be after effective_from")
      end

      it "allows effective_until to be nil" do
        config = build(:cost_config, effective_until: nil)
        expect(config).to be_valid
      end
    end
  end

  describe "scopes" do
    let!(:active_config) { create(:cost_config, effective_from: 1.month.ago, effective_until: nil) }
    let!(:future_config) { create(:cost_config, effective_from: 1.month.from_now) }
    let!(:expired_config) { create(:cost_config, effective_from: 1.year.ago, effective_until: 1.month.ago) }

    describe ".active" do
      it "returns configs effective on the given date" do
        expect(described_class.active).to include(active_config)
        expect(described_class.active).not_to include(future_config, expired_config)
      end

      it "accepts a custom date" do
        expect(described_class.active(2.months.from_now)).to include(active_config, future_config)
      end
    end
  end

  describe ".for_model" do
    let!(:gpt4_config_old) { create(:cost_config, provider: "openai", model: "gpt-4", effective_from: 1.year.ago) }
    let!(:gpt4_config_new) { create(:cost_config, provider: "openai", model: "gpt-4", effective_from: 1.month.ago) }
    let!(:gpt3_config) { create(:cost_config, provider: "openai", model: "gpt-3.5-turbo", effective_from: 1.month.ago) }

    it "returns the most recent active config for the model" do
      expect(described_class.for_model("openai", "gpt-4")).to eq(gpt4_config_new)
    end

    it "returns nil when no config exists" do
      expect(described_class.for_model("openai", "non-existent")).to be_nil
    end

    it "respects the date parameter" do
      expect(described_class.for_model("openai", "gpt-4", 6.months.ago)).to eq(gpt4_config_old)
    end
  end

  describe ".seed_default_costs" do
    it "creates default cost configurations" do
      expect { described_class.seed_default_costs }.to change { described_class.count }
      
      # Check a few key models
      expect(described_class.for_model("openai", "gpt-4o")).to be_present
      expect(described_class.for_model("anthropic", "claude-3-5-sonnet-20241022")).to be_present
    end

    it "updates existing configurations" do
      existing = create(:cost_config, provider: "openai", model: "gpt-4o", effective_from: Date.new(2024, 1, 1), input_token_cost: 0.001)
      
      described_class.seed_default_costs
      
      expect(existing.reload.input_token_cost).to eq(0.005)
    end
  end

  describe "#active?" do
    let(:config) { create(:cost_config, effective_from: 1.month.ago, effective_until: 1.month.from_now) }

    it "returns true when date is within range" do
      expect(config.active?).to be true
      expect(config.active?(Date.today)).to be true
    end

    it "returns false when date is outside range" do
      expect(config.active?(2.months.ago)).to be false
      expect(config.active?(2.months.from_now)).to be false
    end

    it "handles nil effective_until" do
      config.update!(effective_until: nil)
      expect(config.active?(1.year.from_now)).to be true
    end
  end

  describe "#cost_per_1k_tokens" do
    let(:config) { create(:cost_config, input_token_cost: 0.003, output_token_cost: 0.015) }

    it "returns cost breakdown" do
      costs = config.cost_per_1k_tokens
      expect(costs[:input]).to eq(0.003)
      expect(costs[:output]).to eq(0.015)
      expect(costs[:average]).to eq(0.009)
    end
  end
end