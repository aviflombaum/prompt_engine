require "rails_helper"

RSpec.describe PromptEngine::AnalyticsService do
  describe ".usage_stats" do
    let!(:prompt) { create(:prompt) }
    let!(:usages) { create_list(:usage, 3, prompt: prompt) }
    let!(:executions) { create_list(:usage_with_execution, 2, prompt: prompt) }

    it "returns comprehensive usage statistics" do
      stats = described_class.usage_stats(prompt: prompt)

      expect(stats[:total_uses]).to eq(5)
      expect(stats[:total_executions]).to eq(2)
      expect(stats[:success_rate]).to be > 0
      expect(stats[:total_cost]).to be > 0
      expect(stats[:average_tokens]).to be_present
      expect(stats[:by_environment]).to be_a(Hash)
      expect(stats[:by_model]).to be_a(Hash)
    end

    it "filters by date range" do
      old_usage = create(:usage, prompt: prompt, created_at: 2.months.ago)
      
      stats = described_class.usage_stats(prompt: prompt, date_range: 1.month.ago..Time.current)
      
      expect(stats[:total_uses]).to eq(5) # Doesn't include old_usage
    end
  end

  describe ".prompt_performance" do
    let(:prompt) { create(:prompt) }
    let!(:recent_executions) { create_list(:usage_with_execution, 5, prompt: prompt, created_at: 1.day.ago) }
    let!(:old_execution) { create(:usage_with_execution, prompt: prompt, created_at: 2.months.ago) }

    it "returns performance metrics for a prompt" do
      performance = described_class.prompt_performance(prompt)

      expect(performance[:total_executions]).to eq(5)
      expect(performance[:average_latency_ms]).to be_present
      expect(performance[:error_rate]).to be >= 0
      expect(performance[:success_rate]).to be >= 0
      expect(performance[:cost_by_day]).to be_a(Hash)
      expect(performance[:usage_by_version]).to be_a(Hash)
      expect(performance[:model_distribution]).to be_a(Hash)
      expect(performance[:token_usage]).to include(:total_input_tokens, :total_output_tokens)
    end
  end

  describe ".cost_breakdown" do
    let!(:prompt1) { create(:prompt, name: "Prompt 1") }
    let!(:prompt2) { create(:prompt, name: "Prompt 2") }
    let!(:execution1) { create(:llm_execution, usage: create(:usage, prompt: prompt1), cost_usd: 0.05) }
    let!(:execution2) { create(:llm_execution, usage: create(:usage, prompt: prompt2), cost_usd: 0.03) }

    it "breaks down costs by prompt" do
      breakdown = described_class.cost_breakdown(group_by: :prompt)
      
      expect(breakdown["Prompt 1"]).to eq(0.05)
      expect(breakdown["Prompt 2"]).to eq(0.03)
    end

    it "breaks down costs by model" do
      execution1.update!(model: "gpt-4")
      execution2.update!(model: "gpt-3.5-turbo")
      
      breakdown = described_class.cost_breakdown(group_by: :model)
      
      expect(breakdown["gpt-4"]).to eq(0.05)
      expect(breakdown["gpt-3.5-turbo"]).to eq(0.03)
    end

    it "breaks down costs by provider" do
      execution1.update!(provider: "openai")
      execution2.update!(provider: "anthropic")
      
      breakdown = described_class.cost_breakdown(group_by: :provider)
      
      expect(breakdown["openai"]).to eq(0.05)
      expect(breakdown["anthropic"]).to eq(0.03)
    end
  end

  describe ".error_analysis" do
    let!(:rate_limit_error) { create(:llm_execution, status: "error", error_message: "Rate limit exceeded") }
    let!(:auth_error) { create(:llm_execution, status: "error", error_message: "Unauthorized access") }
    let!(:network_error) { create(:llm_execution, status: "error", error_message: "Network connection failed") }

    it "categorizes errors by type" do
      analysis = described_class.error_analysis

      expect(analysis[:total_errors]).to eq(3)
      expect(analysis[:errors_by_type][:rate_limit]).to eq(1)
      expect(analysis[:errors_by_type][:authentication]).to eq(1)
      expect(analysis[:errors_by_type][:network]).to eq(1)
      expect(analysis[:recent_errors]).to be_an(Array)
    end
  end

  describe ".top_prompts" do
    let!(:popular_prompt) { create(:prompt, name: "Popular") }
    let!(:unpopular_prompt) { create(:prompt, name: "Unpopular") }
    let!(:popular_usages) { create_list(:usage_with_execution, 10, prompt: popular_prompt) }
    let!(:unpopular_usages) { create_list(:usage, 2, prompt: unpopular_prompt) }

    it "returns top prompts by usage" do
      top = described_class.top_prompts(limit: 2)

      expect(top.first[:name]).to eq("Popular")
      expect(top.first[:usage_count]).to eq(10)
      expect(top.first[:execution_count]).to eq(10)
      expect(top.first[:total_cost]).to be > 0
      expect(top.first[:success_rate]).to be_present
    end
  end
end