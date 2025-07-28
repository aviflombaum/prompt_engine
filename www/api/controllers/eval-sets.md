---
title: "EvalSets API"
layout: "docs"
parent: "api/controllers"
nav_order: "evalsets"
---

# PromptEngine::EvalSetsController API Documentation

The `EvalSetsController` within the `PromptEngine` module manages the lifecycle of evaluation sets associated with a specific prompt in a Rails application. Evaluation sets are used to organize and run sets of test cases against various versions of prompts, to assess and compare their performance.

## Actions

### Index
- **HTTP Method and Path:** `GET /prompts/:prompt_id/eval_sets`
- **Description:** Retrieves a list of all evaluation sets associated with a specific prompt.
- **Parameters:**
  - `prompt_id` (required): The ID of the prompt.
- **Response Format:** HTML
- **Status Codes:**
  - `200 OK` - Successfully retrieved list.
- **Example Request:**
  ```bash
  curl -X GET http://example.com/prompts/1/eval_sets
  ```

### Show
- **HTTP Method and Path:** `GET /prompts/:prompt_id/eval_sets/:id`
- **Description:** Displays detailed information about a specific evaluation set, including associated test cases and recent evaluation runs.
- **Parameters:**
  - `prompt_id` (required): The ID of the prompt.
  - `id` (required): The ID of the evaluation set.
- **Response Format:** HTML
- **Status Codes:**
  - `200 OK` - Successfully retrieved the evaluation set details.
- **Example Request:**
  ```bash
  curl -X GET http://example.com/prompts/1/eval_sets/2
  ```

### New
- **HTTP Method and Path:** `GET /prompts/:prompt_id/eval_sets/new`
- **Description:** Returns an HTML form for creating a new evaluation set.
- **Parameters:**
  - `prompt_id` (required): The ID of the prompt.
- **Response Format:** HTML
- **Status Codes:**
  - `200 OK` - Successfully returned the form.
- **Example Request:**
  ```bash
  curl -X GET http://example.com/prompts/1/eval_sets/new
  ```

### Create
- **HTTP Method and Path:** `POST /prompts/:prompt_id/eval_sets`
- **Description:** Creates a new evaluation set for the specified prompt.
- **Parameters:**
  - `prompt_id` (required): The ID of the prompt.
  - `eval_set` (required): A hash containing the attributes for the new evaluation set (`name`, `description`, `grader_type`, `grader_config`).
- **Response Format:** HTML (redirects to the show page on success or renders 'new' template on failure)
- **Status Codes:**
  - `302 Found` - Successfully created the evaluation set (redirect).
  - `422 Unprocessable Entity` - Validation failed; unable to create evaluation set.
- **Example Request:**
  ```bash
  curl -X POST -d "eval_set[name]=Example Set&eval_set[description]=An example&eval_set[grader_type]=Type1" http://example.com/prompts/1/eval_sets
  ```

### Edit
- **HTTP Method and Path:** `GET /prompts/:prompt_id/eval_sets/:id/edit`
- **Description:** Returns an HTML form for editing an existing evaluation set.
- **Parameters:**
  - `prompt_id` (required): The ID of the prompt.
  - `id` (required): The ID of the evaluation set.
- **Response Format:** HTML
- **Status Codes:**
  - `200 OK` - Successfully returned the edit form.
- **Example Request:**
  ```bash
  curl -X GET http://example.com/prompts/1/eval_sets/2/edit
  ```

### Update
- **HTTP Method and Path:** `PATCH /prompts/:prompt_id/eval_sets/:id`
- **Description:** Updates the specified evaluation set.
- **Parameters:**
  - `prompt_id` (required): The ID of the prompt.
  - `id` (required): The ID of the evaluation set.
  - `eval_set` (required): A hash containing the attributes for the evaluation set (`name`, `description`, `grader_type`, `grader_config`).
- **Response Format:** HTML (redirects to the show page on success or renders 'edit' template on failure)
- **Status Codes:**
  - `302 Found` - Successfully updated the evaluation set (redirect).
  - `422 Unprocessable Entity` - Validation failed; unable to update.
- **Example Request:**
  ```bash
  curl -X PATCH -d "eval_set[name]=Updated Example Set&eval_set[description]=Updated example" http://example.com/prompts/1/eval_sets/2
  ```

### Destroy
- **HTTP Method and Path:** `DELETE /prompts/:prompt_id/eval_sets/:id`
- **Description:** Deletes a specific evaluation set.
- **Parameters:**
  - `prompt_id` (required): The ID of the prompt.
  - `id` (required): The ID of the evaluation set.
- **Response Format:** HTML (redirects to the index page on success)
- **Status Codes:**
  - `302 Found` - Successfully deleted the evaluation set (redirect).
- **Example Request:**
  ```bash
  curl -X DELETE http://example.com/prompts/1/eval_sets/2
  ```

### Run
- **HTTP Method and Path:** `POST /prompts/:prompt_id/eval_sets/:id/run`
- **Description:** Initiates an evaluation run for the given evaluation set.
- **Parameters:**
  - `prompt_id` (required): The ID of the prompt.
  - `id` (required): The ID of the evaluation set.
- **Response Format:** HTML (redirects to the run page on success or evaluation set page on failure)
- **Status Codes:**
  - `302 Found` - Successfully started an evaluation run (redirect).
  - `403 Forbidden` - OpenAI API key not configured.
  - `429 Too Many Requests` - Rate limit exceeded.
  - `500 Internal Server Error` - API error or other server-side issue.
- **Example Request:**
  ```bash
  curl -X POST http://example.com/prompts/1/eval_sets/2/run
  ```

### Compare
- **HTTP Method and Path:** `GET /prompts/:prompt_id/eval_sets/:id/compare`
- **Description:** Compares two specific runs within an evaluation set, calculating metrics like success rates.
- **Parameters:**
  - `prompt_id` (required): The ID of the prompt.
  - `id` (required): The ID of the evaluation set.
  - `run_ids` (required): An array of two run IDs to compare.
- **Response Format:** HTML
- **Status Codes:**
  - `200 OK` - Successfully calculated comparison metrics.
  - `400 Bad Request` - Incorrect number of run IDs provided.
  - `404 Not Found` - One or both runs could not be found.
- **Example Request:**
  ```bash
  curl -X GET http://example.com/prompts/1/eval_sets/2/compare?run_ids[]=10&run_ids[]=11
  ```

### Metrics
- **HTTP Method and Path:** `GET /prompts/:prompt_id/eval_sets/:id/metrics`
- **Description:** Retrieves various performance metrics for all completed runs of an evaluation set.
- **Parameters:**
  - `prompt_id` (required): The ID of the prompt.
  - `id` (required): The ID of the evaluation set.
- **Response Format:** HTML
- **Status Codes:**
  - `200 OK` - Successfully retrieved metrics.
- **Example Request:**
  ```bash
  curl -X GET http://example.com/prompts/1/eval_sets/2/metrics
  ```

## Authentication Requirements
- All actions require the user to be authenticated. Ensure users are logged in and authorized to access the specified resources.

## Error Handling
- Errors are communicated through standard HTTP status codes along with error messages in the response body or through HTML page alerts, guiding the user to take appropriate actions (e.g., configuration changes, validation errors).
