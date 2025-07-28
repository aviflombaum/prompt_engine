---
title: "Eval Set"
layout: "docs"
parent: "api/models"
nav_order: "evalset"
---

# `EvalSet` Model Documentation

## Description

The `EvalSet` model within the `PromptEngine` module is designed to represent a set of evaluation criteria and configurations associated with a specific prompt. This model is crucial for managing different methods of grading or evaluating responses based on predefined test cases and grading configurations. `EvalSet` manages test cases, evaluation runs, and grading schemes such as exact matches, regular expressions, or JSON schema validations.

## Attributes

| Attribute      | Type          | Description                                               |
|----------------|---------------|-----------------------------------------------------------|
| `name`         | String        | The name of the evaluation set; must be unique per prompt.|
| `grader_type`  | String        | The type of grader used for evaluation.                   |
| `grader_config`| JSON / Hash   | Configuration details specific to the chosen `grader_type`.|

## Associations

- **`belongs_to :prompt`**: Each `EvalSet` is associated with exactly one `Prompt`. This association signifies which prompt the evaluation set is intended to assess.
  
- **`has_many :test_cases, dependent: :destroy`**: An `EvalSet` can have multiple `TestCase` objects. If an `EvalSet` is deleted, all associated `TestCase` instances are also removed.

- **`has_many :eval_runs, dependent: :destroy`**: An `EvalSet` can have multiple evaluation runs (`EvalRun` objects). Deleting an `EvalSet` will also delete all its associated evaluation runs.

## Validations

- **Presence and Uniqueness of Name**: Each `EvalSet` must have a `name`, and it must be unique within the scope of its associated `prompt`.

- **Presence and Inclusion of Grader Type**: The `grader_type` must be present and must be one of the predefined keys in `GRADER_TYPES` (i.e., `exact_match`, `regex`, `contains`, `json_schema`).

- **Grader Configuration Validation**: Custom validation ensures that the `grader_config` is appropriate and valid based on the specified `grader_type`.

## Key Methods

### `latest_run`
Returns the most recent `EvalRun` associated with the `EvalSet`.
```ruby
eval_set.latest_run
```

### `average_success_rate`
Calculates the average success rate of all completed evaluation runs as a percentage.
```ruby
eval_set.average_success_rate
```

### `ready_to_run?`
Checks if there are any test cases associated with the `EvalSet` to determine if it is ready to run an evaluation.
```ruby
eval_set.ready_to_run?
```

### `grader_type_display`
Provides a human-readable string for the current `grader_type`.
```ruby
eval_set.grader_type_display
```

### `requires_grader_config?`
Determines whether the current `grader_type` requires additional configuration details.
```ruby
eval_set.requires_grader_config?
```

## Common Usage Patterns

The `EvalSet` is typically used in scenarios where automated grading or evaluation of responses is required. After defining test cases and setting up the evaluation configuration, you can perform evaluations, track the success rates, and adjust configurations as needed.

## Important Notes or Caveats

- **Grader Configuration**: Proper configuration of `grader_config` is crucial for the correct functioning of evaluations, especially for complex graders like `regex` or `json_schema`. The model includes methods to validate these configurations, but it is important to ensure that these configurations are set correctly from the outset to avoid runtime errors or incorrect evaluations.

- **Validation of JSON and Regex Patterns**: Errors in regex patterns or JSON schema can cause exceptions. These are caught and reported as validation errors. Ensure that regex and JSON schemas are tested separately before applying them to ensure they are valid.

This documentation provides an overview and technical details necessary for developers to effectively utilize and extend the `EvalSet` model within their applications.
