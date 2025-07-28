---
title: "Prompt"
layout: "docs"
parent: "api/models"
nav_order: "prompt"
---

# `Prompt` Model Documentation

## Overview
The `Prompt` model is part of the `PromptEngine` module in a Ruby on Rails application. It is designed to manage and render dynamic content based on a set of parameters and versions. This model handles the creation, versioning, and rendering of prompts, ensuring content integrity and providing tools for content management such as version restoration and parameter synchronization.

## Attributes
| Attribute        | Type          | Description |
|------------------|---------------|-------------|
| `name`           | `string`      | The name of the prompt, used for identification. |
| `content`        | `text`        | The actual content of the prompt which can include variables for dynamic data insertion. |
| `slug`           | `string`      | A URL-friendly identifier automatically generated from the name. |
| `status`         | `enum`        | The status of the prompt, which can be `draft`, `active`, or `archived`. |
| `change_summary` | `string`      | A temporary attribute to hold summaries of what was changed during an update. This is not persisted in the database. |

## Associations
- **Versions**: The prompt has many versions (`PromptEngine::PromptVersion`), which store historical changes of the content and other attributes. Versions are ordered by `version_number` in descending order and dependent on the prompt's deletion.
- **Parameters**: The prompt has many parameters (`PromptEngine::Parameter`), which define the variables used within the content. These are also dependent on the prompt's deletion and are ordered by a custom scope.
- **Eval Sets**: The prompt has many evaluation sets (`PromptEngine::EvalSet`), used for assessing the prompt's effectiveness or accuracy in different scenarios. These are also deleted when the prompt is removed.

## Validations
- **Name**: Must be present and unique within the same status.
- **Content**: Must be present.
- **Slug**: Must be present, unique across all prompts, and must match the regex pattern `\A[a-z0-9-]+\z`, ensuring it is URL-friendly.

## Key Methods

### `render(options = {})`
Renders the prompt with given parameters and options. This method supports rendering specific versions and applying overrides such as model and temperature settings.
```ruby
prompt.render(model: 'gpt-3', temperature: 0.5, content: "Hello, {{name}}!")
```

### `sync_parameters!`
Synchronizes the parameters of the prompt with those detected in its content. It adds new parameters detected and removes those no longer present.
```ruby
prompt.sync_parameters!
```

### `restore_version!(version_number)`
Restores the prompt's content and attributes to a specified version.
```ruby
prompt.restore_version!(3)
```

## Common Usage Patterns

### Creating a new Prompt
When creating a new prompt, you can specify the name, content, and optionally, the initial parameters. After creation, the initial version of the prompt is automatically generated.
```ruby
PromptEngine::Prompt.create(name: "Greeting", content: "Hello, {{name}}!")
```

### Updating a Prompt
When a prompt is updated, if any of the versioned attributes (`content`, `system_message`, `model`, `temperature`, `max_tokens`, `metadata`) have changed, a new version is automatically created.
```ruby
prompt.update(content: "Goodbye, {{name}}!")
```

### Rendering a Prompt
To render a prompt with parameters:
```ruby
prompt.render(name: "Alice")
```

## Notes and Caveats

- The `slug` is generated automatically on creation from the `name` but can be manually overridden if needed. Care should be taken to ensure it remains unique and URL-friendly.
- Parameter synchronization (`sync_parameters!`) is performed after every update to the content, ensuring that the parameters are always aligned with the content variables.
- The system is designed to handle concurrent updates safely, but race conditions can still occur under high load or with complex interactions. Proper database transaction management is recommended when updating prompts and parameters programmatically.
