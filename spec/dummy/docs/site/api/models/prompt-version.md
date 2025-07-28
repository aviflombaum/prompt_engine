---
title: "Prompt Version"
layout: "docs"
parent: "api/models"
nav_order: "promptversion"
---

# PromptEngine::PromptVersion Model Documentation

## 1. Model Overview
The `PromptVersion` model within the `PromptEngine` module represents a specific version of a prompt in a system designed to handle and maintain different versions of textual prompts. This model is crucial for version control, allowing changes to prompts to be tracked and managed over time. It also supports operations like restoring a prompt to a previous state.

## 2. Attributes

| Attribute        | Type       | Description                                           |
|------------------|------------|-------------------------------------------------------|
| `version_number` | integer    | The sequential number indicating the version of a prompt. |
| `content`        | string     | The actual textual content of the prompt version.     |
| `system_message` | string     | A message associated with the prompt, used for system purposes. |
| `model`          | string     | The model used for generating or interpreting the prompt. |
| `temperature`    | float      | Controls randomness in the generation process (higher means more random). |
| `max_tokens`     | integer    | The maximum number of tokens the prompt can generate or use. |
| `metadata`       | json       | A JSON structure storing additional data about the prompt version. |

## 3. Associations

- **belongs_to :prompt**
  - This association links each version to a specific prompt. It uses `PromptEngine::Prompt` as its class name.
- **has_many :playground_run_results**
  - Each prompt version can have multiple playground run results. These are instances where the prompt version has been executed or tested in a playground environment. The associated objects are deleted if the prompt version is destroyed.
- **has_many :eval_runs**
  - Similar to playground run results, each prompt version can have multiple evaluation runs that assess the prompt's performance or outcome. These are also deleted when the prompt version is destroyed.

## 4. Validations

- **Version Number**
  - Must be present and a numerical value greater than 0.
  - Must be unique within the scope of its associated prompt.
- **Content**
  - Must be present.
- **Immutability on Update**
  - Certain attributes (`content`, `system_message`, `model`, `temperature`, `max_tokens`) cannot be changed after creation.

## 5. Key Methods

### `restore!`
Restores the associated prompt's attributes to match those of this version, potentially creating a new version if changes are detected.
```ruby
prompt_version.restore!
```

### `to_prompt_attributes`
Returns a hash of the prompt version's attributes that are relevant for restoration or duplication.
```ruby
attributes = prompt_version.to_prompt_attributes
```

## 6. Common Usage Patterns

- **Creating a New Version**
  When a prompt is updated, a new `PromptVersion` instance is typically created to record the state of the prompt before changes.
  
- **Restoring to a Previous Version**
  To rollback changes or review historical data, the `restore!` method can be used to apply a previous version's attributes to the current prompt.

- **Version Tracking**
  Tracking changes over time can be managed by examining the `version_number` and associated metadata, allowing for detailed audits and historical analysis.

## 7. Important Notes or Caveats

- **Immutability**
  After creation, certain core attributes of a `PromptVersion` are immutable to ensure data consistency and reliability of version history. Attempting to change these attributes on update will raise validation errors.

- **Dependent Associations**
  Deleting a `PromptVersion` will also delete any associated `playground_run_results` and `eval_runs`, which should be considered when performing deletion operations to avoid unintentional data loss.

