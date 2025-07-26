FactoryBot.define do
  factory :llm_execution, class: "PromptEngine::LlmExecution" do
    association :usage, factory: :usage
    
    provider { "openai" }
    model { "gpt-4" }
    temperature { 0.7 }
    max_tokens { 500 }
    messages_sent { [
      { "role" => "system", "content" => "You are a helpful assistant" },
      { "role" => "user", "content" => "Hello" }
    ] }
    response_content { "Hello! How can I help you today?" }
    input_tokens { 1000 }
    output_tokens { 500 }
    total_tokens { 1500 }
    execution_time_ms { 1234.5 }
    cost_usd { 0.0315 } # (1000/1000 * 0.03) + (500/1000 * 0.03)
    status { "success" }
    response_metadata { { "model_version" => "gpt-4-0613" } }
    
    trait :pending do
      status { "pending" }
      response_content { nil }
      input_tokens { nil }
      output_tokens { nil }
      total_tokens { nil }
      execution_time_ms { nil }
      cost_usd { nil }
    end
    
    trait :failed do
      status { "error" }
      response_content { nil }
      error_message { "API Error: Rate limit exceeded" }
    end
    
    trait :timeout do
      status { "timeout" }
      response_content { nil }
      error_message { "Request timed out after 30 seconds" }
    end
    
    trait :anthropic do
      provider { "anthropic" }
      model { "claude-3-5-sonnet-20241022" }
    end
  end
end