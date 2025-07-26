FactoryBot.define do
  factory :usage, class: "PromptEngine::Usage" do
    association :prompt, factory: :prompt
    association :prompt_version, factory: :prompt_version
    
    environment { Rails.env }
    session_id { SecureRandom.uuid }
    user_identifier { "user_#{SecureRandom.hex(4)}" }
    parameters_used { { "name" => "Test User", "topic" => "Test Topic" } }
    rendered_content { "Hello Test User, let's discuss Test Topic" }
    rendered_system_message { "You are a helpful assistant" }
    metadata { { "source" => "test" } }
    
    factory :usage_with_execution do
      after(:create) do |usage|
        create(:llm_execution, usage: usage)
      end
    end
    
    factory :usage_with_failed_execution do
      after(:create) do |usage|
        create(:llm_execution, :failed, usage: usage)
      end
    end
  end
end