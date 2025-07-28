---
title: "Parameter Parser"
layout: "docs"
parent: "api/models"
nav_order: "parameterparser"
---

# Documentation for `ParameterParser` in `PromptEngine` Module

## Model Overview

The `ParameterParser` class in the `PromptEngine` module is designed to manage and manipulate parameter placeholders within strings. It provides functionality to extract parameter information from a given string, replace these parameters with actual values, and check if the string contains any parameters. This class is particularly useful in scenarios where dynamic content generation based on templates is required, such as in configuration management, templating engines, or automated messaging systems.

## Attributes

| Name     | Type       | Description                              |
|----------|------------|------------------------------------------|
| `content`| `String`   | The string content containing parameters.|

## Associations

The `ParameterParser` class does not have any model associations.

## Validations

There are no specific validations implemented in the `ParameterParser` class as it primarily deals with string manipulation and does not enforce business rules on the content structure beyond parameter parsing.

## Key Methods

### `initialize(content)`

Initializes a new instance of `ParameterParser` with the provided content.

**Parameters:**
- `content`: A string containing potential parameters enclosed in double curly braces `{{param}}`.

**Example:**
```ruby
parser = PromptEngine::ParameterParser.new("Hello {{user}}, welcome to {{site_name}}!")
```

### `extract_parameters`

Extracts unique parameter names from the `content` attribute, returning them as an array of hashes with details about each parameter.

**Returns:**
- Array of hashes, each containing:
  - `name`: The parameter name.
  - `placeholder`: The placeholder string as it appears in the content.
  - `required`: A boolean indicating that the parameter is required (always `true`).

**Example:**
```ruby
parser = PromptEngine::ParameterParser.new("Hello {{user}}, welcome to {{site_name}}!")
parameters = parser.extract_parameters
# => [{name: "user", placeholder: "{{user}}", required: true}, {name: "site_name", placeholder: "{{site_name}}", required: true}]
```

### `replace_parameters(parameters = {})`

Replaces the parameter placeholders in the content with values provided in a hash.

**Parameters:**
- `parameters`: A hash where keys are the parameter names and values are the corresponding values to replace in the content.

**Returns:**
- A new string with parameters replaced by their respective values.

**Example:**
```ruby
parser = PromptEngine::ParameterParser.new("Hello {{user}}, welcome to {{site_name}}!")
updated_content = parser.replace_parameters({'user' => 'Alice', 'site_name' => 'ExampleCorp'})
# => "Hello Alice, welcome to ExampleCorp!"
```

### `has_parameters?`

Checks if there are any parameters in the content.

**Returns:**
- `true` if there are parameters, `false` otherwise.

**Example:**
```ruby
parser = PromptEngine::ParameterParser.new("Hello {{user}}, welcome to {{site_name}}!")
parser.has_parameters?
# => true
```

## Common Usage Patterns

The `ParameterParser` class can be used in various applications where template-based generation is needed. For example:
- Generating personalized emails or messages.
- Configuring application settings dynamically.
- Creating template-based documentations or reports.

## Important Notes or Caveats

- The parameter parsing mechanism strictly identifies placeholders formatted as `{{parameter_name}}`. Any deviation from this format will not be recognized as a parameter.
- The `replace_parameters` method does not perform any type validation on the parameter values; it converts all values to strings.
- All parameters are considered required in the current implementation, as indicated by the `required: true` attribute in the `extract_parameters` method result.

This documentation covers the core functionalities of the `ParameterParser` class to assist developers in integrating and utilizing its capabilities effectively within their projects.
