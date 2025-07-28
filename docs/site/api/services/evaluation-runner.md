---
title: "Evaluation Runner"
layout: "docs"
parent: "api/services"
nav_order: "evaluationrunner"
---

# EvaluationRunner Class Documentation

## Purpose and Responsibility

The `EvaluationRunner` class within the `PromptEngine` module is responsible for orchestrating the end-to-end process of executing evaluations using OpenAI's API. It manages the creation of evaluation configurations, uploading test data, initiating evaluation runs, and polling for results. This class acts as a bridge between a local testing framework and OpenAI's remote evaluation services, handling data formatting, API interactions, and status updates.

## Usage Examples

### Instantiating and Running an Evaluation

```ruby
# Assume eval_run is an instance of an EvaluationRun model
runner = PromptEngine::EvaluationRunner.new(eval_run)

# Execute the evaluation
runner.execute
```

This example shows how to create an instance of `EvaluationRunner` and run an evaluation. This process includes updating the evaluation run status, handling file uploads, and polling for results.

## Method Documentation

### `initialize(eval_run)`
- **Parameters**: `eval_run` - An instance of EvaluationRun containing information about the evaluation set and prompt version.
- **Visibility**: Public
- **Purpose**: Sets up the runner with necessary instances and configurations for execution.

### `execute`
- **Parameters**: None
- **Visibility**: Public
- **Purpose**: Orchestrates the full lifecycle of an evaluation run, including setting up OpenAI eval configurations, uploading test data, creating an eval run on OpenAI, and polling for results.

### `ensure_openai_eval_exists`
- **Visibility**: Private
- **Purpose**: Ensures that an OpenAI evaluation configuration exists for the given eval set. If not, it creates one using dynamic schema properties based on the prompt parameters.

### `upload_test_data`
- **Visibility**: Private
- **Purpose**: Handles the creation and upload of a JSONL file containing the test cases to OpenAI.

### `create_openai_run(file_id)`
- **Parameters**: `file_id` - The ID of the uploaded file containing test data.
- **Visibility**: Private
- **Purpose**: Initiates an evaluation run on OpenAI using the uploaded test data and the evaluation configuration.

### `build_templated_content`
- **Visibility**: Private
- **Purpose**: Transforms template variables in the prompt content to the format expected by OpenAI.

### `poll_for_results`
- **Visibility**: Private
- **Purpose**: Periodically checks the status of the evaluation run on OpenAI and processes the results once completed.

### `process_results(run_status)`
- **Parameters**: `run_status` - Status object obtained from OpenAI after an evaluation run.
- **Visibility**: Private
- **Purpose**: Updates the evaluation run with results including total, passed, and failed test counts.

### `build_testing_criteria`
- **Visibility**: Private
- **Purpose**: Constructs the criteria for testing outputs based on the configuration of the eval set.

### `parameter_type_to_json_schema(type)`
- **Parameters**: `type` - A string representing the parameter type.
- **Visibility**: Private
- **Purpose**: Maps a parameter type to its corresponding JSON schema type.

## Error Scenarios

- **API Failures**: Handles any exceptions from API calls by updating the eval run status to `failed` and re-raising the exception.
- **File Handling Issues**: Ensures cleanup of temporary files even if file upload or other operations fail.
- **Timeouts**: Implements a timeout mechanism during result polling to prevent indefinite waiting periods.

## Best Practices

1. **Error Handling**: Ensure robust error handling around API interactions to manage partial failures gracefully.
2. **Resource Management**: Implement proper file management to avoid clutter or leaks in file handling.
3. **Test Coverage**: Extensively test the interaction with external APIs to handle various response scenarios effectively.
