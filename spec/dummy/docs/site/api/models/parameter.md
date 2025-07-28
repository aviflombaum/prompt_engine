---
title: "Parameter"
layout: "docs"
parent: "api/models"
nav_order: "parameter"
---

# Documentation for PromptEngine::Parameter Model

## Overview
The `PromptEngine::Parameter` model represents a configurable parameter used within the `PromptEngine` system. Each parameter defines a specific piece of data that can be customized in prompts, such as its type, whether it is required, and default values. This allows for dynamic customization of user prompts based on predefined rules and types.

## Attributes and Types

| Attribute       | Type    | Description                                                       |
|-----------------|---------|-------------------------------------------------------------------|
| `name`          | string  | The unique identifier for the parameter within a prompt.          |
| `parameter_type`| string  | Defines the data type of the parameter (e.g., string, integer).   |
| `required`      | boolean | Indicates whether the parameter must be provided.                 |
| `default_value` | string  | The default value of the parameter if none is provided.           |
| `validation_rules` | json  | Custom validation rules that apply to the parameter value.        |
| `description`   | text    | A brief description of the parameter and its usage.               |
| `example_value` | string  | An example value that illustrates what can be expected for this parameter. |

## Associations

- **belongs_to :prompt**
  - Each `Parameter` belongs to a `Prompt`. This association links each parameter to a specific prompt within the system, defining the context in which the parameter is used.

## Validations

- **Name**
  - Must be present and unique within the scope of its associated prompt.
  - Must start with a letter or underscore and contain only letters, numbers, and underscores.
- **Parameter Type**
  - Must be present and one of the predefined types: `string`, `integer`, `decimal`, `boolean`, `datetime`, `date`, `array`, `json`.
- **Required**
  - Must be a boolean value indicating whether a parameter is required.

## Key Methods

### `cast_value(value)`
Converts the input `value` to the type specified by `parameter_type`. This is particularly useful for ensuring data integrity before processing or storing parameter values.
```ruby
parameter = PromptEngine::Parameter.find(1)
converted_value = parameter.cast_value("123")  # Assuming the parameter_type is 'integer'
```

### `validate_value(value)`
Validates the input `value` against the parameter's validation rules. Returns an array of error messages if validations fail.
```ruby
parameter = PromptEngine::Parameter.find(1)
errors = parameter.validate_value("test input")
```

### `form_input_options`
Generates a hash of options suitable for building form inputs based on the parameter's type and validation rules. This helps in dynamically creating forms based on parameter definitions.
```ruby
parameter = PromptEngine::Parameter.find(1)
form_options = parameter.form_input_options
```

## Common Usage Patterns

1. **Dynamic Form Generation**: Use `form_input_options` to generate form fields dynamically in a web application based on the parameters defined for a prompt.
2. **Data Validation**: Before processing user inputs, use `validate_value` to ensure that they meet the defined criteria for each parameter.
3. **Data Casting**: Use `cast_value` to convert user inputs into their appropriate types before use in application logic.

## Important Notes or Caveats

- Ensure that default values conform to the expected data type as defined in `parameter_type` to avoid type mismatches.
- It is critical to handle exceptions gracefully, especially when parsing dates, datetimes, and JSON data where the input format might not always be guaranteed.

This documentation should provide a clear understanding of how to work with the `PromptEngine::Parameter` model, facilitating its integration and use in various application scenarios.
