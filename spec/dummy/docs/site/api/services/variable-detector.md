---
title: "Variable Detector"
layout: "docs"
parent: "api/services"
nav_order: "variabledetector"
---

# Documentation for `VariableDetector` Class

## Purpose and Responsibility

The `VariableDetector` class within the `PromptEngine` module is designed to handle the detection, extraction, and manipulation of templated variables embedded within strings. It primarily supports the processing of variables formatted as `{{variable_name}}`, facilitating tasks such as variable extraction, replacement, and validation. This class is useful in scenarios where dynamic content needs to be generated based on variable data, such as in templating engines, configuration management systems, or any application that requires runtime text manipulation.

## Usage Examples

### Initialization

```ruby
detector = PromptEngine::VariableDetector.new("Hello, {{user_name}}! Your balance is {{balance}}.")
```

### Extracting Variables

```ruby
variables = detector.extract_variables
puts variables
# Output might include details about 'user_name' and 'balance' variables such as their positions, inferred types, and placeholders
```

### Checking for Variable Presence

```ruby
has_vars = detector.has_variables?
puts has_vars  # true if variables are present, false otherwise
```

### Rendering Text with Variable Values

```ruby
rendered_text = detector.render({'user_name' => 'Alice', 'balance' => '100'})
puts rendered_text  # "Hello, Alice! Your balance is 100."
```

### Validating Provided Variables

```ruby
validation_result = detector.validate_variables({'user_name' => 'Alice'})
puts validation_result
# Output will show valid status and any missing variables if not all required are provided
```

## Method Documentation

- **initialize(content)**:
  Initializes a new instance with the given content. `content` should be a string that potentially contains templated variables.

- **extract_variables**:
  Returns an array of hashes representing each unique variable found in the content. Each hash includes the variable's name, placeholder, position, inferred type, and a required flag.

- **variable_names**:
  Returns an array of the names of all unique variables extracted from the content.

- **has_variables?**:
  Returns a boolean indicating whether the content includes any templated variables.

- **variable_count**:
  Returns the count of unique variables found in the content.

- **render(variables = {})**:
  Replaces the templated variables in the content with the corresponding values provided in the `variables` hash. Supports both string and symbol keys.

- **validate_variables(provided_variables = {})**:
  Validates whether all required variables are included in `provided_variables`. Returns a hash with a `valid` key (boolean) and a `missing_variables` key (array).

## Error Scenarios

- Providing non-string content to `initialize` will not cause an error directly, as the content is converted to a string, but might lead to unexpected behavior or output.
- Passing non-hash types to `render` or `validate_variables` will result in errors since the method expects a hash.
- Omitting required variables in `render` will not throw an error but will result in the placeholders not being replaced in the output string.

## Best Practices

- Always ensure that the content passed to the `VariableDetector` is well-formed and properly represents the intended template structure.
- Before rendering, validate the provided variables to ensure completeness and correctness of the data, especially in critical applications.
- Use the `validate_variables` method to check for missing data before attempting to render, which helps in avoiding runtime errors or logic issues in the resulting output.
- Consider extending the `infer_type` method or modifying it to better suit specific application needs, as type inference can greatly affect data handling downstream.
