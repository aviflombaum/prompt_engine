# Seed cost configuration data for various AI models
# Prices are in USD per 1000 tokens
# Updated as of January 2025

puts "Seeding cost configurations..."

# OpenAI Models
PromptEngine::CostConfig.create_or_update_cost("openai", "gpt-4o", 0.00500, 0.01500, Date.new(2024, 1, 1))
PromptEngine::CostConfig.create_or_update_cost("openai", "gpt-4o-mini", 0.00015, 0.00060, Date.new(2024, 1, 1))
PromptEngine::CostConfig.create_or_update_cost("openai", "gpt-4-turbo", 0.01000, 0.03000, Date.new(2024, 1, 1))
PromptEngine::CostConfig.create_or_update_cost("openai", "gpt-3.5-turbo", 0.00050, 0.00150, Date.new(2024, 1, 1))
PromptEngine::CostConfig.create_or_update_cost("openai", "gpt-4", 0.03000, 0.06000, Date.new(2024, 1, 1))

# Anthropic Models
PromptEngine::CostConfig.create_or_update_cost("anthropic", "claude-3-5-sonnet-20241022", 0.00300, 0.01500, Date.new(2024, 1, 1))
PromptEngine::CostConfig.create_or_update_cost("anthropic", "claude-3-opus-20240229", 0.01500, 0.07500, Date.new(2024, 1, 1))
PromptEngine::CostConfig.create_or_update_cost("anthropic", "claude-3-sonnet-20240229", 0.00300, 0.01500, Date.new(2024, 1, 1))
PromptEngine::CostConfig.create_or_update_cost("anthropic", "claude-3-haiku-20240307", 0.00025, 0.00125, Date.new(2024, 1, 1))

puts "Cost configurations seeded successfully!"