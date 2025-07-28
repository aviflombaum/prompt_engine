---
title: "Playground Run Result"
layout: "docs"
parent: "api/models"
nav_order: "playgroundrunresult"
---

# PlaygroundRunResult Model Documentation

## 1. Model Description

The `PlaygroundRunResult` model within the `PromptEngine` module is designed to record the results of different runs executed in a playground environment. This environment is typically used for testing and experimenting with various prompt versions under development. Each record captures essential details about the run, such as the provider, model used, the actual prompt rendered, the response received, execution time, and other relevant parameters.

## 2. Table of Attributes

| Attribute        | Type    | Description |
|------------------|---------|-------------|
| `provider`       | String  | Identifies the provider of the model used to generate the response. |
| `model`          | String  | The model identifier used for the run. |
| `rendered_prompt`| Text    | The actual prompt text that was rendered and sent to the model. |
| `response`       | Text    | The response returned by the model after processing the prompt. |
| `execution_time` | Float   | The time taken to execute the run, typically measured in seconds. |
| `token_count`    | Integer | Optional; the number of tokens processed in the run. |
| `parameters`     | Text    | Serialized JSON storing additional parameters or configurations used during the run. |

## 3. List of Associations

- **`belongs_to :prompt_version`**: This association links each `PlaygroundRunResult` to a specific version of a prompt (`PromptEngine::PromptVersion`). It indicates which version of the prompt was used during the run.

## 4. List of Validations

- **`provider`**: Must be present. Ensures that every run result records the provider of the model.
- **`model`**: Must be present. Ensures that the model used for the run is always recorded.
- **`rendered_prompt`**: Must be present. Ensures the prompt sent to the model is logged.
- **`response`**: Must be present. Ensures that a response received from the model is recorded.
- **`execution_time`**: Must be present and a non-negative number. Validates that the recorded execution time is valid and meaningful.
- **`token_count`**: Must be a non-negative number if provided. Allows flexibility in recording how many tokens were used without making it a mandatory field.

## 5. Key Methods

- **Scopes**:
  - `.recent`: Returns results ordered by their creation time in descending order.
    ```ruby
    PromptEngine::PlaygroundRunResult.recent
    ```
  - `.by_provider(provider)`: Filters results by the specified provider.
    ```ruby
    PromptEngine::PlaygroundRunResult.by_provider('Google')
    ```
  - `.successful`: Filters results that have a non-null response.
    ```ruby
    PromptEngine::PlaygroundRunResult.successful
    ```

## 6. Common Usage Patterns

- Retrieving the most recent run results:
  ```ruby
  PromptEngine::PlaygroundRunResult.recent.limit(10)
  ```
- Fetching successful runs for a specific provider:
  ```ruby
  PromptEngine::PlaygroundRunResult.by_provider('AWS').successful
  ```
- Analyzing average execution time across successful runs:
  ```ruby
  PromptEngine::PlaygroundRunResult.successful.average(:execution_time)
  ```

## 7. Important Notes or Caveats

- **Data Integrity**: It is crucial to ensure that the `prompt_version_id` associated with each result accurately reflects the prompt version used during the run to maintain data integrity.
- **Performance Considerations**: When dealing with large datasets, consider indexing frequently queried fields like `provider` and `created_at` to improve query performance.
- **Serialization**: The `parameters` attribute uses JSON serialization to store additional data flexibly. Ensure that this data is serialized and deserialized correctly to avoid data format issues.

This documentation provides a comprehensive overview of the `PlaygroundRunResult` model, detailing its purpose, structure, and common use cases within the system.
