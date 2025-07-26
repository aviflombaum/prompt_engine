FactoryBot.define do
  factory :cost_config, class: "PromptEngine::CostConfig" do
    provider { "openai" }
    model { "gpt-4" }
    input_token_cost { 0.03 }  # $0.03 per 1k tokens
    output_token_cost { 0.06 } # $0.06 per 1k tokens
    effective_from { Date.new(2024, 1, 1) }
    effective_until { nil }
    
    trait :gpt_4o do
      model { "gpt-4o" }
      input_token_cost { 0.005 }
      output_token_cost { 0.015 }
    end
    
    trait :gpt_35_turbo do
      model { "gpt-3.5-turbo" }
      input_token_cost { 0.0005 }
      output_token_cost { 0.0015 }
    end
    
    trait :claude_sonnet do
      provider { "anthropic" }
      model { "claude-3-5-sonnet-20241022" }
      input_token_cost { 0.003 }
      output_token_cost { 0.015 }
    end
    
    trait :expired do
      effective_from { 1.year.ago }
      effective_until { 1.month.ago }
    end
    
    trait :future do
      effective_from { 1.month.from_now }
      effective_until { nil }
    end
  end
end