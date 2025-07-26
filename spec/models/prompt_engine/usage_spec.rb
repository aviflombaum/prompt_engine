require "rails_helper"

RSpec.describe PromptEngine::Usage, type: :model do
  describe "associations" do
    it { should belong_to(:prompt) }
    it { should belong_to(:prompt_version) }
    it { should have_one(:llm_execution).dependent(:destroy) }
  end

  describe "validations" do
    it { should validate_presence_of(:rendered_content) }
  end

  describe "scopes" do
    let!(:usage1) { create(:usage, environment: "production") }
    let!(:usage2) { create(:usage, environment: "development") }
    let!(:usage_with_execution) { create(:usage_with_execution) }

    describe ".by_environment" do
      it "filters by environment" do
        expect(described_class.by_environment("production")).to include(usage1)
        expect(described_class.by_environment("production")).not_to include(usage2)
      end
    end

    describe ".recent" do
      it "orders by created_at desc" do
        expect(described_class.recent).to eq([usage_with_execution, usage2, usage1])
      end
    end

    describe ".with_execution" do
      it "includes only usages with executions" do
        expect(described_class.with_execution).to include(usage_with_execution)
        expect(described_class.with_execution).not_to include(usage1, usage2)
      end
    end
  end

  describe "instance methods" do
    let(:usage) { create(:usage) }
    let(:usage_with_execution) { create(:usage_with_execution) }
    let(:usage_with_failed_execution) { create(:usage_with_failed_execution) }

    describe "#executed?" do
      it "returns true when execution exists" do
        expect(usage_with_execution.executed?).to be true
      end

      it "returns false when no execution exists" do
        expect(usage.executed?).to be false
      end
    end

    describe "#successful?" do
      it "returns true when execution is successful" do
        expect(usage_with_execution.successful?).to be true
      end

      it "returns false when execution failed" do
        expect(usage_with_failed_execution.successful?).to be false
      end

      it "returns false when no execution exists" do
        expect(usage.successful?).to be false
      end
    end

    describe "#cost" do
      it "returns execution cost when available" do
        expect(usage_with_execution.cost).to eq(0.0315)
      end

      it "returns 0 when no execution exists" do
        expect(usage.cost).to eq(0)
      end
    end

    describe "#total_tokens" do
      it "returns total tokens from execution" do
        expect(usage_with_execution.total_tokens).to eq(1500)
      end

      it "returns 0 when no execution exists" do
        expect(usage.total_tokens).to eq(0)
      end
    end
  end
end