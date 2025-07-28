---
title: "Test Case"
layout: "docs"
parent: "api/models"
nav_order: "testcase"
---

# PromptEngine::TestCase Model Documentation

The `PromptEngine::TestCase` class represents individual test cases within a system designed to evaluate and validate a set of input variables against expected outcomes. Each test case is part of an evaluation set and contains multiple evaluation results that determine whether the test cases pass or fail based on predefined criteria.

## Attributes

| Attribute         | Type          | Description                                   |
|-------------------|---------------|-----------------------------------------------|
| `description`     | `string`      | A textual description of the test case.       |
| `input_variables` | `text`        | Serialized data storing variables for testing.|
| `expected_output` | `text`        | Serialized data representing expected result. |

## Associations

- **eval_set:** Each `TestCase` belongs to an `EvalSet`. This association links the test case to a broader evaluation context or a set, which may contain multiple related test cases.
- **eval_results:** A `TestCase` has many `EvalResults`. This represents the outcomes of executing the test case under various conditions or environments. The `dependent: :destroy` option ensures that all associated evaluation results are deleted when the test case itself is deleted.

## Validations

- **input_variables:** Presence validation ensures that each test case must include input variables. This is crucial as a test case without input data is invalid and cannot be executed.
- **expected_output:** Presence validation ensures that each test case must have expected output data defined. This is necessary to validate the test case against its execution results.

## Key Methods

- **display_name:** Returns a string that serves as a readable identifier for the test case. If the description is present, it returns the description; otherwise, it returns a string in the format "Test case #ID".
  ```ruby
  test_case.display_name
  ```

- **passed_count:** Returns the number of associated `EvalResults` where the test case passed.
  ```ruby
  test_case.passed_count
  ```

- **failed_count:** Returns the number of associated `EvalResults` where the test case failed.
  ```ruby
  test_case.failed_count
  ```

- **success_rate:** Calculates the percentage of passed results versus total results. Returns 0 if no results are present.
  ```ruby
  test_case.success_rate
  ```

## Common Usage Patterns

### Creating a New TestCase

```ruby
eval_set = PromptEngine::EvalSet.find(some_id)
test_case = eval_set.test_cases.create(
  description: "Check functionality X",
  input_variables: { key: 'value' }.to_json,
  expected_output: { result: 'expected_value' }.to_json
)
```

### Evaluating Test Case Success

```ruby
if test_case.success_rate > 90
  puts "Highly reliable test case."
else
  puts "Needs review."
end
```

## Important Notes or Caveats

- It is important to ensure that `input_variables` and `expected_output` are stored in a format that is consistent and parseable, as these are used directly in evaluations.
- Deleting a `TestCase` will also delete all associated `EvalResults` due to the `:destroy` dependency. This should be considered when planning data retention and archival strategies.
- The `success_rate` method includes rounding to one decimal place, which is sufficient for most use cases but might need adjustment for more precise needs.

This model is central to the evaluation framework within the `PromptEngine` module, providing foundational functionality for test management and execution assessment.
