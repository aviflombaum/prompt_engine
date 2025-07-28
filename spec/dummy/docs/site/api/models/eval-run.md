---
title: "Eval Run"
layout: "docs"
parent: "api/models"
nav_order: "evalrun"
---

# EvalRun Model Documentation

## Description
The `EvalRun` model within the `PromptEngine` module represents an evaluation run in a system designed to assess prompt versions against evaluation sets. This model is crucial for tracking the execution state and results of evaluations, managing their lifecycle from initiation to completion.

## Attributes

| Attribute      | Type     | Description                                                         |
|----------------|----------|---------------------------------------------------------------------|
| `status`       | Enum     | Represents the state of the evaluation run (pending, running, etc.) |
| `passed_count` | Integer  | The number of successful evaluations within this run.               |
| `total_count`  | Integer  | The total number of evaluations attempted in this run.              |
| `started_at`   | DateTime | Timestamp when the evaluation run was started.                      |
| `completed_at` | DateTime | Timestamp when the evaluation run was completed.                    |

## Associations

- **`belongs_to :eval_set`**: Connects each `EvalRun` to an `EvalSet`, indicating the set of evaluations that this run is assessing.
- **`belongs_to :prompt_version`**: Associates the `EvalRun` with a specific version of a prompt, indicating which version is being evaluated.
- **`has_many :eval_results, dependent: :destroy`**: Links multiple `EvalResults` to an `EvalRun`. All related `EvalResults` are destroyed if the `EvalRun` is deleted, ensuring data integrity.

## Validations
The `EvalRun` model does not currently have validations defined in the provided code snippet. Implementations should ensure that necessary validations, like presence and uniqueness, are considered during development.

## Key Methods

### `success_rate`
Calculates the rate of successful evaluations as a percentage of total evaluations.
```ruby
def success_rate
  return 0 if total_count.zero?
  (passed_count.to_f / total_count * 100).round(1)
end
```
**Usage Example:**
```ruby
eval_run = EvalRun.find(1)
puts eval_run.success_rate  # Outputs the success rate of the eval run.
```

### `duration`
Calculates the total duration of the evaluation run in seconds, if applicable.
```ruby
def duration
  return nil unless started_at && completed_at
  completed_at - started_at
end
```
**Usage Example:**
```ruby
eval_run = EvalRun.find(1)
puts eval_run.duration  # Outputs the duration of the eval run in seconds.
```

### `duration_in_words`
Provides a human-readable format of the evaluation run's duration.
```ruby
def duration_in_words
  return "Not started" unless started_at
  return "Running" if running?
  return "Failed" if failed? && !completed_at

  seconds = duration
  return nil unless seconds

  if seconds < 60
    "#{seconds.round} seconds"
  elsif seconds < 3600
    "#{(seconds / 60).round} minutes"
  else
    "#{(seconds / 3600).round(1)} hours"
  end
end
```
**Usage Example:**
```ruby
eval_run = EvalRun.find(1)
puts eval_run.duration_in_words  # Outputs the duration of the eval run in words.
```

## Common Usage Patterns
The `EvalRun` model is typically used to:
1. Initiate new evaluation runs.
2. Track the progress and status of ongoing evaluations.
3. Calculate statistics such as success rates upon completion.
4. Clean up related data once an evaluation run is no longer needed.

## Important Notes
- The `status` attribute uses an enumerated type for better clarity and constraints on possible values.
- Care should be taken when deleting `EvalRun` instances since it will also remove associated `EvalResults` due to the `:dependent => :destroy` option.
- The model assumes `started_at` and `completed_at` will be properly managed and updated during the lifecycle of an evaluation run.

This documentation should serve as a guide to understanding and utilizing the `EvalRun` model effectively within the development context.
