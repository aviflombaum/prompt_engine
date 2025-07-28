---
title: "Configuration"
layout: "docs"
nav_order: 4
---

# Configuration

PromptEngine can be configured through Rails credentials and initializers.

## API Credentials

Configure your AI provider credentials:

```bash
rails credentials:edit
```

```yaml
# Required: At least one provider
openai:
  api_key: sk-your-openai-key
  
anthropic:
  api_key: sk-ant-your-anthropic-key
```

## Initializer Options

Create an initializer for advanced configuration:

```ruby
# config/initializers/prompt_engine.rb
PromptEngine.configure do |config|
  # Default model for playground
  config.default_model = "gpt-4"
  
  # Enable/disable features
  config.enable_playground = true
  config.enable_analytics = false
  
  # Security
  config.require_authentication = true
  config.admin_role = :admin
end
```

## Environment Variables

Supported environment variables:

- `PROMPT_ENGINE_API_TIMEOUT` - API request timeout (default: 30)
- `PROMPT_ENGINE_MAX_TOKENS` - Maximum tokens per request (default: 4000)
- `PROMPT_ENGINE_CACHE_ENABLED` - Enable response caching (default: false)

## Database Configuration

PromptEngine works with PostgreSQL and MySQL. Ensure your database supports:

- JSON columns (for model_config)
- Full-text search (optional, for better search)
- UUID support (optional, for better IDs)
