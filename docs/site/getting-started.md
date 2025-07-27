---
title: "Getting Started"
layout: "docs"
nav_order: 2
---

# Getting Started with PromptEngine

This guide will help you get PromptEngine up and running quickly.

## Prerequisites

- Ruby 3.0+
- Rails 8.0.2+
- PostgreSQL or MySQL database

## Quick Setup

1. Add PromptEngine to your Gemfile:

```ruby
gem 'prompt_engine'
```

2. Install the gem:

```bash
bundle install
```

3. Mount the engine in your routes:

```ruby
# config/routes.rb
Rails.application.routes.draw do
  mount PromptEngine::Engine => "/prompt_engine"
end
```

4. Install migrations:

```bash
bin/rails prompt_engine:install:migrations
bin/rails db:migrate
```

5. Configure API credentials:

```bash
rails credentials:edit
```

Add your API keys:

```yaml
openai:
  api_key: sk-your-openai-key
anthropic:
  api_key: sk-ant-your-anthropic-key
```

6. Start your Rails server and visit `/prompt_engine`

## Next Steps

- [Create your first prompt](guides/basic-usage.md)
- [Configure advanced settings](configuration.md)
- [Explore the API](api/)