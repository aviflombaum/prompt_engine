---
title: "Setting"
layout: "docs"
parent: "api/models"
nav_order: "setting"
---

# `PromptEngine::Setting` Model Documentation

## 1. Model Purpose
The `PromptEngine::Setting` model within the `PromptEngine` module is designed to manage application settings related to external API integrations, specifically with OpenAI and Anthropic. It uses encryption to securely store API keys and implements a singleton pattern to ensure only one settings record exists at any time.

## 2. Attributes

| Attribute          | Type   | Description                                         |
|--------------------|--------|-----------------------------------------------------|
| `openai_api_key`   | String | The API key for OpenAI services, stored encrypted.  |
| `anthropic_api_key`| String | The API key for Anthropic services, stored encrypted.|

## 3. Associations
This model does not have any associations with other models.

## 4. Validations
There are no specific validations implemented in this model. However, the singleton pattern ensures that only one instance of this model can exist.

## 5. Key Methods

### `self.instance`
- **Description**: Ensures that only one instance of the `Setting` model exists or creates one if none exists.
- **Usage**:
  ```ruby
  settings = PromptEngine::Setting.instance
  ```

### `openai_configured?`
- **Description**: Checks if the OpenAI API key is present.
- **Returns**: `true` if configured, `false` otherwise.
- **Usage**:
  ```ruby
  settings = PromptEngine::Setting.instance
  settings.openai_configured?  # => true or false
  ```

### `anthropic_configured?`
- **Description**: Checks if the Anthropic API key is present.
- **Returns**: `true` if configured, `false` otherwise.
- **Usage**:
  ```ruby
  settings = PromptEngine::Setting.instance
  settings.anthropic_configured?  # => true or false
  ```

### `masked_openai_api_key`
- **Description**: Returns a masked version of the OpenAI API key for display purposes, showing only the first and last 3 characters.
- **Returns**: Masked String or `nil`.
- **Usage**:
  ```ruby
  settings = PromptEngine::Setting.instance
  settings.masked_openai_api_key  # => "sk-...789"
  ```

### `masked_anthropic_api_key`
- **Description**: Returns a masked version of the Anthropic API key for similar purposes as `masked_openai_api_key`.
- **Returns**: Masked String or `nil`.
- **Usage**:
  ```ruby
  settings = PromptEngine::Setting.instance
  settings.masked_anthropic_api_key  # => "sk-...789"
  ```

### `mask_api_key`
- **Description**: A private method that masks any given API key.
- **Returns**: A string showing the first 3 and the last 3 characters of the key, with the middle characters replaced by ellipses.

## 6. Common Usage Patterns
The singleton pattern usage, as implemented in this model, is crucial for ensuring that configuration settings are consistently managed and accessed throughout the application. Common usage involves retrieving the single instance and checking or displaying API configurations:
```ruby
settings = PromptEngine::Setting.instance
if settings.openai_configured?
  puts settings.masked_openai_api_key
end
```

## 7. Important Notes or Caveats
- **Singleton Pattern**: It's important to ensure that operations which might lead to the creation of multiple instances (like direct use of `new` or `create`) are avoided.
- **Encryption**: The API keys are encrypted at the database level. Any direct access to these keys outside of the provided methods might expose unencrypted data or lead to data inconsistencies.
- **Masking Logic**: The masking logic assumes that the API key is at least 7 characters long. For shorter keys, it returns `"*****"`.

This documentation should provide a comprehensive understanding of the `PromptEngine::Setting` model's functionality and its usage within the Rails application.
