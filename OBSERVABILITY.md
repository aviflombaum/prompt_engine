# PromptEngine Observability Implementation Plan

## Overview

This document outlines the implementation plan for adding comprehensive observability and logging capabilities to PromptEngine. The goal is to track all prompt usage, including versions used, messages sent to LLMs, responses received, metadata, and costs.

## Core Requirements

1. **Usage Tracking**: Log every time a prompt is rendered and used
2. **Version Tracking**: Record which version of a prompt was used
3. **Message Logging**: Capture the actual messages sent to LLMs
4. **Response Logging**: Store responses, tokens used, and timing data
5. **Cost Tracking**: Calculate and store costs based on model and token usage
6. **Analytics**: Provide insights into prompt performance and usage patterns

## Architecture Design

### Database Schema

#### 1. `prompt_engine_usages`
Tracks each time a prompt is rendered (whether or not it's sent to an LLM).

```ruby
create_table :prompt_engine_usages do |t|
  t.references :prompt, null: false, foreign_key: { to_table: :prompt_engine_prompts }
  t.references :prompt_version, null: false, foreign_key: { to_table: :prompt_engine_prompt_versions }
  t.string :environment # development, staging, production
  t.string :session_id # Optional tracking ID from host app
  t.string :user_identifier # Optional user ID from host app
  t.jsonb :parameters_used, default: {} # The actual parameters passed
  t.text :rendered_content # The final rendered prompt content
  t.text :rendered_system_message # The final system message
  t.jsonb :metadata, default: {} # Additional tracking data
  t.timestamps
end
```

#### 2. `prompt_engine_llm_executions`
Tracks actual LLM API calls and responses.

```ruby
create_table :prompt_engine_llm_executions do |t|
  t.references :usage, null: false, foreign_key: { to_table: :prompt_engine_usages }
  t.string :provider # anthropic, openai, etc.
  t.string :model # gpt-4, claude-3-5-sonnet, etc.
  t.float :temperature
  t.integer :max_tokens
  t.jsonb :messages_sent, default: [] # Array of messages sent to LLM
  t.text :response_content # The LLM's response
  t.integer :input_tokens
  t.integer :output_tokens
  t.integer :total_tokens
  t.decimal :execution_time_ms # Time in milliseconds
  t.decimal :cost_usd, precision: 10, scale: 6 # Cost in USD
  t.string :status # success, error, timeout
  t.text :error_message
  t.jsonb :response_metadata, default: {} # Additional response data
  t.timestamps
end
```

#### 3. `prompt_engine_cost_configs`
Stores cost information for different models.

```ruby
create_table :prompt_engine_cost_configs do |t|
  t.string :provider, null: false
  t.string :model, null: false
  t.decimal :input_token_cost, precision: 10, scale: 8 # Cost per 1k tokens
  t.decimal :output_token_cost, precision: 10, scale: 8 # Cost per 1k tokens
  t.date :effective_from
  t.date :effective_until
  t.timestamps
  
  t.index [:provider, :model, :effective_from]
end
```

### Core Models

#### `PromptEngine::Usage`
```ruby
module PromptEngine
  class Usage < ApplicationRecord
    self.table_name = "prompt_engine_usages"
    
    belongs_to :prompt
    belongs_to :prompt_version
    has_one :llm_execution, dependent: :destroy
    
    scope :by_environment, ->(env) { where(environment: env) }
    scope :recent, -> { order(created_at: :desc) }
    scope :with_execution, -> { joins(:llm_execution) }
    
    def executed?
      llm_execution.present?
    end
    
    def successful?
      llm_execution&.successful?
    end
    
    def cost
      llm_execution&.cost_usd || 0
    end
  end
end
```

#### `PromptEngine::LlmExecution`
```ruby
module PromptEngine
  class LlmExecution < ApplicationRecord
    self.table_name = "prompt_engine_llm_executions"
    
    belongs_to :usage
    has_one :prompt, through: :usage
    
    scope :successful, -> { where(status: "success") }
    scope :failed, -> { where(status: "error") }
    scope :by_provider, ->(provider) { where(provider: provider) }
    scope :by_model, ->(model) { where(model: model) }
    
    def successful?
      status == "success"
    end
    
    def calculate_cost
      cost_config = CostConfig.for_model(provider, model, created_at)
      return 0 unless cost_config
      
      input_cost = (input_tokens.to_f / 1000) * cost_config.input_token_cost
      output_cost = (output_tokens.to_f / 1000) * cost_config.output_token_cost
      input_cost + output_cost
    end
  end
end
```

#### `PromptEngine::CostConfig`
```ruby
module PromptEngine
  class CostConfig < ApplicationRecord
    self.table_name = "prompt_engine_cost_configs"
    
    validates :provider, :model, :input_token_cost, :output_token_cost, presence: true
    
    def self.for_model(provider, model, date = Date.current)
      where(provider: provider, model: model)
        .where("effective_from <= ?", date)
        .where("effective_until IS NULL OR effective_until >= ?", date)
        .order(effective_from: :desc)
        .first
    end
  end
end
```

### Service Layer

#### `PromptEngine::ObservabilityService`
Central service for logging prompt usage and executions.

```ruby
module PromptEngine
  class ObservabilityService
    class << self
      def log_usage(prompt:, version:, parameters:, rendered_content:, rendered_system_message:, **options)
        Usage.create!(
          prompt: prompt,
          prompt_version: version,
          parameters_used: parameters,
          rendered_content: rendered_content,
          rendered_system_message: rendered_system_message,
          environment: detect_environment,
          session_id: options[:session_id],
          user_identifier: options[:user_identifier],
          metadata: options[:metadata] || {}
        )
      end
      
      def log_execution(usage:, provider:, model:, **execution_data)
        execution = usage.build_llm_execution(
          provider: provider,
          model: model,
          temperature: execution_data[:temperature],
          max_tokens: execution_data[:max_tokens],
          messages_sent: execution_data[:messages],
          status: "pending"
        )
        
        execution.save!
        execution
      end
      
      def update_execution(execution, response_data)
        execution.update!(
          response_content: response_data[:content],
          input_tokens: response_data[:input_tokens],
          output_tokens: response_data[:output_tokens],
          total_tokens: response_data[:total_tokens],
          execution_time_ms: response_data[:execution_time_ms],
          status: "success",
          response_metadata: response_data[:metadata] || {}
        )
        
        # Calculate and update cost
        execution.update!(cost_usd: execution.calculate_cost)
      end
      
      def log_execution_error(execution, error)
        execution.update!(
          status: "error",
          error_message: error.message
        )
      end
      
      private
      
      def detect_environment
        Rails.env
      end
    end
  end
end
```

### Integration Points

#### 1. Update `PromptEngine::RenderedPrompt`
Add observability hooks to the `execute_with` method:

```ruby
def execute_with(client, **options)
  # Log the usage
  usage = ObservabilityService.log_usage(
    prompt: prompt,
    version: prompt.version_at(version_number),
    parameters: parameters,
    rendered_content: content,
    rendered_system_message: system_message,
    session_id: options.delete(:session_id),
    user_identifier: options.delete(:user_identifier),
    metadata: options.delete(:tracking_metadata)
  )
  
  # Prepare execution logging
  execution = ObservabilityService.log_execution(
    usage: usage,
    provider: detect_provider(client),
    model: model,
    temperature: temperature,
    max_tokens: max_tokens,
    messages: messages
  )
  
  start_time = Time.current
  
  begin
    # Execute based on client type with event handlers for RubyLLM
    response = case client.class.name
    when /RubyLLM/, /Anthropic/
      execute_with_ruby_llm(client, execution, options)
    when /OpenAI/
      execute_with_openai(client, execution, options)
    else
      raise ArgumentError, "Unknown client type: #{client.class.name}"
    end
    
    response
  rescue => e
    ObservabilityService.log_execution_error(execution, e)
    raise
  end
end

private

def execute_with_ruby_llm(client, execution, options)
  params = to_ruby_llm_params(**options)
  
  # Create chat instance
  chat = client.chat(**params)
  
  # Add event handlers
  response_data = {}
  
  chat.on_new_message do
    # Message started
  end
  
  chat.on_end_message do |message|
    if message
      execution_time_ms = (Time.current - start_time) * 1000
      
      response_data = {
        content: message.content,
        input_tokens: message.input_tokens,
        output_tokens: message.output_tokens,
        total_tokens: (message.input_tokens || 0) + (message.output_tokens || 0),
        execution_time_ms: execution_time_ms,
        metadata: extract_metadata(message)
      }
      
      ObservabilityService.update_execution(execution, response_data)
    end
  end
  
  # Execute the chat
  chat.ask(content)
end

def execute_with_openai(client, execution, options)
  params = to_openai_params(**options)
  start_time = Time.current
  
  response = client.chat(parameters: params)
  
  execution_time_ms = (Time.current - start_time) * 1000
  
  # Extract token usage from OpenAI response
  usage_data = response.dig("usage") || {}
  
  response_data = {
    content: response.dig("choices", 0, "message", "content"),
    input_tokens: usage_data["prompt_tokens"],
    output_tokens: usage_data["completion_tokens"],
    total_tokens: usage_data["total_tokens"],
    execution_time_ms: execution_time_ms,
    metadata: response.except("choices", "usage")
  }
  
  ObservabilityService.update_execution(execution, response_data)
  
  response
end
```

#### 2. Update `PromptEngine.render`
Add basic usage logging for non-execution cases:

```ruby
module PromptEngine
  class << self
    def render(slug, **options)
      # Extract tracking options
      tracking_options = options.slice(:session_id, :user_identifier, :tracking_metadata)
      
      prompt = find(slug)
      rendered = prompt.render(**options)
      
      # Log usage if tracking is enabled and not already logged
      if tracking_enabled? && !options[:skip_tracking]
        ObservabilityService.log_usage(
          prompt: prompt,
          version: prompt.version_at(rendered.version_number),
          parameters: rendered.parameters,
          rendered_content: rendered.content,
          rendered_system_message: rendered.system_message,
          **tracking_options
        )
      end
      
      rendered
    end
    
    private
    
    def tracking_enabled?
      # Can be configured
      true
    end
  end
end
```

#### 3. Update `PlaygroundExecutor`
Add execution logging:

```ruby
def execute
  validate_inputs!
  
  # Create usage record
  usage = ObservabilityService.log_usage(
    prompt: prompt,
    version: prompt.current_version,
    parameters: parameters,
    rendered_content: processed_content,
    rendered_system_message: prompt.system_message,
    metadata: { source: "playground" }
  )
  
  # Create execution record
  execution = ObservabilityService.log_execution(
    usage: usage,
    provider: provider,
    model: MODELS[provider],
    temperature: prompt.temperature,
    max_tokens: prompt.max_tokens,
    messages: build_messages
  )
  
  start_time = Time.current
  
  begin
    # Execute with RubyLLM
    # ... existing execution code ...
    
    # Update execution with response
    ObservabilityService.update_execution(execution, {
      content: response_content,
      input_tokens: response.input_tokens,
      output_tokens: response.output_tokens,
      total_tokens: token_count,
      execution_time_ms: execution_time * 1000,
      metadata: { playground: true }
    })
    
    # Return existing response format
    {
      response: response_content,
      execution_time: execution_time,
      token_count: token_count,
      model: MODELS[provider],
      provider: provider
    }
  rescue => e
    ObservabilityService.log_execution_error(execution, e)
    handle_error(e)
  end
end
```

### Analytics Features

#### 1. Usage Analytics Service
```ruby
module PromptEngine
  class AnalyticsService
    class << self
      def usage_stats(prompt: nil, date_range: nil)
        scope = Usage.all
        scope = scope.where(prompt: prompt) if prompt
        scope = scope.where(created_at: date_range) if date_range
        
        {
          total_uses: scope.count,
          total_executions: scope.joins(:llm_execution).count,
          success_rate: calculate_success_rate(scope),
          total_cost: scope.joins(:llm_execution).sum("prompt_engine_llm_executions.cost_usd"),
          average_tokens: scope.joins(:llm_execution).average("prompt_engine_llm_executions.total_tokens"),
          by_environment: scope.group(:environment).count,
          by_model: scope.joins(:llm_execution).group("prompt_engine_llm_executions.model").count
        }
      end
      
      def prompt_performance(prompt, date_range: 30.days.ago..Time.current)
        executions = prompt.usages
          .joins(:llm_execution)
          .where(created_at: date_range)
          .includes(:llm_execution)
        
        {
          total_executions: executions.count,
          average_latency_ms: executions.average("prompt_engine_llm_executions.execution_time_ms"),
          error_rate: calculate_error_rate(executions),
          cost_by_day: cost_by_day(executions),
          usage_by_version: usage_by_version(prompt, date_range)
        }
      end
    end
  end
end
```

### Cost Management

#### Seed Initial Cost Data
```ruby
# db/seeds/cost_configs.rb
PromptEngine::CostConfig.create!([
  # OpenAI
  { provider: "openai", model: "gpt-4o", input_token_cost: 0.00500, output_token_cost: 0.01500, effective_from: Date.new(2024, 1, 1) },
  { provider: "openai", model: "gpt-4o-mini", input_token_cost: 0.00015, output_token_cost: 0.00060, effective_from: Date.new(2024, 1, 1) },
  { provider: "openai", model: "gpt-3.5-turbo", input_token_cost: 0.00050, output_token_cost: 0.00150, effective_from: Date.new(2024, 1, 1) },
  
  # Anthropic
  { provider: "anthropic", model: "claude-3-5-sonnet-20241022", input_token_cost: 0.00300, output_token_cost: 0.01500, effective_from: Date.new(2024, 1, 1) },
  { provider: "anthropic", model: "claude-3-haiku-20240307", input_token_cost: 0.00025, output_token_cost: 0.00125, effective_from: Date.new(2024, 1, 1) }
])
```

## Implementation Steps

### Phase 1: Core Infrastructure
1. Create database migrations for all observability tables
2. Implement core models (Usage, LlmExecution, CostConfig)
3. Create ObservabilityService
4. Add seed data for cost configurations

### Phase 2: Integration
1. Update RenderedPrompt#execute_with with RubyLLM event handlers
2. Add basic logging to PromptEngine.render
3. Update PlaygroundExecutor to log executions
4. Handle both RubyLLM and non-RubyLLM execution paths

### Phase 3: Analytics
1. Build AnalyticsService with usage statistics
2. Create analytics controllers and views
3. Add dashboard with charts and metrics
4. Implement cost tracking and reporting

### Phase 4: Advanced Features
1. Add filtering and search to analytics
2. Implement usage alerts and thresholds
3. Add export functionality for reports
4. Create API endpoints for programmatic access

## Testing Strategy

### Unit Tests
- Model validations and associations
- Service object methods
- Cost calculations
- Analytics calculations

### Integration Tests
- End-to-end prompt rendering with logging
- RubyLLM event handler integration
- PlaygroundExecutor logging
- Error handling and recovery

### System Tests
- Analytics dashboard functionality
- Usage tracking across different scenarios
- Cost reporting accuracy

## Performance Considerations

1. **Async Logging**: Consider moving logging to background jobs for high-traffic apps
2. **Data Retention**: Implement data archival/cleanup policies
3. **Indexing**: Add appropriate database indexes for analytics queries
4. **Caching**: Cache expensive analytics calculations

## Security Considerations

1. **PII Protection**: Ensure sensitive data in parameters/responses can be filtered
2. **Access Control**: Limit analytics access to authorized users
3. **Data Encryption**: Consider encrypting stored messages/responses
4. **Audit Trail**: Track who accesses analytics data

## Future Enhancements

1. **Real-time Analytics**: WebSocket updates for live dashboards
2. **Anomaly Detection**: Alert on unusual usage patterns
3. **A/B Testing Integration**: Track performance across prompt versions
4. **Export APIs**: Integrate with external analytics tools
5. **Multi-tenant Support**: Isolate analytics by organization