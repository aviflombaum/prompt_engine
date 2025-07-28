---
title: "Eval Result"
layout: "docs"
parent: "api/models"
nav_order: "evalresult"
---

# Documentation for `PromptEngine::EvalResult` Model

## 1. Model Overview
The `EvalResult` model represents the result of an evaluation process within the `PromptEngine` module. It is primarily used to store the outcomes of specific test cases executed during an evaluation run. Each instance of `EvalResult` records whether a test passed or failed and the execution time in milliseconds.

## 2. Attributes

| Attribute          | Type    | Description                                               |
|--------------------|---------|-----------------------------------------------------------|
| `passed`           | Boolean | Indicates whether the test case passed (true) or failed (false). |
| `execution_time_ms`| Integer | The time taken to execute the test case, measured in milliseconds. |

## 3. Associations

- **`belongs_to :eval_run`**: This association links each `EvalResult` to an `EvalRun`, indicating that each result is part of an evaluation run. An `EvalRun` could have multiple `EvalResults`.

- **`belongs_to :test_case`**: This association connects each `EvalResult` to a `TestCase`, specifying the particular test case that was evaluated to produce this result.

## 4. Validations
There are no validations specified in the model, implying that the integrity and requirements of the data should be managed externally or are assumed to be validated elsewhere.

## 5. Key Methods

### `execution_time_seconds`
Converts the execution time from milliseconds to seconds.
```ruby
def execution_time_seconds
  return nil unless execution_time_ms
  execution_time_ms / 1000.0
end
```
**Usage Example:**
```ruby
result = PromptEngine::EvalResult.find(1)
puts result.execution_time_seconds # Outputs the execution time in seconds
```

### `status`
Returns a string indicating whether the test passed or failed.
```ruby
def status
  passed? ? "passed" : "failed"
end
```
**Usage Example:**
```ruby
result = PromptEngine::EvalResult.find(1)
puts result.status # Outputs "passed" or "failed"
```

## 6. Common Usage Patterns

### Finding all passed results
```ruby
passed_results = PromptEngine::EvalResult.passed
```

### Finding all failed results
```ruby
failed_results = PromptEngine::EvalResult.failed
```

### Ordering results by execution time
```ruby
sorted_results = PromptEngine::EvalResult.by_execution_time
```

## 7. Important Notes or Caveats

- **Precision of Execution Time**: The `execution_time_ms` attribute stores time in milliseconds. When converted to seconds using the `execution_time_seconds` method, there might be floating-point arithmetic considerations.

- **Dependence on Associations**: Both `eval_run` and `test_case` must be present for `EvalResult` records to be fully meaningful and operational within the system.

- **Scope Functionality**: The `passed` and `failed` scopes are convenient for filtering results, but they rely entirely on the `passed` boolean attribute. Ensure this attribute is correctly set during the creation or update of each `EvalResult`.

This documentation aims to provide a clear understanding of the `EvalResult` model within the `PromptEngine` context, ensuring effective usage and integration in related Rails applications.
