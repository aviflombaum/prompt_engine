---
title: "Playground Executor"
layout: "docs"
parent: "api/services"
nav_order: "playgroundexecutor"
---

# Documentation for PlaygroundExecutor Class

## Purpose and Responsibility

The `PlaygroundExecutor` class in the `PromptEngine` module is designed to execute prompts using various language models provided by external APIs such as Anthropic and OpenAI. Its main responsibilities include:
- Parsing and replacing parameters in prompt content.
- Configuring and utilizing the RubyLLM library for API interactions.
- Handling prompt execution and managing responses, including formatting and error handling.

## Usage Examples

### Basic Usage

Here's how you can use the `PlaygroundExecutor` to execute a prompt using a specific provider:

```ruby
prompt = Prompt.new(content: "Hello, what is your name?", temperature: 0.5)
executor = PromptEngine::PlaygroundExecutor.new(
    prompt: prompt,
    provider: "openai",
    api_key: "your_openai_api_key"
)

result = executor.execute
puts result[:response]  # Outputs the response from the model
```

### Advanced Usage with Parameters

If your prompt includes parameters that need to be dynamically replaced:

```ruby
prompt = Prompt.new(content: "Hello, {name}! How can I assist you today?")
executor = PromptEngine::PlaygroundExecutor.new(
    prompt: prompt,
    provider: "anthropic",
    api_key: "your_anthropic_api_key",
    parameters: {name: "Alice"}
)

result = executor.execute
puts result[:response]  # Outputs the response with the name replaced
```

## Method Documentation

### `initialize(prompt:, provider:, api_key:, parameters: {})`
Initializes a new instance of the `PlaygroundExecutor`.
- **Parameters**:
  - `prompt`: An instance of `Prompt` containing the content and optional attributes like temperature.
  - `provider`: A string indicating the provider (`"anthropic"` or `"openai"`).
  - `api_key`: The API key for the respective provider.
  - `parameters`: An optional hash of parameters to replace in the prompt content.
  
### `execute`
Executes the prompt and returns a hash with details about the execution.
- **Returns**:
  - A hash containing: `response`, `execution_time`, `token_count`, `model`, and `provider`.

## Error Scenarios

Errors are handled by the `handle_error` method which processes various exceptions like:
- **Net::HTTPUnauthorized**: Raises "Invalid API key".
- **Net::HTTPTooManyRequests**: Raises "Rate limit exceeded. Please try again later."
- **Net::HTTPError**: Raises "Network error. Please check your connection and try again."
- **ArgumentError**: Re-raises the error if there are missing or invalid inputs.

## Best Practices

- **Validation**: Always ensure that the provider and API key are correctly specified to avoid runtime errors.
- **Error Handling**: Implement additional error handling in the calling code to gracefully manage exceptions raised by `PlaygroundExecutor`.
- **Parameter Management**: Use the parameters feature to customize prompt contents dynamically, aiding in more flexible interactions.
- **API Key Security**: Securely manage API keys, avoiding hard-coded values in the source code.

By following these guidelines, you can effectively utilize the `PlaygroundExecutor` for robust and efficient prompt management and execution.
